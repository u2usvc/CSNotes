# GitOps

## Gitea

### Persistence

#### create an admin user

```bash
kubectl -n gitea exec -it gitea-6456cd87bf-mdr8r -- /bin/bash
gitea admin user create --username admin --admin --email admin@aperture.ad --random-password --must-change-password=false
```

### Setup

#### K8s + Gitea Actions + Harbor

```bash
helm repo add gitea-charts https://dl.gitea.com/charts/
helm repo update

helm show values gitea-charts/actions > gitea-runner-values.yaml
# enabled: true
#     # See full example here: https://gitea.com/gitea/act_runner/src/branch/main/internal/pkg/config/config.example.yaml
#     config: |
#       log:
#         level: debug
#       cache:
#         enabled: false
#       container:
#         require_docker: true
#         docker_timeout: 300s
#         network: "host"
#         valid_volumes:
#           - '**'
#         options: "-e 'DOCKER_TLS_VERIFY=1' -e 'DOCKER_CERT_PATH=/certs/server' -e 'DOCKER_HOST=tcp://127.0.0.1:2376' --volume /etc/ssl/certs:/etc/ssl/certs:ro --volume /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro --volume /certs/client:/certs/server:ro"

#
# ## Specify an existing token secret
# ##
# existingSecret: "gitea-runner-token"
# existingSecretKey: "token"
#
# ## Specify the root URL of the Gitea instance
# giteaRootURL: "https://gitea.aperture.ad"
#
# ## @section Global
# global:
#   imageRegistry: "harbor.aperture.ad/gitea"
#   storageClass: "rook-ceph-block"

helm upgrade --install --namespace gitea gitea-actions gitea-charts/actions -f gitea-runner-values.yaml

# or you can retrieve it via GUI (Site admininistration > Actions > Runners)
kubectl -n gitea exec -it deploy/gitea -c gitea -- gitea actions generate-runner-token
kubectl -n gitea create secret generic gitea-runner-token --from-literal=token=$TOKEN

kubectl label --overwrite namespace gitea \
pod-security.kubernetes.io/enforce=privileged \
pod-security.kubernetes.io/enforce-version=latest

# kubectl -n gitea logs gitea-actions-act-runner-0 -c act-runner

kubectl -n gitea patch deployment gitea \
--type='json' \
-p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "internal-root-ca",
      "configMap": {
        "name": "internal-root-ca"
      }
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "ca-store",
      "emptyDir": {}
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts/-",
    "value": {
"name": "ca-store",
      "mountPath": "/etc/ssl/certs/",
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/initContainers/-",
    "value": {
      "name": "build-ca",
      "image": "docker.io/fluxcd/flux:1.17.0",
      "imagePullPolicy": "IfNotPresent",
      "command": ["/usr/sbin/update-ca-certificates"],
      "volumeMounts": [
        {
          "mountPath": "/usr/local/share/ca-certificates/",
          "name": "internal-root-ca",
          "readOnly": true
        },
        {
          "mountPath": "/etc/ssl/certs/",
          "name": "ca-store"
        }
      ]
    }
  }
]'

# now add the CA on nodes to allow initContainers to use custom CA. This will allow initContainers that will use harbor.aperture.ad/gitea repo to validate harbor's self-signed cert
# it required me to reboot all talos nodes for this to work.
cat talos-ca.yaml
# apiVersion: v1alpha1
# kind: TrustedRootsConfig
# name: custom-ca
# certificates: |-
#   -----BEGIN CERTIFICATE-----
#   ...
#   -----END CERTIFICATE-----
talosctl patch mc --nodes 192.168.88.245,192.168.88.244,192.168.88.243,192.168.88.242 --patch @talos-ca.yaml

# add CA to runner container so that it can verify gitea instance
# Make sure to mount /etc/ssl/certs/ to both containers (including dind), because "valid_volumes" option from gitea act runner config fetches volumes from dind container
kubectl -n gitea patch statefulset gitea-actions-act-runner \
--type='json' \
-p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "internal-root-ca",
      "configMap": {
        "name": "internal-root-ca"
      }
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "ca-store",
      "emptyDir": {}
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts/-",
    "value": {
      "name": "ca-store",
      "mountPath": "/etc/ssl/certs/"
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/1/volumeMounts/-",
    "value": {
      "name": "ca-store",
      "mountPath": "/etc/ssl/certs/"
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/initContainers/-",
    "value": {
      "name": "build-ca",
      "image": "docker.io/fluxcd/flux:1.17.0",
      "imagePullPolicy": "IfNotPresent",
      "command": ["/usr/sbin/update-ca-certificates"],
      "volumeMounts": [
        {
          "mountPath": "/usr/local/share/ca-certificates/",
          "name": "internal-root-ca",
          "readOnly": true
        },
        {
          "mountPath": "/etc/ssl/certs/",
          "name": "ca-store"
        }
      ]
    }
  }
]'

# reload
kubectl -n gitea delete pod gitea-actions-act-runner-0
```

WISH TO RESET? delete the actions-runner PVC and dont forget to patch the statefulset for the runner to add the certificate (and then delete the pod)

if youre getting the following errors:

```
level=info msg="Registering runner, arch=amd64, os=linux, version=v0.2.13."
Error: parse config file "/actrunner/config.yaml": yaml: unmarshal errors:
line 12: mapping key "options" already defined at line 6
Waiting to retry ...
```

then fix your config file

Harbor:

