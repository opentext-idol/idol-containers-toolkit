import os
import pathlib
import subprocess
import yaml

from tempfile import TemporaryDirectory
from typing import Dict, Optional

class HelmChartTestBase():
    chartpath = 'dummy'         # path to chart
    update_dependency = False   # whether to run helm dependency update before running tests
    debug = False               # --debug
    # --validate requires a server connection and will clash with existing resources
    # so best to use an empty namespace to avoid
    validation_namespace = ''

    _kinds = None
    _gateway_data = None
    _gateway_bad_data = None

    @property
    def kinds(self):
        return self._kinds

    @classmethod
    def setUpClass(cls) -> None:
        if os.path.isdir(cls.chartpath) and cls.update_dependency:
            subprocess.check_output(['helm','dependency','update',cls.chartpath])
        return super().setUpClass()
    
    def name(self):
        return self.default_values()['name']

    def workloads(self, objs, names):
        found = {}
        for t in ['Deployment','StatefulSet']:
            if t not in self.kinds:
                continue
            for name, workload in objs[t].items():
                if name in names:
                    found[name] = True
                    yield t, workload
        self.assertEqual(set(found.keys()), set(names), f'Workloads missing from {names}')

    def check_tls(self, objs, names):
        '''
        Check that the IDOL_SSL environment variable is set to "1" in each workload's container spec.
        '''
        for kind,obj in self.workloads(objs, names):
            with self.subTest(kind):
                self.assertIn({'name':'IDOL_SSL','value':'1'},
                            obj['spec']['template']['spec']['containers'][0]['env'])

    @staticmethod
    def get_test_custom_data():
        labels = {'test-label':'test-label-value'}
        annotations = {'test-annotation':'test-annotation-value'}
        return {
                'labels': labels,
                'annotations': annotations,
                'serviceAccountName': 'test-svc'
               }

    def check_custom_data(self, objs, names):
        ''' annotations/labels etc. written to Deployments/StatefulSets '''
        expected_custom_data = self.get_test_custom_data()
        for kind,obj in self.workloads(objs, names):
            with self.subTest(kind):
                with self.subTest(f'{kind}-annotations'):
                    self.assertEqual(expected_custom_data['annotations'],
                                        obj['spec']['template']['metadata']['annotations'])

                with self.subTest(f'{kind}-labels'):
                    self.assertLessEqual(expected_custom_data['labels'].items(),
                                            obj['spec']['template']['metadata']['labels'].items())

                with self.subTest(f'{kind}-serviceAccountName'):
                    self.assertEqual(expected_custom_data['serviceAccountName'],
                                        obj['spec']['template']['spec']['serviceAccountName'])

    def default_values(self):
        values = subprocess.check_output(['helm','show','values',self.chartpath])
        return yaml.load(values, Loader=yaml.FullLoader)

    def render_chart(self, values: Optional[Dict] = None, name: str ='test', capture_output=False) -> Dict:
        with TemporaryDirectory() as tmp_dir:
            cmd = ['helm','template', name, self.chartpath ]
            if values:
                content = yaml.dump(values)
                values_file = os.path.join(tmp_dir,'testvalues.yaml')
                pathlib.Path(values_file).write_text(content, 'utf-8')
                cmd.extend(['--values', values_file])
            if HelmChartTestBase.validation_namespace:
                cmd.extend(['-n', HelmChartTestBase.validation_namespace, '--validate'])
            if HelmChartTestBase.debug:
                cmd.extend(['--debug'])
            templates = subprocess.check_output(cmd, stderr=subprocess.STDOUT if capture_output else None)
            ret = dict()
            for obj in yaml.load_all(templates, Loader=yaml.FullLoader):
                if not obj:
                    continue
                kind = obj['kind']
                name = obj['metadata']['name']
                self.assertIn('apiVersion', obj)
                if kind not in ret:
                    ret[kind] = dict()
                self.assertNotIn(name, ret[kind])
                ret[kind][name] = obj
            return ret
    
    def test_render_default(self):
        ''' Chart renders successfully with default values '''
        objs = self.render_chart()
        self.assertNotEqual(0, len(objs))

    def security_context_value(self):
        ''' A securityContext configuration  value to test with '''
        return { 'enabled': True, 'runAsGroup': 123}

    def check_security_context(self, names=['thing'], values=None):
        if values is None:
            values = {'podSecurityContext': self.security_context_value(),
                'containerSecurityContext': self.security_context_value(),
                'name':'thing'}
        objs = self.render_chart(values)
        for name in names:
            workloads = { k:o for k,o in self.workloads(objs, [name])}
            self.assertGreater(len(workloads), 0, f'no workloads found for {name}')
            for kind,obj in workloads.items():
                self.assertLessEqual({'runAsGroup':123}.items(), obj['spec']['template']['spec']['securityContext'].items())
                self.assertNotIn('enabled', obj['spec']['template']['spec']['securityContext'].keys())
                self.assertLessEqual({'runAsGroup':123}.items(), obj['spec']['template']['spec']['containers'][0]['securityContext'].items())
                self.assertNotIn('enabled', obj['spec']['template']['spec']['containers'][0]['securityContext'].keys())
    
    def test_security_context(self):
        ''' containerSecurityContext and podSecurityContext render correctly when used '''
        self.check_security_context()

    def check_additionalVolumes_array(self, names=None):
        if None==names:
            names = [self.name()]
        vols = [
            { 'name': 'extra', 'configMap': {'name': 'extra'} }
        ]
        mounts = [
            { 'name': 'extra', 'mountPath': 'extra' }
        ]
        objs = self.render_chart({'additionalVolumes': vols, 'additionalVolumeMounts': mounts })
        for k,obj in self.workloads(objs, names):
            volumeMounts = obj['spec']['template']['spec']['containers'][0]['volumeMounts']
            for mount in mounts:
                self.assertIn(mount, volumeMounts)
            volumes = obj['spec']['template']['spec']['volumes']
            for vol in vols:
                self.assertIn(vol, volumes)

    def check_additionalVolumes_dict(self, names=None):
        if None==names:
            names = [self.name()]
        vols = {
            'extra': { 'name': 'extra', 'configMap': {'name': 'extra'} },
            'extraNull': None, # null ignored
            'extraEmpty': {}, # empty dict should be ignored
            'extraDeleted': { 'DELETE': True, 'name': 'extra', 'configMap': {'name': 'extra'} },  # DELETE marks should be ignored
            
        }
        mounts = {
            'extra': { 'name': 'extra', 'mountPath': 'extra' },
            'extraNull': None, # null ignored
            'extraEmpty': {}, # empty dict should be ignored
            'extraDeleted': { 'name': 'extraDeleted', 'mountPath': 'extra', 'DELETE': True } # DELETE marks should be ignored
        }
        objs = self.render_chart({'additionalVolumes': vols, 'additionalVolumeMounts': mounts })
        for k,obj in self.workloads(objs, names):
            volumeMounts = obj['spec']['template']['spec']['containers'][0]['volumeMounts']
            self.assertIn(mounts['extra'], volumeMounts)
            for omit in ['extraNull','extraEmpty', 'extraDeleted']:
                self.assertNotIn(mounts[omit], volumeMounts)
            volumes = obj['spec']['template']['spec']['volumes']
            self.assertIn(vols['extra'], volumes)
            for omit in ['extraNull','extraEmpty', 'extraDeleted']:
                self.assertNotIn(vols[omit], volumes)

    def test_additionalVolumes_array(self):
        ''' Can specify additionalVolumes in array form (legacy) '''
        self.check_additionalVolumes_array()

    def test_gateway_ingress(self):
        ''' Gateway ingress configuration renders HTTPRoute correctly '''
        gateway_spec = self._gateway_data or {'ingress': {'host': 'component.example.12-34-56-78.nip.io', 'type': 'gateway', 'gatewayName': 'test-gateway'}}
        objs = self.render_chart(gateway_spec)
        http_route = objs.get('HTTPRoute')
        if not http_route:
            self.fail("No HTTPRoute found in rendered chart for gateway ingress type")
        route = next(iter(http_route.values()))
        route_spec = route["spec"]
        self.assertEqual(route_spec["parentRefs"][0]["name"], "test-gateway", msg="Incorrect gateway name in HTTPRoute parentRefs")
        self.assertEqual(route_spec["hostnames"][0], "component.example.12-34-56-78.nip.io", msg="Incorrect hostname in HTTPRoute spec")
        self.assertNotEqual(0, len(route_spec["rules"]), msg="No rules found in HTTPRoute spec")

    def test_gateway_ingress_invalid(self):
        ''' Invalid gateway ingress configuration raises error '''
        with self.assertRaises(subprocess.CalledProcessError) as raiser:
            gateway_bad_spec = self._gateway_bad_data or {'ingress': {'host': 'component.example.12-34-56-78.nip.io', 'type': 'gateway'}}
            self.render_chart(gateway_bad_spec, capture_output=True)
        self.assertIn('Must specify ingress.gatewayName', raiser.exception.output.decode('utf8'))
