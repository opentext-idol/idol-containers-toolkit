# BEGIN COPYRIGHT NOTICE
# Copyright 2023-2024 Open Text.
#
# The only warranties for products and services of Open Text and its affiliates and licensors
# ("Open Text") are as may be set forth in the express warranty statements accompanying such
# products and services. Nothing herein should be construed as constituting an additional warranty.
# Open Text shall not be liable for technical or editorial errors or omissions contained herein.
# The information contained herein is subject to change without notice.
#
# END COPYRIGHT NOTICE

# all charts
CHARTS:=$(subst /,,$(dir $(wildcard */Chart.yaml)))

# charts with values schema
SCHEMA_CHARTS:=$(subst /,,$(dir $(wildcard */values.schema.json)))

# Non-packaging charts
SKIP_PACKAGE_CHARTS:=idol-library-example-test

CLEAN_CHARTS:=$(addprefix clean-,${CHARTS})
PACKAGE_CHARTS:=$(addprefix package-,$(filter-out ${SKIP_PACKAGE_CHARTS},${CHARTS}))
VALIDATE_SCHEMA_CHARTS:=$(addprefix validateschema-,${SCHEMA_CHARTS})

PYTHON_CMD?=python3

# charts for which we use helm-docs to generate the README.md from README.md.gotmpl
README_CHARTS:=$(basename $(wildcard */README.md.gotmpl))
THIS_YEAR?=$(shell date +%Y)

UPDATE_DEPENDENCIES?=-u

# update-versions parameters
# Can overwrite UPDATE_VERSIONS_CHARTS to specify which charts to update
# Will update all chart versions by default
UPDATE_VERSIONS_CHARTS ?= $(CHARTS)
UPDATE_VERSIONS_DRY_RUN?=
UPDATE_VERSIONS_DECREMENT?=

.PHONY: package-all ${PACKAGE_CHARTS} 
.PHONY: clean-all ${CLEAN_CHARTS} 
.PHONY: validate-all ${VALIDATE_SCHEMA_CHARTS}
.PHONY: update-versions

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
${PACKAGE_CHARTS}: package-% : %/README.md 
	if [ -z `git ls-files --other --exclude-standard $*` ]; then \
		helm package ${UPDATE_DEPENDENCIES} -d staging/release $*/ ; \
	else \
		echo "Untracked files exist in $*" ; \
	fi

# generated README.md files
${README_CHARTS}: %/README.md: %/values.yaml %/Chart.yaml %/README.md.gotmpl
	docker run --rm -v `pwd`/$*:/helm-docs -u `id -u` jnorwood/helm-docs:latest

package-all: ${PACKAGE_CHARTS}

# run schema validation
${VALIDATE_SCHEMA_CHARTS}: validateschema-%: utils/validate.schema.py
	${PYTHON_CMD} utils/validate.schema.py c $*

# add schema validation as prerequisite for packaging
$(addprefix package-,${SCHEMA_CHARTS}): package-% : validateschema-%

validate-all: ${VALIDATE_SCHEMA_CHARTS}

# update chart versions
update-versions:
	${PYTHON_CMD} utils/updateversions.py --charts $(UPDATE_VERSIONS_CHARTS) $(UPDATE_VERSIONS_DRY_RUN) $(UPDATE_VERSIONS_DECREMENT)

${CLEAN_CHARTS}: clean-% : 
	-${RM} $*/charts/*
	-${RM} $*/Chart.lock

clean-all: ${CLEAN_CHARTS}

# Makefile variable debugging (e.g. make print-CHARTS)
print-%  : ; @echo $* = $($*)