1. Add a "Docker Hub" repository called docker-hub-proxy
2. Add a new project with name=gitea, access_level=public and proxy=true,docker-hub-proxy
3. Create a regular user account for gitea
4. Go to project you created -> Members -> + User -> gitea (admin)

dind is a separate container that runs a docker daemon and exposes docker TCP socket port to the act_runner container. act_runner container is responsible for communication with gitea, while dind is reponsible for running CI containers.
dind container needs to be privileged, because dockerd uses some kernel capabilities such as cgroups to function properly

If you exec into the main container using `kubectl -n gitea exec -it pod/gitea-actions-act-runner-0 -- /bin/bash` and observe it's env vars you're gonna see that it uses `DOCKER_HOST=tcp://127.0.0.1:2376` socket, which runs on it's sidecar `dind` container.

The buildx jobs to run successfully, the CI container must be able to connect to docker daemon. In order to do that it must get it's default DOCKER_HOST value (which is `unix:///var/run/docker.sock`) overriten to dind docker TCP socket (which is `localhost:2376` if network=host). In order to establish secure connection we need to provide the buildx job path to it's certificates (client certificates).
We cannot mount the contents of `/certs/server` directory of dind container to CI containers, because this directory container server key.

dockerd on the remote host is started with the following server-side arguments `--tlsverify --tlscacert /certs/server/ca.pem --tlscert /certs/server/cert.pem --tlskey /certs/server/key.pem`, these arguments can be retrieved by running the following command: `kubectl -n gitea exec -it pod/gitea-actions-act-runner-0 -c dind -- /bin/bash ps auxf` and observing which arguments does the host docker utility work with.

in order to pass the correct TLS credentials to the `docker buildx` client, theoretically we would need to generate client certs for the client using an initContainer and then mount the output directory to CI container using --volume argument, fortunately the first step (generating certs) is already been done for us, these certs are held inside the `/certs/client` directory on the dind host. The weird thing is that buildx action searches for certificates in /certs/server directory (I ASSUME THAT'S BECAUSE I SET DOCKER_CERT_PATH to `/certs/server`, NEVERMIND), instead of /certs/client, that's why we mount as follows: `--volume /certs/client:/certs/server:ro`

Once i deployed the container first i didn't have an internet connection from CI container. I first thought that that was because of the MTU values of node-interface eth0 and docker0 interface that is used to launch CI containers by DinD, however it wasn't the problem. The real problem was that the `network: "host"` parameter i specified inside the gitea-actions-act-runner configuration is only being applied to the main runner image (e.g. `docker.gitea.com/runner-images:ubuntu-latest`).
Here's how the DinD container looks like while i run the pipeline containing buildx jobs:

```bash
docker container ps --all --no-trunc
# CONTAINER ID                                                       IMAGE                                          COMMAND                                                                                                CREATED          STATUS          PORTS     NAMES
# 97fda5bdc9ca06b88a314a5680b54b70f7228fbe8c8ee7fa6364f87f24ddcf4c   moby/buildkit:buildx-stable-1                  "buildkitd --allow-insecure-entitlement security.insecure --allow-insecure-entitlement network.host"   34 seconds ago   Up 33 seconds             buildx_buildkit_builder-2b8aa5f9-c26e-44af-bcac-cab07d69add20
# bd39d69c97b12e201cd5ad9dadce704c68a9ba9ab35f7a8e48f9936391e0f6f8   docker.gitea.com/runner-images:ubuntu-latest   "/bin/sleep 10800"                                                                                     40 seconds ago   Up 40 seconds             GITEA-ACTIONS-TASK-121_WORKFLOW-Build-and-Push-Docker-Image_JOB-build
```

This all means that if we run a job such as `run: docker build ...` (which runs inside the main runner container `runner-images`) we will utilize all variables and options that we passed to gitea-actions-act-runner inside it's helm values, but when we run jobs that create their own separate container (such as `docker/setup-buildx-action`), options we specified earlier are not known to them (meaning, network will not be host's). This is why you need to add the network=host option when running buildx jobs. Same things goes for certificates. Since we only have `/etc/ssl/certs/ca-certificates.crt` file containing our internal root CA certificate, instead of having this certificate stored separately, we would need to mount it separately into dind:

```bash
kubectl -n gitea patch statefulset gitea-actions-act-runner --type='json' \
-p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "internal-ca",
      "configMap": {
        "name": "internal-root-ca"
      }
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/1/volumeMounts/-",
    "value": {
      "name": "internal-ca",
      "mountPath": "/etc/ssl/certs/internal-ca.crt",
      "subPath": "ca.crt",
      "readOnly": true
    }
  }
]'
```

```yaml
  - name: Set up Docker Buildx
    uses: docker/setup-buildx-action@v3
    with:
      driver-opts: |
        network=host
      config-inline: |
        [registry."harbor.aperture.ad"]
          ca=["/etc/ssl/certs/internal-ca.crt"]
```

#### migrate from valkey-cluster to valkey

I was getting segfault crashes on my valkey-cluster pods

```bash
helm upgrade --install gitea gitea-charts/gitea \
--namespace gitea \
--set postgresql-ha.enabled=false \
--set postgresql.enabled=true \
--set persistence.storageClass='rook-ceph-block' \
--set postgresql.primary.persistence.storageClass='rook-ceph-block' \
--set gitea.config.server.ROOT_URL=https://gitea.aperture.ad/ \
--set valkey-cluster.enabled=false \
--set valkey.enabled=true \
--set valkey.persistence.storageClass='rook-ceph-block'
```
