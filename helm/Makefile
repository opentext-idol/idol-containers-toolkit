# BEGIN COPYRIGHT NOTICE
# (c) Copyright 2023 Micro Focus or one of its affiliates.
# END COPYRIGHT NOTICE

SUBCHARTS:=idol-library \
	idol-licenseserver \
	distributed-idol

PACKAGE_SUBCHARTS:=$(addprefix package-,${SUBCHARTS})
CLEAN_SUBCHARTS:=$(addprefix clean-,${SUBCHARTS})

UPDATE_DEPENDENCIES?=-u

.PHONY: package-all ${PACKAGE_SUBCHARTS} clean-all ${CLEAN_SUBCHARTS}

default: package-all index.yaml

index.yaml: $(wildcard release/*)
	helm repo index . --merge index.yaml

${PACKAGE_SUBCHARTS}: package-% : 
	helm package ${UPDATE_DEPENDENCIES} -d release $*/

package-all: ${PACKAGE_SUBCHARTS}

${CLEAN_SUBCHARTS}: clean-% : 
	-${RM} $*/charts/*

clean-all: ${CLEAN_SUBCHARTS}

