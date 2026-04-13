# Helm

## Basic usage

```bash
# add repo
helm repo add $REPO_NAME $REPO
# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# list packages in repo
helm search repo $REPO_NAME
# helm search repo fluentd

# install package
helm install $POD_NAME $REPO_NAME/$PACKAGE_NAME
# helm install prometheus prometheus-community/prometheus
```
