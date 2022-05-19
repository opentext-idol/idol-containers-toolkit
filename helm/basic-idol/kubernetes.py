###
# Copyright (c) 2019-2020 Micro Focus or one of its affiliates.
#
# Licensed under the MIT License (the "License"); you may not use this file
# except in compliance with the License.
#
# The only warranties for products and services of Micro Focus and its affiliates
# and licensors ("Micro Focus") are as may be set forth in the express warranty
# statements accompanying such products and services. Nothing herein should be
# construed as constituting an additional warranty. Micro Focus shall not be
# liable for technical or editorial errors or omissions contained herein. The
# information contained herein is subject to change without notice.
###

""" runs dependencies and relevant values files for helm-generates Kubernetes clusters """

import argparse
import os
import sys

HELM_DIRECTORY = os.path.dirname(__file__)
BASE_DIRECTORY = os.path.abspath(os.path.join(HELM_DIRECTORY, '..'))

sys.path.insert(0, os.path.join(BASE_DIRECTORY, 'common-files', 'python-libs'))

from helm import create_configmaps, launch_kubernetes, clear_kubernetes

def argparser():
    p = argparse.ArgumentParser()
    p.add_argument('--upgrade', action='store_true', help='do not install from scratch, merely upgrade the chart')
    p.add_argument('--no_reverseproxy', action='store_true', help='do not use reverse-proxy')
    p.add_argument('--documentsecurity', action='store_true', help='use document security in setup')
    p.add_argument('--mmap', action='store_true', help='launch an mmap cluster')
    p.add_argument('--name', default='helm-basic-idol', help='name of the generated helm chart') 
    p.add_argument('--chart', default=os.path.join(HELM_DIRECTORY, 'charts', 'basic-idol'), help='location of the chart settings') 
    p.add_argument('--variables', default=os.path.join(HELM_DIRECTORY, 'charts', 'basic-idol', 'variables'), help='location of the .values files which overwrite default values.yaml')
    p.add_argument('--basicidol', default=os.path.join(BASE_DIRECTORY, 'basic-idol'), help='location of the compose basic-idol directory')
    p.add_argument('--clean', action='store_true', help='delete all related pods, services and configmaps')
    return p

def clean_kubernetes(name, basicidol):
    configmaps = [
        '{}/nifi/flow'.format(basicidol),
        '{}/httpd-reverse-proxy'.format(basicidol),
        '{}/../common-files/mmap-postgres'.format(args.basicidol),
        '{}/content'.format(basicidol),
        '{}/omnigroupserver'.format(basicidol),
        '{}/community'.format(basicidol)
    ]
    clear_kubernetes(name, configmaps)

if __name__=='__main__':
    args, other = argparser().parse_known_args()

    if args.clean:
        clean_kubernetes(args.name, args.basicidol)

    else:
        if args.mmap and args.documentsecurity:
            raise ValueError("You must choose at most one of mmap or document security setups.")

        #create a list of values files to be applied to 'helm install' command
        values_files = ['{}/env.values'.format(args.variables)]

        #create nifi configmaps (for all types of idol setup)
        create_configmaps('{}/nifi/flow'.format(args.basicidol))

        #add reverse-proxy values and configmaps
        if not args.no_reverseproxy:
            values_files.append('{}/reverse-proxy.values'.format(args.variables))
            create_configmaps('{}/httpd-reverse-proxy'.format(args.basicidol))

        #add mmap values and configmaps
        if args.mmap:
            values_files.append('{}/mmap.values'.format(args.variables))
            create_configmaps('{}/../common-files/mmap-postgres'.format(args.basicidol))
            
        #add document security values and configmaps
        if args.documentsecurity:
            values_files.append('{}/document-security.values'.format(args.variables))
            create_configmaps('{}/content'.format(args.basicidol))
            create_configmaps('{}/omnigroupserver'.format(args.basicidol))
            create_configmaps('{}/community'.format(args.basicidol))

        #launch Kubernetes
        launch_kubernetes(args.name, args.chart, values_files, args.upgrade)
