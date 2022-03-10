#!/bin/bash
###
# Copyright (c) 2021 Micro Focus or one of its affiliates.
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

source /controller/startup_utils.sh

## Command to call with an HTTP request
MAKE_REQUEST="wget -qO-"

## Functions to add services to controller
function add_content_service {
    content_controller_hostname=$1

    # Wait for controller to be available
    waitForAci ${content_controller_hostname}:41200
    # Add service
    ${MAKE_REQUEST} "http://localhost:41200/a=addservice&execpath=/content/content.exe&configpath=/content/cfg/content.cfg&controlmethod=script&initscriptpath=/content/control-content.sh"
}

function add_support_services {
    # Add agentstore, categorisation-agentstore, community, view

    support_controller_hostname=$1

    # Wait for controllers to be available
    waitForAci ${support_controller_hostname}:41200

    # Agentstore
    ${MAKE_REQUEST} "http://localhost:41200/a=addservice&execpath=/agentstore/agentstore.exe&configpath=/agentstore/cfg/agentstore.cfg&controlmethod=script&initscriptpath=/agentstore/control-agentstore.sh"

    # Categorisation-agentstore
    ${MAKE_REQUEST} "http://localhost:41200/a=addservice&execpath=/categorisation-agentstore/categorisation-agentstore.exe&configpath=/categorisation-agentstore/cfg/categorisation-agentstore.cfg&controlmethod=script&initscriptpath=/categorisation-agentstore/control-categorisation-agentstore.sh"

    # Community
    ${MAKE_REQUEST} "http://localhost:41200/a=addservice&execpath=/community/community.exe&configpath=/community/cfg/community.cfg&controlmethod=script&initscriptpath=/community/control-community.sh"

    # View
    ${MAKE_REQUEST} "http://localhost:41200/a=addservice&execpath=/view/view.exe&configpath=/view/cfg/view.cfg&controlmethod=script&initscriptpath=/view/control-view.sh"
}

function add_siteadmin_backend_services {
    # Add agentstore, community

    siteadmin_backend_controller_hostname=$1

    # Wait for controllers to be available
    waitForAci ${siteadmin_backend_controller_hostname}:41200

    # Agentstore
    ${MAKE_REQUEST} "http://localhost:41200/a=addservice&execpath=/agentstore/agentstore.exe&configpath=/agentstore/cfg/agentstore.cfg&controlmethod=script&initscriptpath=/agentstore/control-agentstore.sh"

    # Community
    ${MAKE_REQUEST} "http://localhost:41200/a=addservice&execpath=/community/community.exe&configpath=/community/cfg/community.cfg&controlmethod=script&initscriptpath=/community/control-community.sh"
}


## Functions to start services
function start_content {
    content_controller_hostname=$1

    # Wait for controller to be available
    waitForAci ${content_controller_hostname}:41200

    # Start service
    ${MAKE_REQUEST} "http://localhost:41200/a=startservice&port=9100"
    waitForAci localhost:9100
}

function start_support_services {
    # Add agentstore, categorisation-agentstore, community, view

    support_controller_hostname=$1
    content_controller_hostname=$2

    # Wait for controllers to be available
    waitForAci ${support_controller_hostname}:41200
    waitForAci ${content_controller_hostname}:41200

    # Agentstore
    ${MAKE_REQUEST} "http://localhost:41200/a=startservice&port=9050"
    waitForAci localhost:9050

    # Categorisation-agentstore
    ${MAKE_REQUEST} "http://localhost:41200/a=startservice&port=9182"
    waitForAci localhost:9182

    # Community
    waitForAci ${content_controller_hostname}:9100
    ${MAKE_REQUEST} "http://localhost:41200/a=startservice&port=9030"
    waitForAci localhost:9030

    # View
    ${MAKE_REQUEST} "http://localhost:41200/a=startservice&port=9080"
    waitForAci localhost:9080
}

function start_siteadmin_backend_services {
    # Add agentstore, community

    support_controller_hostname=$1
    content_controller_hostname=$2

    # Wait for controllers to be available
    waitForAci ${support_controller_hostname}:41200
    waitForAci ${content_controller_hostname}:41200

    # Agentstore
    ${MAKE_REQUEST} "http://localhost:41200/a=startservice&port=9050"
    waitForAci localhost:9050

    # Community
    waitForAci ${content_controller_hostname}:9100
    ${MAKE_REQUEST} "http://localhost:41200/a=startservice&port=9030"
    waitForAci localhost:9030
}


function add_to_coordinator {
    controller_hostname=$1
    # Once coordinator is ready, add this controller to it
    waitForAci idol-coordinator:40200
    ${MAKE_REQUEST} "http://idol-coordinator:40200/a=addcontroller&HostName="${controller_hostname}"&Port=41200&ConnectByHostName=True"
}