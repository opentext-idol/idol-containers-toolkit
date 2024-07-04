import os
import argparse

from ruamel.yaml import YAML

yaml = YAML()
yaml.preserve_quotes = True
yaml.indent(mapping=2, sequence=2, offset=0)
yaml.width = 4096  # prevents line wrapping

HELM_DIR = os.path.join(os.path.dirname(os.path.realpath(__file__)), '..')

# may need to change this in future if version conventions change
def increment_version(version: str, modifier: int):
    version_split = version.split('.')
    version_split[1] = str(int(version_split[1])+modifier)
    return '.'.join(version_split)

def get_chart_version(chart_dir: str):
    chart_yaml_path = os.path.join(HELM_DIR, chart_dir, 'Chart.yaml')
    with open(chart_yaml_path, 'r') as f:
        chart_yaml = yaml.load(f)
    return chart_yaml['version']

def update_chart_version(chart_dir: str, dry_run: bool, modifier: int):
    chart_yaml_path = os.path.join(HELM_DIR, chart_dir, 'Chart.yaml')
    with open(chart_yaml_path, 'r') as f:
        chart_yaml = yaml.load(f)
    
    chart_yaml['version'] = increment_version(chart_yaml['version'], modifier)
    
    if not dry_run:
        with open(chart_yaml_path, 'w') as f:
            yaml.dump(chart_yaml, f)
        
    return chart_yaml['name'], chart_yaml['version']

def get_dependencies(chart_dir: str):
    chart_yaml_path = os.path.join(HELM_DIR, chart_dir, 'Chart.yaml')
    with open(chart_yaml_path, 'r') as f:
        chart_yaml = yaml.load(f)
    if 'dependencies' in chart_yaml:
        return {dep['name']: dep['version'] for dep in chart_yaml['dependencies']}
    return {}  # no dependencies for this chart

def update_dependencies(chart_dir: str, updated_versions: dict, dependency_graph: dict, dry_run: bool):
    chart_yaml_path = os.path.join(HELM_DIR, chart_dir, 'Chart.yaml')
    with open(chart_yaml_path, 'r') as f:
        chart_yaml = yaml.load(f)

    if 'dependencies' in chart_yaml:
        for dep in chart_yaml['dependencies']:
            # only update dependency version if it's the latest one 
            if dep['name'] in updated_versions and dep['version'] == dependency_graph[dep['name']]['version']:
                dep['version'] = updated_versions[dep['name']]
        
        if not dry_run:
            with open(chart_yaml_path, 'w') as f:
                yaml.dump(chart_yaml, f)

def build_dependency_graph():
    graph = {}
    for chart_dir in os.listdir(HELM_DIR):
        if os.path.exists(os.path.join(HELM_DIR, chart_dir, 'Chart.yaml')):
            chart_version = get_chart_version(chart_dir)
            # include version so that we only update charts using the latest versions of updated charts
            graph[chart_dir] = {'version': chart_version, 'dependencies': get_dependencies(chart_dir)}
    return graph

def get_dependent_charts(graph: dict, chart_dir: str, latest_version: str):
    dependent_charts = []
    for key, value in graph.items():
        # only add the chart to the dependency list if it is the latest version
        if chart_dir in value['dependencies'] and value['dependencies'][chart_dir] == latest_version:
            dependent_charts.append(key)
    return dependent_charts

def update_charts(chart_dir: str, dry_run: bool, decrement: bool):
    dependency_graph = build_dependency_graph()
    updated_versions = {}
    charts_processed = set()
    modifier = -1 if decrement else 1

    def process_chart(chart_dir: str):
        if chart_dir in charts_processed:
            # don't update if already been updated
            return  
        # add to processed charts
        charts_processed.add(chart_dir)
        
        # update chart version
        name, version = update_chart_version(chart_dir, dry_run, modifier)
        updated_versions[name] = version
        print(f"Updated {name} to version {version}")

        # update charts that depend on this one and use the latest version
        dependents = get_dependent_charts(dependency_graph, chart_dir, dependency_graph[chart_dir]['version'])
        for dependent in dependents:
            process_chart(dependent)

    process_chart(chart_dir)

    # update dependencies for all processed charts
    for processed_chart in charts_processed:
        update_dependencies(processed_chart, updated_versions, dependency_graph, dry_run)
        
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Update Helm chart versions.')
    parser.add_argument('chart', help='Name of the chart to update, including all charts depending on it', type=str)
    parser.add_argument('--dry-run', action='store_true', help='prints updates that would occur, but does not actually modify any files')
    parser.add_argument('--decrement', action='store_true', help='decrement version numbers instead of incrementing them')
    args = parser.parse_args()

    if args.dry_run:
        print("DRY RUN, VERSIONS NOT UPDATED")
    else:
        # add the following so that multiline strings are dumped properly
        def str_presenter(dumper, data):
            if data.count('\n') > 0:  # check for multiline string
                return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='|')
            return dumper.represent_scalar('tag:yaml.org,2002:str', data)
        yaml.representer.add_representer(str, str_presenter)

    update_charts(args.chart, args.dry_run, args.decrement)