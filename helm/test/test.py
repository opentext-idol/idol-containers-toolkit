import os
import subprocess
import unittest
import yaml

from tempfile import NamedTemporaryFile
from typing import Dict, Optional

def render_chart(chartpath: str, values: Optional[Dict] = None, name: str ='test') -> Dict:
    values = values or {}
    with NamedTemporaryFile() as tmp_file:
        content = yaml.dump(values)
        tmp_file.write(content.encode())
        tmp_file.flush()
        templates = subprocess.check_output(["helm", "template", '--values', tmp_file.name, name, chartpath])
        ret = dict()
        for obj in yaml.load_all(templates, Loader=yaml.FullLoader):
            if not obj:
                continue
            kind = obj['kind']
            name = obj['metadata']['name']
            if kind not in ret:
                ret[kind] = dict()
            ret[kind][name] = obj
        return ret

class TestIdolLibraryExample(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.chartpath = os.path.join('..','idol-library-example-test')
        #if os.path.isdir(cls.chartpath):
        #    subprocess.check_output(['helm','dependency','update',cls.chartpath])
        return super().setUpClass()

    def test_defaults(self):
        objs = render_chart(self.chartpath)
        self.assertEqual(set(['Deployment','StatefulSet','Ingress','Service','ConfigMap']), set(objs.keys()))
        expect_version = '24.4'
        for t in ['Deployment','StatefulSet']:
            with self.subTest(t):
                self.assertRegex(objs[t]['idol-aci-test']['spec']['template']['spec']['containers'][0]['image'],
                                 f'.+:{expect_version}$')

    def test_names(self):
        name = 'test-name'
        objs = render_chart(self.chartpath, values={'name':name})
        for kind,names in {'Deployment':[name], 'StatefulSet':[name], 
                           'Ingress':[name], 'Service':[name], 'ConfigMap':[f'{name}-default-cfg']}.items():
            self.assertEqual(set(names),set(objs[kind].keys()))

    def test_using_tls(self):
        objs = render_chart(self.chartpath, values={'usingTLS':True})
        for t in ['Deployment','StatefulSet']:
            with self.subTest(t):
                self.assertIn({'name':'IDOL_SSL','value':'1'},
                            objs[t]['idol-aci-test']['spec']['template']['spec']['containers'][0]['env'])

if __name__ == '__main__':
    unittest.main()