# CD

## FluxCD

### Setup

#### Gitea integration

Bootstrap command creates kustomization repository, installs flux operator into kubernetes under flux-system namespace
Note: if you want to uninstall flux just run `flux uninstall`

```bash
# install fluxcd CLI
curl -s https://fluxcd.io/install.sh | sudo bash

# Settings -> Applications -> Create token
# Also, for some reason i was able to create it first using --insecure-skip-tls-verify, but then recreated it
flux bootstrap gitea \
--token-auth \
--owner=alex.dvorak \
--repository=flux-kustomization-repo \
--branch=main \
--path=clusters/aperture \
--personal \
--hostname gitea.aperture.ad \
--certificate-authority $PATH_TO_API_SERVER_CERT \
--ca-file $PATH_TO_GITEA_CERT
# Please enter your Gitea personal access token (PAT): 0f2cbf55fb1cb8f47209aca6923d21025bf8c141

~#   git clone https://$USER:$PAT@gitea.aperture.ad/$USER/flux-kustomization-repo
cd flux-kustomization-repo

# create an application source ()
flux create source git gfub \
--url=https://gitea.aperture.ad/alex.dvorak/GFUB \
--branch=main \
--interval=1m \
--export > ./clusters/aperture/gfub-source.yaml

git add -A && git commit -m "Add GFUB GitRepository" && git push

# make sure names match (name of git source "gfub" and --source "gfub")
flux create kustomization gfub \
--target-namespace=gfub \
--source=gfub \
--path="./kustomize" \
--prune=true \
--wait=true \
--interval=30m \
--retry-interval=2m \
--health-check-timeout=3m \
--export > ./clusters/aperture/gfub-kustomization.yaml

git add -A && git commit -m "Add GFUB Kustomization" && git push
```

FluxCD will reset all labels and modifications to deployments and other resources, so in order to add our CA to containers we must patch them.
Resources are contained within fluxcd's gotk-components.yaml file that contains Namespace, Deployment definintions and CRDs.
In order to patch it we need to define kustomization: [https://fluxcd.io/flux/installation/configuration/bootstrap-customization/](https://fluxcd.io/flux/installation/configuration/bootstrap-customization/)

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
: Kustomization
urces:
gotk-components.yaml
gotk-sync.yaml
hes:
patch: |
  - op: add
    path: /metadata/labels/use-internal-ca
    value: "true"
target:
  kind: Namespace
  labelSelector: "app.kubernetes.io/part-of=flux"

patch: |
  - op: add
    path: /spec/template/spec/volumes/-
    value:
      name: internal-root-ca
      configMap:
        name: internal-root-ca

  - op: add
    path: /spec/template/spec/volumes/-
    value:
      name: ca-store
      emptyDir: {}

  - op: add
    path: /spec/template/spec/containers/0/volumeMounts/-
    value:
      name: ca-store
      mountPath: /etc/ssl/certs/

  - op: add
    path: /spec/template/spec/initContainers
    value: []

  - op: add
    path: /spec/template/spec/initContainers/-
    value:
      name: build-ca
      image: docker.io/fluxcd/flux:1.17.0
      imagePullPolicy: IfNotPresent
      command:
        - /usr/sbin/update-ca-certificates
      volumeMounts:
        - mountPath: /usr/local/share/ca-certificates/
          name: internal-root-ca
          readOnly: true
        - mountPath: /etc/ssl/certs/
          name: ca-store
target:
  kind: Deployment
  name: "source-controller"
```

```bash
git add -A && git commit -m "modify resources" && git push

# wait
flux get kustomizations --watch
```

Now we get `kustomization path not found: stat /tmp/kustomization-393043959/kustomize: no such file or directory`, this is because we set `./kustomize` path and flux expects manifests inside this path within our GFUB repository in order to deploy the project to kubernetes.
