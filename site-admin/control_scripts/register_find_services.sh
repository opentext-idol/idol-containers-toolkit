#!/bin/bash

source /controller/add_services.sh

add_support_services idol-controller-find-backend-bundle
start_support_services idol-controller-find-backend-bundle idol-controller-content-bundle
add_to_coordinator idol-controller-find-backend-bundle
