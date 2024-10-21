import os
import pathlib
import subprocess
import yaml

from tempfile import TemporaryDirectory
from typing import Dict, Optional

class HelmChartTestBase():
    chartpath = 'dummy'         # path to chart
    update_dependency = False   # whether to run helm dependency update before running tests
    debug = False               # --debug
    # --validate requires a server connection and will clash with existing resources
    # so best to use an empty namespace to avoid
    validation_namespace = ''

    _kinds = None

    @property
    def kinds(self):
        return self._kinds

    @classmethod
    def setUpClass(cls) -> None:
        if os.path.isdir(cls.chartpath) and cls.update_dependency:
            subprocess.check_output(['helm','dependency','update',cls.chartpath])
        return super().setUpClass()

    def workloads(self, objs, names):
        for t in ['Deployment','StatefulSet']:
            if t not in self.kinds:
                continue
            for name, workload in objs[t].items():
                if name in names:
                        yield t, workload

    def check_tls(self, objs, names):
        for kind,obj in self.workloads(objs, names):
            with self.subTest(kind):
                self.assertIn({'name':'IDOL_SSL','value':'1'},
                            obj['spec']['template']['spec']['containers'][0]['env'])
    def default_values(self):
        values = subprocess.check_output(['helm','show','values',self.chartpath])
        return yaml.load(values, Loader=yaml.FullLoader)

    def render_chart(self, values: Optional[Dict] = None, name: str ='test') -> Dict:
        with TemporaryDirectory() as tmp_dir:
            cmd = ['helm','template', name, self.chartpath ]
            if values:
                content = yaml.dump(values)
                values_file = os.path.join(tmp_dir,'testvalues.yaml')
                pathlib.Path(values_file).write_text(content, 'utf-8')
                cmd.extend(['--values', values_file])
            if HelmChartTestBase.validation_namespace:
                cmd.extend(['-n', HelmChartTestBase.validation_namespace, '--validate'])
            if HelmChartTestBase.debug:
                cmd.extend(['--debug'])
            templates = subprocess.check_output(cmd)
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
