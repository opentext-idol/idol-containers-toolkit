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

# Sends a request to add a useradmin user to community, so that siteadmin doesn't require configuration

## Command to call with an HTTP request
MAKE_REQUEST="curl -s"

function add_useradmin {
    # $1 host:port
    local USERNAME=useradmin
    local PASSWORD=useradmin
    local ROLE=useradmin
    ${MAKE_REQUEST} "http://"${1}"/a=RoleAdd&RoleName="${ROLE}
    ${MAKE_REQUEST} "http://"${1}"/a=UserAdd&RoleName="${ROLE}"&userName="${USERNAME}"&password="${PASSWORD}
}
