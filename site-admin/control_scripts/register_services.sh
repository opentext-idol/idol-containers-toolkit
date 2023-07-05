#!/bin/bash

source /controller/add_services.sh

add_content_service idol-controller-content-bundle
start_content idol-controller-content-bundle
add_to_coordinator idol-controller-content-bundle
