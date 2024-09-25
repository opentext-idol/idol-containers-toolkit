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
        objs = self.render_chart({'name':'testnifi', 'nifiClusters':[{'clusterId': 'nf1'},
                                           {'clusterId':'nf2'},
                                           {'clusterId': 'nf3',
                                            'flowfile':'flow3.json',
                                            'ingress':{
                                               'enabled':True,'proxyPath':'/','tls':{'secretName':''},'aciTLS':{'secretName':''},'metricsTLS':{'secretName':''}}},
                                           {}]})
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

if __name__ == '__main__':
    unittest.main()