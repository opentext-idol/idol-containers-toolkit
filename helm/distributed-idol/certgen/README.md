# Certificate generation helper

A certificate generation script run inside a Docker container to produce the certificates required for the custom-metrics adapter.
See https://github.com/kubernetes-sigs/apiserver-builder-alpha/blob/master/docs/concepts/auth.md for context.


## Usage

If you want to regenerate `serving.crt` and `serving.key` for your cluster, find your certificate and key of your cluster's `requestheader-client-ca-file` argument to your `kube-apiserver` process. The generation script expects the files to be in the `certgen/ca` and called `front-proxy-ca.crt` and `front-proxy-ca.key`. To call the script, use the Makefile. Once successfully run, you should have the `serving.crt` and `serving.key` in the `certgen/certs` directory.