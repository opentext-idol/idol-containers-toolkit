# BEGIN COPYRIGHT NOTICE
# (c) Copyright 2023 Micro Focus or one of its affiliates.
# END COPYRIGHT NOTICE

SUBCHARTS:=idol-library \
	idol-licenseserver \
	idol-find \
	idol-nifi \
	distributed-idol \
	single-content

PACKAGE_SUBCHARTS:=$(addprefix package-,${SUBCHARTS})
CLEAN_SUBCHARTS:=$(addprefix clean-,${SUBCHARTS})

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
${PACKAGE_SUBCHARTS}: package-% : 
	helm package ${UPDATE_DEPENDENCIES} -d staging/release $*/

package-all: ${PACKAGE_SUBCHARTS}

${CLEAN_SUBCHARTS}: clean-% : 
	-${RM} $*/charts/*

clean-all: ${CLEAN_SUBCHARTS}

