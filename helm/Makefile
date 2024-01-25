# BEGIN COPYRIGHT NOTICE
# (c) Copyright 2023 Micro Focus or one of its affiliates.
# END COPYRIGHT NOTICE

SUBCHARTS:=idol-library \
	idol-licenseserver \
	idol-community \
	idol-find \
	idol-nifi \
	idol-omnigroupserver \
	idol-stack \
	idol-qms \
	idol-answerserver \
	distributed-idol \
	single-content

PACKAGE_SUBCHARTS:=$(addprefix package-,${SUBCHARTS})
CLEAN_SUBCHARTS:=$(addprefix clean-,${SUBCHARTS})
# subcharts for which we use helm-docs to generate the README.md from README.md.gotmpl
README_SUBCHARTS:=$(basename $(wildcard */README.md.gotmpl))

UPDATE_DEPENDENCIES?=-u

.PHONY: package-all ${PACKAGE_SUBCHARTS} clean-all ${CLEAN_SUBCHARTS}

default: package-all index.yaml

# This moves any staged packages to release and updates the index.yaml
# Uses staging to avoid trampling existing timestamps
# See https://github.com/helm/helm/issues/7363 
index.yaml: $(wildcard staging/release/*)
	cd staging && helm repo index . --merge ../index.yaml && cd ..
	mv staging/release/* release/.
	mv staging/index.yaml index.yaml

# packages releases to staging directory
${PACKAGE_SUBCHARTS}: package-% : %/README.md
	helm package ${UPDATE_DEPENDENCIES} -d staging/release $*/

${README_SUBCHARTS}: %/README.md: %/values.yaml %/Chart.yaml %/README.md.gotmpl
	docker run --rm -v `pwd`/$*:/helm-docs -u `id -u` jnorwood/helm-docs:latest

package-all: ${PACKAGE_SUBCHARTS}

${CLEAN_SUBCHARTS}: clean-% : 
	-${RM} $*/charts/*

clean-all: ${CLEAN_SUBCHARTS}

