from utils.testbase import HelmChartTestBase

class AciTestBase(HelmChartTestBase):
    _kinds = ['Deployment','Ingress','Service','ConfigMap']
    version = '24.4'

    @property
    def kinds(self):
        return self._kinds

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
        objs = self.render_chart({'name':'idol-aci-test', 'usingTLS':True})
        for t in ['Deployment','StatefulSet']:
            if t in self.kinds:
                with self.subTest(t):
                    self.assertIn({'name':'IDOL_SSL','value':'1'},
                                objs[t]['idol-aci-test']['spec']['template']['spec']['containers'][0]['env'])
                    
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

