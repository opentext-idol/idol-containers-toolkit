import os
import subprocess
import yaml

from tempfile import NamedTemporaryFile
from typing import Dict, Optional

class HelmChartTestBase():
    chartpath = 'dummy'
    update_dependency = False

    @classmethod
    def setUpClass(cls) -> None:
        if os.path.isdir(cls.chartpath) and cls.update_dependency:
            subprocess.check_output(['helm','dependency','update',cls.chartpath])
        return super().setUpClass()
    
    def default_values(self):
        values = subprocess.check_output(['helm','show','values',self.chartpath])
        return yaml.load(values, Loader=yaml.FullLoader)

    def render_chart(self, values: Optional[Dict] = None, name: str ='test') -> Dict:
        values = values or {}
        with NamedTemporaryFile() as tmp_file:
            content = yaml.dump(values)
            tmp_file.write(content.encode())
            tmp_file.flush()
            templates = subprocess.check_output(["helm", "template", '--values', tmp_file.name, name, self.chartpath])
            ret = dict()
            for obj in yaml.load_all(templates, Loader=yaml.FullLoader):
                if not obj:
                    continue
                kind = obj['kind']
                name = obj['metadata']['name']
                self.assertIn('apiVersion', obj)
                if kind not in ret:
                    ret[kind] = dict()
                self.assertNotIn(name, ret[kind])
                ret[kind][name] = obj
            return ret
    
    def test_render_default(self):
        ''' Chart renders successfully with default values '''
        objs = self.render_chart()
        self.assertNotEqual(0, len(objs))

