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

""" base helper functions for helm scripts """

import subprocess

def run_and_check_returncode(cmd):
    try:
        subprocess.run(cmd).check_returncode()
    except subprocess.CalledProcessError as e:
        print(e, "Continuing...")

def create_configmaps(directory):
    run_and_check_returncode(['kubectl','create','-k', directory])

def delete_configmaps(directory):
    run_and_check_returncode(['kubectl','delete','-k', directory])

def launch_kubernetes(name, chart, values, upgrade=False):
    action = 'upgrade' if upgrade else 'install'
    command = ['helm', action, name, chart]
    command.extend(['--values={}'.format(v) for v in values])
    run_and_check_returncode(command)

def clear_kubernetes(name, configmaps):
    #uninstall chart
    run_and_check_returncode(['helm','delete', name])
    #delete all possible configmaps
    for configmap in configmaps:
        delete_configmaps(configmap)
