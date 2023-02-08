.PHONY: clean-charts

release/distributed-idol-%.tgz: clean-charts
	helm package -u -d release --version $* .

index.yaml: clean-charts
	helm repo index . --merge index.yaml

clean-charts:
	-${RM} charts/*