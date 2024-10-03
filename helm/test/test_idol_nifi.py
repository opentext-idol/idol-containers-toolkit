import os
import unittest

from itertools import chain
from utils.testbase import HelmChartTestBase

# Testing options
HelmChartTestBase.validation_namespace = ''
HelmChartTestBase.debug = False

class TestIdolNifi(unittest.TestCase, HelmChartTestBase):
    chartpath = os.path.join('..','idol-nifi')

    def test_multiple_nifi(self):
        clusterids = ['nf1','nf2','nf3','testnifi']
        objs = self.render_chart(
            {
                'name':'testnifi',
                'nifiClusters':[
                    { 'clusterId':'nf1' },
                    {
                        'clusterId':'nf2',
                        'flows':[
                            {
                                'file':'/scripts/flow1.json',
                                'bucket': 'default-bucket',
                                'import':True
                            },
                            {
                                'file':'/scripts/flow2.json',
                                'bucket': 'other-bucket',
                                'import':False
                            }
                        ]
                    },
                    {
                        'clusterId':'nf3',
                        'flowfile':'flow3.json',
                        'ingress':{
                           'enabled':True,
                           'proxyPath':'/',
                           'tls':{ 'secretName':'' },
                           'aciTLS':{ 'secretName':'' },
                           'metricsTLS':{
                             'secretName':''
                           }
                        }
                    },
                    {}
                ]
            })
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
        self.assertEqual(objs['Ingress']['nf3']['spec']['rules'][0]['http']['paths'][0]['path'], f'/(.*)')
        self.assertNotIn('proxy_set_header X-ProxyContextPath',
                        objs['Ingress']['nf3']['metadata']['annotations']['nginx.ingress.kubernetes.io/configuration-snippet'])

        # Flow env checks
        for id in ['nf1','testnifi']:
            self.assertEqual(objs['ConfigMap'][f'{id}-env']['data']['IDOL_NIFI_FLOW_COUNT'], '1')
            self.assertEqual(objs['ConfigMap'][f'{id}-env']['data']['IDOL_NIFI_FLOW_FILE_0'], '/scripts/flow-basic-idol.json')
            self.assertEqual(objs['ConfigMap'][f'{id}-env']['data']['IDOL_NIFI_FLOW_BUCKET_0'], 'default-bucket')
            self.assertEqual(objs['ConfigMap'][f'{id}-env']['data']['IDOL_NIFI_FLOW_IMPORT_0'], 'true')

        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_COUNT'], '2')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_FILE_0'], '/scripts/flow1.json')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_BUCKET_0'], 'default-bucket')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_IMPORT_0'], 'true')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_FILE_1'], '/scripts/flow2.json')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_BUCKET_1'], 'other-bucket')
        self.assertEqual(objs['ConfigMap']['nf2-env']['data']['IDOL_NIFI_FLOW_IMPORT_1'], 'false')
        
        self.assertEqual(objs['ConfigMap']['nf3-env']['data']['IDOL_NIFI_FLOW_COUNT'], '1')
        self.assertEqual(objs['ConfigMap']['nf3-env']['data']['IDOL_NIFI_FLOW_FILE_0'], 'flow3.json')
        self.assertEqual(objs['ConfigMap']['nf3-env']['data']['IDOL_NIFI_FLOW_BUCKET_0'], 'default-bucket')
        self.assertEqual(objs['ConfigMap']['nf3-env']['data']['IDOL_NIFI_FLOW_IMPORT_0'], 'true')

    def test_default_registry_buckets(self):
        objs = self.render_chart({})
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_COUNT'], '1')
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_NAME_0'], 'default-bucket')
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_FILES_0'], '/scripts/flow-basic-idol.json')

    def test_registry_buckets(self):
        objs = self.render_chart(
            {
                'nifiRegistry':{
                    'buckets':[
                        { "name": "default-bucket" },
                        { "name": "my-bucket" },
                        {
                            "name": "some-bucket",
                            "flowfiles": [ "/some/flow/file1.json", "/some/flow/file2.json" ]
                        }
                    ]
                }
            })
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_COUNT'], '3')
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_NAME_0'], 'default-bucket')
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_FILES_0'], '')
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_NAME_1'], 'my-bucket')
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_FILES_1'], '')
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_NAME_2'], 'some-bucket')
        self.assertEqual(objs['ConfigMap']['idol-nifi-reg-cm']['data']['NIFI_REGISTRY_BUCKET_FILES_2'], '/some/flow/file1.json,/some/flow/file2.json')

if __name__ == '__main__':
    unittest.main()