import os
import unittest

from utils.acibase import AciTestBase

class TestIdolLibraryExample(AciTestBase, unittest.TestCase):
    chartpath = os.path.join('..','idol-library-example-test')
    _kinds = ['Deployment','StatefulSet','Ingress','ConfigMap','Service']

class TestIdolAnswerServer(AciTestBase, unittest.TestCase):
    chartpath = os.path.join('..','idol-answerserver')
    _kinds = ['StatefulSet','Ingress','ConfigMap','Service']

class TestSingleContent(AciTestBase, unittest.TestCase):
    chartpath = os.path.join('..','single-content')
    _kinds = ['StatefulSet','Ingress','ConfigMap','Service']

if __name__ == '__main__':
    unittest.main()