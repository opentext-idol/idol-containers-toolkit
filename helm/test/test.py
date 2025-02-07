import os
import unittest

from utils.acibase import AciTestBase, StatefulSetTests
from utils.testbase import HelmChartTestBase

# Testing options
HelmChartTestBase.validation_namespace = ''
HelmChartTestBase.debug = False

class TestIdolLibraryExample(AciTestBase, StatefulSetTests, unittest.TestCase):
    chartpath = os.path.join('..','idol-library-example-test')
    _kinds = ['Deployment','StatefulSet','Ingress','ConfigMap','Service']

    def test_oem(self):
        objs = self.render_chart({'global':{'idolOemLicenseSecret':'oem-secret'}, 'workingDir':'/testoem'})
        volumeMounts = objs['StatefulSet']['idol-aci-test']['spec']['template']['spec']['containers'][0]['volumeMounts']
        self.assertTrue(any([ { 'name': 'oem-license','mountPath': '/testoem/licensekey.dat',
            'subPath': 'licensekey.dat'}.items() <= x.items() for x in volumeMounts]))
        
    def test_additionalVolumes_array(self):
        vols = [
            { 'name': 'extra', 'configMap': {'name': 'extra'} }
        ]
        mounts = [
            { 'name': 'extra', 'mountPath': 'extra' }
        ]
        objs = self.render_chart({'additionalVolumes': vols, 'additionalVolumeMounts': mounts })
        for k in ['StatefulSet', 'Deployment']:
            volumeMounts = objs[k]['idol-aci-test']['spec']['template']['spec']['containers'][0]['volumeMounts']
            for mount in mounts:
                self.assertIn(mount, volumeMounts)
            volumes = objs[k]['idol-aci-test']['spec']['template']['spec']['volumes']
            for vol in vols:
                self.assertIn(vol, volumes)

    def test_additionalVolumes_dict(self):
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
        for k in ['StatefulSet', 'Deployment']:
            volumeMounts = objs[k]['idol-aci-test']['spec']['template']['spec']['containers'][0]['volumeMounts']
            self.assertIn(mounts['extra'], volumeMounts)
            for omit in ['extraNull','extraEmpty', 'extraDeleted']:
                self.assertNotIn(mounts[omit], volumeMounts)
            volumes = objs[k]['idol-aci-test']['spec']['template']['spec']['volumes']
            self.assertIn(vols['extra'], volumes)
            for omit in ['extraNull','extraEmpty', 'extraDeleted']:
                self.assertNotIn(vols[omit], volumes)

class TestIdolAnswerServer(AciTestBase, unittest.TestCase):
    chartpath = os.path.join('..','idol-answerserver')
    _kinds = ['StatefulSet','Ingress','ConfigMap','Service']

class TestIdolCommunity(AciTestBase, unittest.TestCase):
    chartpath = os.path.join('..','idol-community')

class TestIdolEductionServer(AciTestBase, unittest.TestCase):
    chartpath = os.path.join('..','idol-eductionserver')

class TestIdolMediaServer(AciTestBase, unittest.TestCase):
    chartpath = os.path.join('..','idol-mediaserver')

class TestIdolOmniGroupServer(AciTestBase, unittest.TestCase):
    chartpath = os.path.join('..','idol-omnigroupserver')
    _kinds = ['StatefulSet','Ingress','ConfigMap','Service']

class TestIdolQms(AciTestBase, unittest.TestCase):
    chartpath = os.path.join('..','idol-qms')

class TestIdolView(AciTestBase, unittest.TestCase):
    chartpath = os.path.join('..','idol-view')

class TestSingleContent(AciTestBase, unittest.TestCase):
    chartpath = os.path.join('..','single-content')
    _kinds = ['StatefulSet','Ingress','ConfigMap','Service']

if __name__ == '__main__':
    unittest.main()