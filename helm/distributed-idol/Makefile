# To make a new release
# - Update templates as required
# - Update Chart.yaml (at least increment version)
# - Run make release/distributed-idol-x.y.z.tgz 
# - Run make index.yaml

.PHONY: clean-charts

release/distributed-idol-%.tgz: clean-charts
	helm package -u -d release --version $* .

index.yaml: clean-charts
	helm repo index . --merge index.yaml

clean-charts:
	-${RM} charts/*