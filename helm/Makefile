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
	idol-view \
	distributed-idol \
	single-content

PACKAGE_SUBCHARTS:=$(addprefix package-,${SUBCHARTS})
CLEAN_SUBCHARTS:=$(addprefix clean-,${SUBCHARTS})
# subcharts for which we use helm-docs to generate the README.md from README.md.gotmpl
README_SUBCHARTS:=$(basename $(wildcard */README.md.gotmpl))
THIS_YEAR?=$(shell date +%Y)

UPDATE_DEPENDENCIES?=-u

.PHONY: package-all ${PACKAGE_SUBCHARTS} clean-all ${CLEAN_SUBCHARTS}

default: package-all index.yaml

# This moves any staged packages to release and updates the index.yaml
# Uses staging to avoid trampling existing timestamps
# See https://github.com/helm/helm/issues/7363 
index.yaml: $(wildcard staging/release/*) ot_copyright_notice.stl
	cd staging && helm repo index . --merge ../index.yaml && cd ..
	mv staging/release/* release/.
	sed "s/XX_YEAR_XX/${THIS_YEAR}/" ot_copyright_notice.stl > index.yaml.nxt
	cat staging/index.yaml >> index.yaml.nxt
	rm staging/index.yaml
	mv index.yaml.nxt index.yaml

# packages releases to staging directory
${PACKAGE_SUBCHARTS}: package-% : %/README.md
	if [ -z `git ls-files --other --exclude-standard $*` ]; then \
		helm package ${UPDATE_DEPENDENCIES} -d staging/release $*/ ; \
	else \
		echo "Untracked files exist in $*" ; \
	fi

${README_SUBCHARTS}: %/README.md: %/values.yaml %/Chart.yaml %/README.md.gotmpl
	docker run --rm -v `pwd`/$*:/helm-docs -u `id -u` jnorwood/helm-docs:latest

package-all: ${PACKAGE_SUBCHARTS}

${CLEAN_SUBCHARTS}: clean-% : 
	-${RM} $*/charts/*

clean-all: ${CLEAN_SUBCHARTS}

