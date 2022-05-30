
MAINTAINER?=idol
CERTGEN_IMAGE_NAME:=certgen
CERTGEN_IMAGE_VERSION?=latest

CERTGEN_PURPOSE?=serving

CERTS_DIR:=$(abspath certs)
CA_DIR:=$(abspath ca)

.PHONY: certgen-docker-image

GENCERT=docker run --rm -v $(CERTS_DIR):/certs \
    -v $(CA_DIR):/ca \
    --env PURPOSE=$(1) \
	--env SERVICE_NAME=$(2) \
	--env NAMESPACE=$(3) \
	$(MAINTAINER)/$(CERTGEN_IMAGE_NAME):$(CERTGEN_IMAGE_VERSION)

SERVING_FILES:=$(addprefix $(CERTS_DIR)/,$(addprefix serving,.crt .key))

$(CERTS_DIR)/serving.gen: certgen-docker-image $(CERTS_DIR)
	$(call GENCERT,serving,idol-dih-metrics,default)

serving-files: $(CERTS_DIR)/serving.gen


certgen-docker-image:
	docker build -t $(MAINTAINER)/$(CERTGEN_IMAGE_NAME):$(CERTGEN_IMAGE_VERSION) \
	--build-arg http_proxy=$(HTTP_PROXY) \
	--build-arg HTTP_PROXY=$(HTTP_PROXY) \
	--build-arg https_proxy=$(HTTP_PROXY) \
	--build-arg HTTPS_PROXY=$(HTTP_PROXY) \
	.

$(CERTS_DIR):
	mkdir -p $(CERTS_DIR)
