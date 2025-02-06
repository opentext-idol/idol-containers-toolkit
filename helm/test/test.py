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