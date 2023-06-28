#!/bin/bash

_HTTP_PROXY_HOST=${HTTP_PROXY_HOST}
_HTTP_PROXY_PORT=${HTTP_PROXY_PORT}

function overwrite_proxy {
  
    sed -i "s/XX_PROXY_HOST_XX/${_HTTP_PROXY_HOST}/g" /view/view.cfg
    sed -i "s/XX_PROXY_PORT_XX/${_HTTP_PROXY_PORT}/g" /view/view.cfg
}

overwrite_proxy
