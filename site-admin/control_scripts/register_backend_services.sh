#!/bin/bash

source /controller/add_services.sh

add_siteadmin_backend_services idol-controller-siteadmin-backend-bundle
start_siteadmin_backend_services idol-controller-siteadmin-backend-bundle idol-controller-content-bundle
add_to_coordinator idol-controller-siteadmin-backend-bundle
