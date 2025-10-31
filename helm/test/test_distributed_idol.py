import os
import unittest
from utils.testbase import HelmChartTestBase

# Testing options
HelmChartTestBase.validation_namespace = ''
HelmChartTestBase.debug = False

class TestDistributedIdol(unittest.TestCase, HelmChartTestBase):
    chartpath = os.path.join('..','distributed-idol')

    def setUp(self):
        self._kinds = ['Deployment','StatefulSet','Ingress','ConfigMap','Service']
        self._aci_workloads = ['idol-content', 'idol-dah', 'idol-dih']
        self._components = {'content', 'dah', 'dih', 'prometheus'}

    def test_kinds(self):
        '''
        Check that the chart produces expected kinds/names
        '''
        release = 'rel'
        objs = self.render_chart( {}, name=release )
        expected_kinds = {
            'Deployment': [
                           'idol-dah',
                           f'{release}-metrics-server',
                           f'{release}-prometheus-adapter',
                           f'{release}-prometheus-server'
                          ],
            'StatefulSet': [
                            'idol-content',
                            'idol-dih'
                           ],
            'Ingress': [
                        'idol-content',
                        'idol-dah',
                        'idol-dih',
                        f'{release}-prometheus-server'
                       ],
            'ConfigMap': [
                          'dih-prometheus-exporter-python',
                          'idol-content-default-cfg',
                          'idol-content-scripts',
                          'idol-dah-default-cfg',
                          'idol-dah-scripts',
                          'idol-dih-default-cfg',
                          'idol-dih-scripts',
                          f'{release}-prometheus-adapter',
                          f'{release}-prometheus-server'
                         ],
            'Service': [
                        'idol-content',
                        'idol-dah',
                        'idol-dih',
                        'idol-index-service',
                        'idol-query-service',
                        f'{release}-metrics-server',
                        f'{release}-prometheus-server'
                       ]
        }
        for kind,names in expected_kinds.items():
            with self.subTest(kind):
                self.assertGreaterEqual(set(objs[kind].keys()), set(names))

    def test_multiple_content(self):
        '''
        Check that we can specify the initial number of engines for the content component, and get that many replicas of the idol-content StatefulSet.
        '''
        initial_engines = 3

        custom_values = {
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
        custom_values = { }
        for component in self._components:
            custom_values.update( {component: {'usingTLS': True}} )

        objs = self.render_chart(custom_values)
        self.check_tls(objs, self._aci_workloads)


    def test_custom_data(self):
        ''' annotations/labels etc. written to Deployments/StatefulSets '''
        test_custom_data = self.get_test_custom_data()

        custom_values = { }
        for component in self._components:
            custom_values.update( {component: test_custom_data} )

        objs = self.render_chart(custom_values)
        self.check_custom_data(objs, self._aci_workloads)

    def test_security_context(self):
        return self.check_security_context(['idol-dih','idol-dah','idol-content'], {
            'dih':{t: self.security_context_value() for t in ['podSecurityContext','containerSecurityContext']},
            'dah':{t: self.security_context_value() for t in ['podSecurityContext','containerSecurityContext']},
            'content':{t: self.security_context_value() for t in ['podSecurityContext','containerSecurityContext']},
        })
    
    def check_additionalVolumes(self, use_dict):
        vols = [
            { 'name': 'extra', 'configMap': {'name': 'extra'} }
        ]
        mounts = [
            { 'name': 'extra', 'mountPath': 'extra' }
        ]
        if use_dict:
            objs = self.render_chart({x: {'additionalVolumes': {v['name']: v for v in vols}, 
                                        'additionalVolumeMounts': {m['name']: m for m in mounts}
                    } for x in ['dah','dih','content']})
        else:
            objs = self.render_chart({x: {'additionalVolumes': vols, 
                                        'additionalVolumeMounts': mounts,
                    } for x in ['dah','dih','content']})
        for k,obj in self.workloads(objs, ['idol-dah','idol-dih','idol-content']):
            volumeMounts = obj['spec']['template']['spec']['containers'][0]['volumeMounts']
            for mount in mounts:
                self.assertIn(mount, volumeMounts)
            volumes = obj['spec']['template']['spec']['volumes']
            for vol in vols:
                self.assertIn(vol, volumes)
            
    def test_additionalVolumes_array(self):
        self.check_additionalVolumes(False)

    def test_additionalVolumes_dict(self):
        self.check_additionalVolumes(True)

if __name__ == '__main__':
    unittest.main()