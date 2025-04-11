from utils.testbase import HelmChartTestBase

class AciTestBase(HelmChartTestBase):
    _kinds = ['Deployment','Ingress','Service','ConfigMap']
    version = '24.4'

    def test_names(self):
        ''' Chart produces expected kinds/names '''
        name = 'test-name'
        objs = self.render_chart({'name':name})
        expect = { k:[name] for k in self.kinds }
        expect['ConfigMap'] = [f'{name}-default-cfg']
        for kind,names in expect.items():
            self.assertGreaterEqual(set(objs[kind].keys()), set(names))

    def test_using_tls(self):
        ''' usingTLS sets IDOL_SSL environment variable '''
        objs = self.render_chart({'usingTLS':True})
        self.check_tls(objs, [self.name()])
                    
    def test_custom_data(self):
        ''' annotations/labels etc. written to Deployments/StatefulSets '''
        objs = self.render_chart(self.get_test_custom_data())
        self.check_custom_data(objs, [self.name()])

    def test_oem(self):
        objs = self.render_chart({'global':{'idolOemLicenseSecret':'oem-secret'}, 'workingDir':'/testoem'})
        for k,obj in self.workloads(objs, [self.name()]):
            volumeMounts = obj['spec']['template']['spec']['containers'][0]['volumeMounts']
            self.assertTrue(any([ { 'name': 'oem-license','mountPath': '/testoem/licensekey.dat',
                'subPath': 'licensekey.dat'}.items() <= x.items() for x in volumeMounts]))

    def test_additionalVolumes_dict(self):
        self.check_additionalVolumes_dict()

    def test_replicas(self):
        ''' replicas can be set '''
        replicas = 0
        objs = self.render_chart({'name': 'test', 'replicas': replicas})
        for k in set(self._kinds).intersection(['Deployment', 'StatefulSet']):
            ss = objs.get(k, {}).get('test', None)
            self.assertIsNotNone(ss)
            self.assertEqual(ss['spec']['replicas'], 0)

class StatefulSetTests():
    def test_volume_claim_templates(self):
        ''' Any StatefulSets do not contain chart version in volumeClaimTemplate labels '''
        objs = self.render_chart({'name': 'test-vct', 'labels':{'hello':'world'}})
        ss = objs.get('StatefulSet', {}).get('test-vct', None)
        if ss:
            self.assertIn('helm.sh/chart', ss['metadata']['labels'].keys())
            self.assertIn('helm.sh/chart', ss['spec']['template']['metadata']['labels'].keys())
            for vct in ss['spec']['volumeClaimTemplates']:
                self.assertNotIn('helm.sh/chart', vct['metadata']['labels'].keys())

