# Recon

## Basic

### import SA token

```bash
# KUBERNETES_PORT (if kubectling from the container) or the apiserver external IP, ca.crt, token
kubectl config set-cluster my-cluster \
--server=https://$API_SERVER:$PORT \
--certificate-authority=/path/to/ca.crt \
--embed-certs=true

kubectl config set-credentials sa-user \
--token="$SA_TOKEN"

kubectl config set-context sa-context \
--cluster=my-cluster \
--user=sa-user

kubectl config use-context sa-context

kubectl auth can-i --list
```
