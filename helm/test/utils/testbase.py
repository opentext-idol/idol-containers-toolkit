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
        '''
        Check that the IDOL_SSL environment variable is set to "1" in each workload's container spec.
        '''
        for kind,obj in self.workloads(objs, names):
            with self.subTest(kind):
                self.assertIn({'name':'IDOL_SSL','value':'1'},
                            obj['spec']['template']['spec']['containers'][0]['env'])

    @staticmethod
    def get_test_custom_data():
        labels = {'test-label':'test-label-value'}
        annotations = {'test-annotation':'test-annotation-value'}
        return {
                'labels': labels,
                'annotations': annotations,
                'serviceAccountName': 'test-svc'
               }

    def check_custom_data(self, objs, names):
        ''' annotations/labels etc. written to Deployments/StatefulSets '''
        expected_custom_data = self.get_test_custom_data()
        for kind,obj in self.workloads(objs, names):
            with self.subTest(kind):
                with self.subTest(f'{kind}-annotations'):
                    self.assertEqual(expected_custom_data['annotations'],
                                        obj['spec']['template']['metadata']['annotations'])

                with self.subTest(f'{kind}-labels'):
                    self.assertLessEqual(expected_custom_data['labels'].items(),
                                            obj['spec']['template']['metadata']['labels'].items())

                with self.subTest(f'{kind}-serviceAccountName'):
                    self.assertEqual(expected_custom_data['serviceAccountName'],
                                        obj['spec']['template']['spec']['serviceAccountName'])

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

    def security_context_value(self):
        ''' A securityContext configuration  value to test with '''
        return { 'enabled': True, 'runAsGroup': 123}

    def check_security_context(self, names=['thing'], values=None):
        if values is None:
            values = {'podSecurityContext': self.security_context_value(),
                'containerSecurityContext': self.security_context_value(),
                'name':'thing'}
        objs = self.render_chart(values)
        for name in names:
            workloads = { k:o for k,o in self.workloads(objs, [name])}
            self.assertGreater(len(workloads), 0, f'no workloads found for {name}')
            for kind,obj in workloads.items():
                self.assertLessEqual({'runAsGroup':123}.items(), obj['spec']['template']['spec']['securityContext'].items())
                self.assertNotIn('enabled', obj['spec']['template']['spec']['securityContext'].keys())
                self.assertLessEqual({'runAsGroup':123}.items(), obj['spec']['template']['spec']['containers'][0]['securityContext'].items())
                self.assertNotIn('enabled', obj['spec']['template']['spec']['containers'][0]['securityContext'].keys())
    
    def test_security_context(self):
        ''' containerSecurityContext and podSecurityContext render correctly when used '''
        self.check_security_context()
