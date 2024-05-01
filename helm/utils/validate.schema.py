# BEGIN COPYRIGHT NOTICE
# Copyright 2023-2024 Open Text.
#
# The only warranties for products and services of Open Text and its affiliates and licensors
# ("Open Text") are as may be set forth in the express warranty statements accompanying such
# products and services. Nothing herein should be construed as constituting an additional warranty.
# Open Text shall not be liable for technical or editorial errors or omissions contained herein.
# The information contained herein is subject to change without notice.
#
# END COPYRIGHT NOTICE

import argparse
import json
import jsonschema
import pathlib
import sys
import yaml

# This should be equivalent to calling:
#  check-jsonschema --schemafile <chart>/values.schema.json <chart>/values.yaml 
# but gives slightly better/clearer debugging information

ap = argparse.ArgumentParser()
sub = ap.add_subparsers(title='subcommands', dest='mode', required=True)
chart = sub.add_parser('chart', aliases=['c'], description='validate values.yaml against values.schema.json in chartpath')
chart.add_argument('chartpath', help='path to chart to validate')

files = sub.add_parser('files', aliases=['f'], description='validate values file against schema')
files.add_argument('schema_json', help='path to json schema')
files.add_argument('values', help='path to values.yaml/json')

args = ap.parse_args()

if args.mode.startswith('f'):
    schema_path = args.schema_json
    instance_path = args.values
else:
    schema_path = f'{args.chartpath}/values.schema.json'
    instance_path = f'{args.chartpath}/values.yaml'

schema = json.loads(pathlib.Path(schema_path).read_text('utf-8'))
if instance_path.endswith('.json'):
    instance = json.loads(pathlib.Path(instance_path).read_text('utf-8'))
else:
    instance = yaml.load(pathlib.Path(instance_path).read_text('utf-8'), Loader=yaml.SafeLoader)

# The idol-licenseserver chart deliberately has its values setup to fail schema validation
if (instance.get('licenseServerIp',None)=='must be a valid ip address, or set null and specify licenseServerExternalName'):
    print('Adjusting values for checking idol-licenseserver schema validation')
    instance['licenseServerIp'] = '1.2.3.4'
    del(instance['licenseServerExternalName'])

jsonschema.validate(instance, schema, format_checker=jsonschema.FormatChecker())
print("schema validation ok")
sys.exit(0)