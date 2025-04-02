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
    def test_replicas(self):
        ''' replicas can be set '''
        replicas = 0
        objs = self.render_chart({'name': 'test', 'replicas': replicas})
        for k in ['Deployment', 'StatefulSet']:
            ss = objs.get(k, {}).get('test', None)
            self.assertIsNotNone(ss)
            self.assertEqual(ss['spec']['replicas'], replicas)

class TestIdolAnswerServer(AciTestBase, unittest.TestCase):
    chartpath = os.path.join('..','idol-answerserver')
    _kinds = ['StatefulSet','Ingress','ConfigMap','Service']

class TestIdolCommunity(AciTestBase, unittest.TestCase):
    chartpath = os.path.join('..','idol-community')

class TestIdolEductionServer(AciTestBase, unittest.TestCase):
    chartpath = os.path.join('..','idol-eductionserver')

class TestIdolMediaServer(AciTestBase, unittest.TestCase):
    chartpath = os.path.join('..','idol-mediaserver')

class TestIdolOmniGroupServer(AciTestBase, StatefulSetTests, unittest.TestCase):
    chartpath = os.path.join('..','idol-omnigroupserver')
    _kinds = ['StatefulSet','Ingress','ConfigMap','Service']

class TestIdolQms(AciTestBase, unittest.TestCase):
    chartpath = os.path.join('..','idol-qms')

class TestIdolView(AciTestBase, unittest.TestCase):
    chartpath = os.path.join('..','idol-view')
    _kinds = ['Deployment','Ingress','ConfigMap','Service']

class TestSingleContent(AciTestBase, StatefulSetTests, unittest.TestCase):
    chartpath = os.path.join('..','single-content')
    _kinds = ['StatefulSet','Ingress','ConfigMap','Service']

if __name__ == '__main__':
    unittest.main()