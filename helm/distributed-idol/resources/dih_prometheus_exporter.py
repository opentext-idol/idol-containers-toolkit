import collections
import json
import logging
import os
import re
import requests
import time

from prometheus_client import start_http_server
from prometheus_client.core import GaugeMetricFamily, REGISTRY

from threading import Lock, Thread
from typing import Tuple, Optional, Iterator

no_proxies = {'http': None, 'https': None }

DIHStatus = collections.namedtuple('DIHStatus', ['full_ratio', 'children'])
DIHChild = collections.namedtuple('DIHChild', ['group','host','port','status'])

TEMP_STATUS_CODES = set([-7,-12,-13,-16,-17,-25,-34,-35,-36,-38])
FINISHED_STATUS_CODES = set([x for x in filter(lambda y: y not in TEMP_STATUS_CODES, range(-1,-38,-1))])

logging.basicConfig(format='%(asctime)s [%(thread)d] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger('prometheus-exporter')
logger.setLevel(logging.DEBUG)
fh = logging.FileHandler('exporter.log')
fh.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s [%(thread)d] %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
fh.setFormatter(formatter)
logger.addHandler(fh)

def ensure_list(object: object):
    if object is None:
        return []
    elif isinstance(object, list):
        return object
    elif isinstance(object, collections.abc.Sequence) and not isinstance(object, str):
        return list(object)
    else:
        return [object]

def extract_index_id(responsetext: str) -> str:
    match = re.search('^INDEXID=(\d+)', responsetext)
    if not match:
        return None
    return match.group(1)

def log_and_raise(msg: str):
    logger.error(msg)
    raise Exception(msg)

def full_ratio_metric(value: Optional[float]) -> GaugeMetricFamily:
    m = GaugeMetricFamily(
        'dih_full_ratio',
        'Combined full-ratio of the child engines of the DIH',
        labels=["pod", "deployment"])
    if value is not None:
        m.add_metric([os.environ['HOSTNAME'], {{ .Values.dihDeployment | quote }}], value)
    return m

def latch_metric(value: Optional[float]) -> GaugeMetricFamily:
    m = GaugeMetricFamily(
        'full_ratio_latch',
        'Metric to control scale down (1.0 if OK, lower if scale down required)',
        labels=["pod", "deployment"])
    if value is not None:
        m.add_metric([os.environ['HOSTNAME'], {{ .Values.dihDeployment | quote }}], value)
    return m

class Worker(object):
    def __init__(self):
        self.host = '{{ .Values.dihName }}'
        self.aci_port = int(os.environ['IDOL_DIH_SERVICE_PORT_ACI_PORT'])
        self.index_port = self.aci_port + 1
        self.redist_count = 0 # counter for tracking DREREDISTRIBUTE commmands
        self.lock = Lock()  # protect shared access to metrics
        self.full_ratio_metric = full_ratio_metric(0.00)    # shared access
        self.latch_metric = latch_metric(1.00)              # shared access

    def get_status(self) -> DIHStatus:
        def sort_children(c: DIHChild):
            # host string is of form pod-name-{id}.domain.blah - sort by pod id
            return int(c.host.split('.', 1)[0].split('-')[-1])
        try:
            resp = requests.get('&'.join([f'http://{self.host}:{self.aci_port}/action=getstatus',
                'responseformat=json',
                'actionid=prometheus-exporter']), proxies=no_proxies)
            responsedata = resp.json()['autnresponse']['responsedata']
            full_ratio = float(responsedata['full_ratio']['$'])
            children = [ DIHChild(e['group']['$'], e['host']['$'], e['port']['$'], e['status']['$']) for e in ensure_list(responsedata['engines']['engine']) ]
            return DIHStatus(full_ratio=full_ratio, 
                children=sorted(children, key=sort_children))
        except Exception as e:
            if resp is not None:
                logger.error("{}: Got content '{}'".format(e.__str__(), resp.content))
            else:
                logger.error("{}: No content".format(e.__str__()))
            return None
    
    def get_index_job_status(self, id: str):
        resp = requests.get('&'.join([f'http://{self.host}:{self.aci_port}/action=indexerGetStatus',
            f'index={id}',
            'responseformat=simplejson',
            'actionid=prometheus-exporter']), proxies=no_proxies)
        jresp = resp.json()['autnresponse']['responsedata']
        if 'item' not in jresp:
            log_and_raise(f'Item with id {id} not found in index queue.')

        if len(jresp['item']) != 1:
            log_and_raise('Unexpected number of results. We were only expecting a single item.')

        item = jresp['item'][0]
        return item

    def trigger_redistribution(self, to_remove: set[DIHChild]) -> Tuple[str,str]:
        tracking_id = f'pe-{self.redist_count}-{int(time.time()):0x}'
        resp = requests.get('&'.join([f'http://{self.host}:{self.index_port}/DREREDISTRIBUTE?RemoveGroup={("+".join(to_remove))}',
            f'dahhost={os.environ["IDOL_DAH_SERVICE_HOST"]}',
            f'dahport={os.environ["IDOL_DAH_SERVICE_PORT"]}',
            f'indexuid={tracking_id}']), proxies=no_proxies)
        self.redist_count += 1
        id = extract_index_id(resp.text)
        resp = requests.get(f'http://{self.host}:{self.index_port}/DRESYNC?&indexuid={tracking_id}-sync', 
            proxies=no_proxies) 
        return id, tracking_id
    
    def is_empty_enough(self, status: DIHStatus) -> bool:
        #Return True if we have lots of spare capacity, False otherwise
        if status is None or \
           1>=len(status.children) or \
           (0.0 == status.full_ratio and any([ 'UP'!=c.status for c in status.children ])):
            # DIH may still be starting up and unable to contact engines for fullness
            return False
        return status.full_ratio <= 0.4

    def calculate_scaledown_num_engines(self, status: DIHStatus) -> int:
        #Try to work out the smallest number of engines possible that can handle the storage without triggering a scaleup
        #This function should only be used when triggering a scaledown
        storage_used = len(status.children) * status.full_ratio
        for n in range(1, len(status.children)):
            if (storage_used / float(n)) <= 1.0:
                return n
        return len(status.children) - 1

    def calculate_return_metric(self, status: DIHStatus, desired_engines: int) -> float:
        #This is a rearrangement of the equation that the HPA uses to calculate the number of replicas that should exist:
        #  desiredReplicas = ceil(currentReplicas * (currentMetric / desiredMetric))
        #This rearrangement assumes the desired metric value is 1.0
        return (float(desired_engines) / float(len(status.children))) - 0.01

    def is_engine_available(self, child: DIHChild) -> bool:
        try:
            r = requests.get('&'.join([f'http://{child.host}:{child.port}/action=getpid',
                    'actionid=prometheus-exporter']), 
                    proxies=no_proxies)
            return True
        except:
            return False

    def do_redistribute(self, remove_children: set[DIHChild]):
        id, tracking_id = self.trigger_redistribution([c.group for c in remove_children])
        logger.info(f'Awaiting completion of DREREDISTRIBUTE {id} {tracking_id}')
        index_status = 0
        while index_status not in FINISHED_STATUS_CODES:
            if index_status!=0:
                time.sleep(1)
            item = self.get_index_job_status(id)
            index_status = int(item['status'])
        if -1 != index_status:
            log_and_raise(f'Item with id {id} has permanant status {index_status}, wanted: -1, item: {item}')
        logger.info(f'DREREDISTRIBUTE {id} {tracking_id} finished.')

    def wait_for_engine_removal(self, remove_children: set[DIHChild]):
        def still_available(c: DIHChild):
            if not self.is_engine_available(c):
                logger.info(f'Child engine {c.group} {c.host}:{c.port} has been removed')
                # should we latch as soon as we see one child has been removed?
                return False
            return True
        while len(remove_children)>0:
            pending_removal = list(filter(still_available, remove_children))
            remove_children.clear()
            for p in pending_removal:
                remove_children.add(p)
            time.sleep(1)

    def do_scaledown(self, status: DIHStatus):
        desired_engines = self.calculate_scaledown_num_engines(status)
        remove_children = set(status.children[desired_engines:])
        logger.info(f'Scaledown starting: from {len(status.children)} to {desired_engines} engines')
        for c in status.children[:desired_engines]:
            logger.info(f'Child engine {c.group} {c.host}:{c.port}')
        for c in remove_children:
            logger.info(f'Child engine {c.group} {c.host}:{c.port} is pending removal')
        
        self.do_redistribute(remove_children)
        
        scaledown_report_metric = self.calculate_return_metric(status, desired_engines)
        logger.info(f'Reporting scaledown to HPA ({scaledown_report_metric})')
        with self.lock:
            self.full_ratio_metric = full_ratio_metric(scaledown_report_metric)
            self.latch_metric = latch_metric(scaledown_report_metric)
        
        self.wait_for_engine_removal(remove_children)
        logger.info(f'Scaledown completed')

    def collect(self) -> bool:
        status = self.get_status()

        if self.is_empty_enough(status):
            self.do_scaledown(status)
            return False # don't sleep - run next update cycle immediately
        
        metric = full_ratio_metric(status.full_ratio if status else None)
        latch = latch_metric(1.00)
        
        with self.lock:
            self.full_ratio_metric = metric
            self.latch_metric = latch
        return True # should sleep

class DIHCollector(object):
    def __init__(self):
        def worker_main(w):
            while True:
                if w.collect():
                    time.sleep(5)
        self.worker = Worker()
        self.thread = Thread(target=worker_main, args=[self.worker])
        self.thread.start()

    def describe(self) -> Iterator[GaugeMetricFamily]:
        yield full_ratio_metric(None)
        yield latch_metric(None)

    def collect(self) -> Iterator[GaugeMetricFamily]:
        with self.worker.lock:
            m1 = self.worker.full_ratio_metric
            m2 = self.worker.latch_metric
        yield m1
        yield m2

if __name__ == '__main__':
    logger.info('Starting DIH stats collection')
    d = DIHCollector()
    REGISTRY.register(d)
    start_http_server(int(os.environ['IDOL_DIH_SERVICE_PORT_METRICS_PORT']))
    while True: 
        time.sleep(1)