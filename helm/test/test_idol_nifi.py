import os
import unittest

from itertools import chain
from utils.testbase import HelmChartTestBase

# Testing options
HelmChartTestBase.validation_namespace = ''
HelmChartTestBase.debug = False

class TestIdolNifi(unittest.TestCase, HelmChartTestBase):
    chartpath = os.path.join('..','idol-nifi')
    
    def setUp(self):
        self._kinds = ['StatefulSet','Ingress','ConfigMap','Service']

    def _multiple_nifi_values(self, nifiClusters):
        return {
                'name':'testnifi',
                'nifiClusters': nifiClusters,
                "nifi":{
                    "replicas": 2,
                    "service": {
                        "additionalPorts":{
                            "commonPort":{
                                "port": 2222
                            }
                        }
                    }
                }
            }

    def _multiple_nifi_clusters(self):
        return {
            'nf1': { 'clusterId':'nf1',
                      'replicas': 1 },
            'nf2': {
                'clusterId':'nf2',
                'flows':{
                    'f1':{
                        'file':'/scripts/flow1.json',
                        'bucket': 'default-bucket',
                        'import':True
                    },
                    'f2':{
                        'file':'/scripts/flow2.json',
                        'bucket': 'other-bucket',
                        'import':False
                    },
                    'f3':{
                        'name':'Existing Flow',
                        'bucket':'existing-bucket',
                        'version':"123"
                    },
                    'f4':{
                        'name':'Existing Flow2',
                        'bucket':'existing-bucket'
                    },
                    'basic-idol':{
                        'DELETE':True
                    }
                },
                'service':{
                    'additionalPorts':{
                        'commonPort': {
                            'port': -1
                        }
                    }
                }
            },
            'nf3': {
                'clusterId':'nf3',
                'flowfile':'flow3.json',
                'replicas': 0,
                'ingress':{
                    'enabled':True,
                    'proxyPath':'/',
                    'tls':{ 'secretName':'' },
                    'aciTLS':{ 'secretName':'' },
                    'metricsTLS':{
                        'secretName':''
                    }
                },
                    'service':{
                    'additionalPorts':{
                        'commonPort': {
                            'protocol': 'UDP'
                        },
                        'extra-port': {
                            'name': 'extra',
                            'protocol': 'UDP',
                            'port': 2223,
                            'targetPort': 2224
                        }
                    }
                }
            },
            '_unnamed_': {}
           }

    def _check_multiple_nifi(self, objs):
        clusterids = ['nf1','nf2','nf3','testnifi']
        
        # expected manifests with multiple clusters
        self.assertGreaterEqual(set(objs['StatefulSet'].keys()),
                                set(['testnifi-reg']+list(chain.from_iterable([[id,f'{id}-zk'] for id in clusterids]))))
        self.assertGreaterEqual(set(objs['ConfigMap'].keys()),
                                set(['testnifi-scripts']+list(chain.from_iterable([[f'{id}-env',f'{id}-keys-env'] for id in clusterids]))))
        # Ingress checks
        for id in ['nf1','nf2','testnifi']:
            self.assertEqual(objs['Ingress'][id]['spec']['rules'][0]['http']['paths'][0]['path'], f'/{id}/(.*)')
            self.assertIn(f'proxy_set_header X-ProxyContextPath "/{id}";',
                           objs['Ingress'][id]['metadata']['annotations']['nginx.ingress.kubernetes.io/configuration-snippet'])
            self.assertEqual(objs['Ingress'][f'{id}-aci']['spec']['rules'][0]['http']['paths'][0]['path'], f'/{id}/connector-aci/(.*)')
            self.assertEqual(objs['Ingress'][f'{id}-metrics']['spec']['rules'][0]['http']['paths'][0]['path'], f'/{id}/metrics/(.*)')
        self.assertEqual(objs['Ingress']['nf3']['spec']['rules'][0]['http']['paths'][0]['path'], f'/(.*)')
        self.assertEqual(objs['Ingress'][f'nf3-aci']['spec']['rules'][0]['http']['paths'][0]['path'], '/nf3/connector-aci/(.*)')
        self.assertEqual(objs['Ingress'][f'nf3-metrics']['spec']['rules'][0]['http']['paths'][0]['path'], '/nf3/metrics/(.*)')
        self.assertNotIn('proxy_set_header X-ProxyContextPath',
                        objs['Ingress']['nf3']['metadata']['annotations']['nginx.ingress.kubernetes.io/configuration-snippet'])

        # Flow env checks
        for id in ['nf1','testnifi']:
            self.assertEqual(objs['ConfigMap'][f'{id}-env']['data']['IDOL_NIFI_FLOW_COUNT'], '1')
            self.assertEqual(objs['ConfigMap'][f'{id}-env']['data']['IDOL_NIFI_FLOW_FILE_0'], '')
            self.assertEqual(objs['ConfigMap'][f'{id}-env']['data']['IDOL_NIFI_FLOW_NAME_0'], 'Basic IDOL')
            self.assertEqual(objs['ConfigMap'][f'{id}-env']['data']['IDOL_NIFI_FLOW_BUCKET_0'], 'default-bucket')
            self.assertEqual(objs['ConfigMap'][f'{id}-env']['data']['IDOL_NIFI_FLOW_VERSION_0'], '')
            self.assertEqual(objs['ConfigMap'][f'{id}-env']['data']['IDOL_NIFI_FLOW_IMPORT_0'], 'true')

        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_COUNT'], '4')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_FILE_0'], '/scripts/flow1.json')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_NAME_0'], '')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_BUCKET_0'], 'default-bucket')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_VERSION_0'], '')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_IMPORT_0'], 'true')
        
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_FILE_1'], '/scripts/flow2.json')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_NAME_1'], '')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_BUCKET_1'], 'other-bucket')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_VERSION_1'], '')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_IMPORT_1'], 'false')
        
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_FILE_2'], '')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_NAME_2'], 'Existing Flow')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_BUCKET_2'], 'existing-bucket')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_VERSION_2'], '123')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_IMPORT_2'], 'true')
        
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_FILE_3'], '')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_NAME_3'], 'Existing Flow2')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_BUCKET_3'], 'existing-bucket')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_VERSION_3'], '')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_IMPORT_3'], 'true')

        self.assertEqual(objs['ConfigMap']['nf3-env']['data']['IDOL_NIFI_FLOW_COUNT'], '1')
        self.assertEqual(objs['ConfigMap']['nf3-env']['data']['IDOL_NIFI_FLOW_FILE_0'], 'flow3.json')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_NAME_0'], '')
        self.assertEqual(objs['ConfigMap']['nf3-env']['data']['IDOL_NIFI_FLOW_BUCKET_0'], 'default-bucket')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_VERSION_0'], '')
        self.assertEqual(objs['ConfigMap']['nf3-env']['data']['IDOL_NIFI_FLOW_IMPORT_0'], 'true')

        # Services
        commonPortDef = {'name':'commonPort','port':2222}
        self.assertIn(commonPortDef, objs['Service']['nf1']['spec']['ports'])
        self.assertNotIn(commonPortDef, objs['Service']['nf2']['spec']['ports']) # -ve port number removes inherited def
        self.assertIn({'name':'commonPort','port':2222, 'protocol':'UDP'}, objs['Service']['nf3']['spec']['ports'])
        self.assertIn( {'name':'extra', 'protocol':'UDP', 'port':2223,'targetPort':2224,}, objs['Service']['nf3']['spec']['ports'])

        for k,v in {'nf1':1, 'nf2':2, 'nf3': 0 }.items():
            with self.subTest(f'{k} replicas'):
                self.assertEqual(objs['StatefulSet'][k]['spec']['replicas'], v)
    
    def test_multiple_nifi_array(self):
        self._check_multiple_nifi(self.render_chart(
            self._multiple_nifi_values(list(self._multiple_nifi_clusters().values()))))
        
    def test_multiple_nifi_map(self):
        self._check_multiple_nifi(self.render_chart(
            self._multiple_nifi_values(self._multiple_nifi_clusters())))

    def test_default_registry_buckets(self):
        objs = self.render_chart({})
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_COUNT'], '1')
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_NAME_0'], 'default-bucket')
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_FILES_0'], '/scripts/flow-basic-idol.json')
        self.assertEqual(objs['ConfigMap']['idol-nifi-env']['data']['NIFI_REGISTRY_HOSTS'], 'idol-nifi-reg')

    def test_registry_buckets(self):
        objs = self.render_chart(
            {
                'nifiRegistry':{
                    'buckets':{
                        'default-bucket': {'DELETE':True},
                        'b1':{ "name": "default-bucket" },
                        'b2':{ "name": "my-bucket" },
                        'b3':{
                            "name": "some-bucket",
                            "flowfiles": [ "/some/flow/file1.json", "/some/flow/file2.json" ]
                        }
                    }
                }
            })
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_COUNT'], '3')
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_NAME_0'], 'default-bucket')
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_FILES_0'], '')
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_NAME_1'], 'my-bucket')
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_FILES_1'], '')
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_NAME_2'], 'some-bucket')
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_FILES_2'], '/some/flow/file1.json,/some/flow/file2.json')

    def test_additional_volumes(self):
        objs = self.render_chart(
            {
                'additionalVolumeMounts': [
                    {"name": "test-nifi-files", "mountPath": "/some/mount/point"}
                ],
                'additionalVolumes': [
                    {"name": "test-nifi-files", "configMap": {"name": "test-nifi-cfg-map"}}
                ]
            })
        mounts = objs['StatefulSet']['idol-nifi-reg']['spec']['template']['spec']['containers'][0]['volumeMounts']
        self.assertTrue(any(mount["name"] == "test-nifi-files" and mount["mountPath"] == "/some/mount/point" for mount in mounts))

        volumes = objs['StatefulSet']['idol-nifi-reg']['spec']['template']['spec']['volumes']
        self.assertTrue(any(volume["name"] == "test-nifi-files" and volume.get("configMap", {}).get("name") == "test-nifi-cfg-map" for volume in volumes))

    def test_registry_name(self):
        objs = self.render_chart({'nifi':{
            'registryHost': 'nifi-registry'
        }})
        self.assertEqual(objs['ConfigMap']['idol-nifi-env']['data']['NIFI_REGISTRY_HOSTS'], 'nifi-registry')

    def test_default_ingress(self):
        objs = self.render_chart()
        self.assertEqual(objs['Ingress']['idol-nifi']['spec']['rules'][0]['http']['paths'][0]['path'], '/(.*)')
        self.assertEqual(objs['Ingress']['idol-nifi-aci']['spec']['rules'][0]['http']['paths'][0]['path'], '/connector-aci/(.*)')
        self.assertEqual(objs['Ingress']['idol-nifi-metrics']['spec']['rules'][0]['http']['paths'][0]['path'], '/metrics/(.*)')

    def test_security_context(self):
        return self.check_security_context(['idol-nifi','idol-nifi-reg','idol-nifi-zk'],{
            t: self.security_context_value() for t in ['podSecurityContext','containerSecurityContext']
        })
    
    def test_additionalVolumes_dict(self):
        return self.check_additionalVolumes_dict()

if __name__ == '__main__':
    unittest.main()