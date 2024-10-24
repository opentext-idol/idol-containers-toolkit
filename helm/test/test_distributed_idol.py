import os
import unittest
from utils.testbase import HelmChartTestBase

# Testing options
HelmChartTestBase.validation_namespace = ''
HelmChartTestBase.debug = False

class TestDistributedIdol(unittest.TestCase, HelmChartTestBase):
    chartpath = os.path.join('..','distributed-idol')

    def setUp(self):
        self._name = 'distributed-idol-test'
        self._kinds = ['Deployment','StatefulSet','Ingress','ConfigMap','Service']
        self._aci_workloads = ['idol-content', 'idol-dah', 'idol-dih']
        self._components = {'content', 'dah', 'dih', 'prometheus'}

    def test_kinds(self):
        '''
        Check that the chart produces expected kinds/names
        '''
        objs = self.render_chart( {'name': self._name } )
        expected_kinds = {
            'Deployment': [
                           'custom-metrics-apiserver',
                           'idol-dah',
                           'prometheus',
                          ],
            'StatefulSet': [
                            'idol-content',
                            'idol-dih'
                           ],
            'Ingress': [
                        'idol-content',
                        'idol-dah',
                        'idol-dih',
                        'prometheus'
                       ],
            'ConfigMap': [
                          'adapter-config',
                          'dih-prometheus-exporter-python',
                          'idol-content-default-cfg',
                          'idol-dah-default-cfg',
                          'idol-dih-default-cfg',
                          'prometheus-config'
                         ],
            'Service': [
                        'custom-metrics-apiserver',
                        'idol-content',
                        'idol-dah',
                        'idol-dih',
                        'idol-index-service',
                        'idol-query-service',
                        'prometheus'
                       ]
        }
        for kind,names in expected_kinds.items():
            self.assertGreaterEqual(set(objs[kind].keys()), set(names))

    def test_multiple_content(self):
        '''
        Check that we can specify the initial number of engines for the content component, and get that many replicas of the idol-content StatefulSet.
        '''
        initial_engines = 3

        custom_values = {
            'name': self._name,
            'content': {
                'initialEngineCount': str(initial_engines)
            }
        }

        objs = self.render_chart(custom_values)
        self.assertEqual(objs['StatefulSet']['idol-content']['spec']['replicas'], initial_engines)

    def test_using_tls(self):
        '''
        Check that setting usingTLS sets IDOL_SSL environment variable
        '''
        custom_values = { 'name': self._name }
        for component in self._components:
            custom_values.update( {component: {'usingTLS': True}} )

        objs = self.render_chart(custom_values)
        self.check_tls(objs, self._aci_workloads)


    def test_custom_data(self):
        ''' annotations/labels etc. written to Deployments/StatefulSets '''
        test_custom_data = self.get_test_custom_data()

        custom_values = { 'name': self._name }
        for component in self._components:
            custom_values.update( {component: test_custom_data} )

        objs = self.render_chart(custom_values)
        self.check_custom_data(objs, self._aci_workloads)

if __name__ == '__main__':
    unittest.main()