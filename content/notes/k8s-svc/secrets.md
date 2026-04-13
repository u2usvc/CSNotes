# Secrets Management

## Vault

### Setup

#### Integrate with K8s

```bash
# enable (create) a new KV (v2) secrets engine under k8s/prod/gfub 
vault secrets enable -path=k8s -version=2 kv

# store secrets (store in batch, each `put` does an override)
vault kv put k8s/prod/gfub/atsvc \
JWT_SECRET_KEY="da0a56e4c80c7aa7f93aad7452efdec2f759f915xl38dan" \
DATABASE_PASSWORD="sohd801h08h10fhv1" \
APPLICATION_URL="https://atsvc.com" \
SPRING_PROFILES_ACTIVE="dev" \
DATABASE_USERNAME="admin" \
DATABASE_URL="jdbc:postgresql://db:5432/atsvc" \
REDIS_HOST="redis" \
REDIS_PORT="6379" \
POSTGRES_USER="admin" \
POSTGRES_PASSWORD="sohd801h08h10fhv1" \
POSTGRES_DB="atsvc"

# verify
vault kv get k8s/prod/gfub/atsvc
```

Install external secrets

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets external-secrets/external-secrets \
--namespace external-secrets \
--create-namespace
```

Note: The ExternalSecret specifies what to fetch, the SecretStore specifies how to access.
[https://external-secrets.io/main/api/externalsecret/](https://external-secrets.io/main/api/externalsecret/)
[https://external-secrets.io/main/api/secretstore/](https://external-secrets.io/main/api/secretstore/)

```bash
???
cat external-secrets.yaml
# ---
# apiVersion: external-secrets.io/v1
# kind: SecretStore
# metadata:
#   name: vault-backend
# spec:
#   provider:
#     vault:
#       server: "https://vault.aperture.ad:8200"
#       path: k8s #?
#       version: v2
#       auth:
#         tokenSecretRef:
#           name: vault-token
#           namespace: gfub
#           key: token
#       caProvider:
#         type: ConfigMap
#         name: internal-root-ca
#         key: "ca.crt"
# ---
# apiVersion: external-secrets.io/v1
# kind: ExternalSecret
# metadata:
#   name: prod-gfub
#   namespace: gfub
# spec:
#   refreshInterval: 1m
#   secretStoreRef:
#     name: vault-backend
#     kind: SecretStore
#   target:
#     name: prod-gfub
#   data:
#     - secretKey: JWT_SECRET_KEY
#       remoteRef:
#         key: prod/gfub/atsvc
#         property: JWT_SECRET_KEY
#     - secretKey: DATABASE_PASSWORD
#       remoteRef:
#         key: prod/gfub/atsvc
#         property: DATABASE_PASSWORD
#     - secretKey: APPLICATION_URL
#       remoteRef:
#         key: prod/gfub/atsvc
#         property: APPLICATION_URL
#     - secretKey: SPRING_PROFILES_ACTIVE
#       remoteRef:
#         key: prod/gfub/atsvc
#         property: SPRING_PROFILES_ACTIVE
#     - secretKey: DATABASE_USERNAME
#       remoteRef:
#         key: prod/gfub/atsvc
#         property: DATABASE_USERNAME
#     - secretKey: DATABASE_URL
#       remoteRef:
#         key: prod/gfub/atsvc
#         property: DATABASE_URL
#     - secretKey: REDIS_HOST
#       remoteRef:
#         key: prod/gfub/atsvc
#         property: REDIS_HOST
#     - secretKey: REDIS_PORT
#       remoteRef:
#         key: prod/gfub/atsvc
#         property: REDIS_PORT
#     - secretKey: POSTGRES_USER
#       remoteRef:
#         key: prod/gfub/atsvc
#         property: POSTGRES_USER
#     - secretKey: POSTGRES_PASSWORD
#       remoteRef:
#         key: prod/gfub/atsvc
#         property: POSTGRES_PASSWORD
#     - secretKey: POSTGRES_DB
#       remoteRef:
#         key: prod/gfub/atsvc
#         property: POSTGRES_DB
```

```bash
kubectl create namespace gfub

cat ./gfub-policy.hcl
# path "k8s/data/prod/gfub/atsvc" {
#   capabilities = ["read", "list"]
# }
#
# path "k8s/metadata/prod/gfub/atsvc" {
#   capabilities = ["read", "list"]
# }

vault policy write gfub-policy ./gfub-policy.hcl

vault token create -policy=gfub-policy -period=0 -orphan
# token: $TOKEN

kubectl create secret generic vault-token --namespace gfub --from-literal=token="$TOKEN"

kubectl apply -f ./external-secrets.yaml
kubectl label namespace gfub use-internal-ca=true

# verify
kubectl -n gfub get externalsecret
kubectl -n gfub get secret
```

Fix certificate issues when external-secrets operator tries to connect to vault:

```bash
kubectl label namespace external-secrets use-internal-ca=true
```

Configure secret for kubernetes to be able to pull image from private harbor repo and allow default SA to use that secret:

```bash
kubectl create secret docker-registry reg-token --docker-server=https://harbor.aperture.ad/ --docker-username=kubernetes --docker-password="coolpasswd" --docker-email="kubernetes@aperture.ad"
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "reg-token"}]}'
```

#### Setup on Proxmox

Install Hashicorp Vault to an external server.
I will use docker community script to dep [https://community-scripts.github.io/ProxmoxVE/scripts?id=docker&category=Containers+%26+Docker](https://community-scripts.github.io/ProxmoxVE/scripts?id=docker&category=Containers+%26+Docker)

```bash
export $(grep -v '^#' .env | xargs)
ssh -i $TF_VAR_pve_ssh_key_path root@pve.aperture.ad

bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/docker.sh)"
# select advanced install, choose root passwd and configure ssh key
# add compose plugin
# ......... installation completed
exit
```

I will now generate certs for vault on my workstation:

```bash
openssl genrsa -out vault.aperture.ad.key 4096

cat > vault.aperture.ad.cnf <<EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
CN = vault.aperture.ad

[req_ext]
subjectAltName = @san

[san]
DNS.1 = vault.aperture.ad
EOF

# on WS
openssl req -new \
-key vault.aperture.ad.key \
-out vault.aperture.ad.csr \
-config vault.aperture.ad.cnf

openssl x509 -req \
-in vault.aperture.ad.csr \
-CA k8s-aperture-root-ca.crt \
-CAkey k8s-aperture-root-ca.key \
-CAcreateserial \
-out vault.aperture.ad.crt \
-days 825 \
-sha256 \
-extensions req_ext \
-extfile vault.aperture.ad.cnf

sftp -i vault root@vault.aperture.ad
> put certificates/vault.aperture.ad.crt /root/vault/certs/server.crt
> put certificates/vault.aperture.ad.key /root/vault/certs/server.key
> put certificates/k8s-aperture-root-ca-01.crt /usr/local/share/ca-certificates/
```

After docker LXC installation, exit proxmox ssh and ssh into docker LXC.

```bash
update-ca-certificates

mkdir -p $HOME/vault/{config,file,logs,certs}
cd $HOME/vault/certs/

cd $HOME/vault
cat <<EOF > docker-compose.yaml
version: '3.3'
services:
  vault:
    image: hashicorp/vault
    container_name: vault-new
    environment:
      VAULT_ADDR: "https://vault.aperture.ad:8200"
      VAULT_API_ADDR: "https://vault.aperture.ad:8200"
      VAULT_ADDRESS: "https://vault.aperture.ad:8200"
      # VAULT_UI: true
      # VAULT_TOKEN:
    ports:
      - "8200:8200"
      - "8201:8201"
    restart: always
    volumes:
      - ./logs:/vault/logs/:rw
      - ./data:/vault/data/:rw
      - ./config:/vault/config/:rw
      - ./certs:/certs/:rw
      - ./file:/vault/file/:rw
    cap_add:
      - IPC_LOCK
    entrypoint: vault server -config /vault/config/config.hcl
EOF

cd $HOME/vault/config
cat <<EOF > config.hcl
ui = true
disable_mlock = "true"

storage "raft" {
  path    = "/vault/data"
  node_id = "node1"
}

listener "tcp" {
  address = "[::]:8200"
  tls_disable = "false"
  tls_cert_file = "/certs/server.crt"
  tls_key_file  = "/certs/server.key"
}

api_addr = "https://vault.aperture.ad:8200"
cluster_addr = "https://vault.aperture.ad:8201"
EOF

cd $HOME/vault
docker compose up -d

# Exec into the vault container
docker exec -it vault-new /bin/sh

# Once logged into the vault container
vault operator init
# store the unseal keys and the token outputted

# run the following in the container, entering 3 different unseal keys
vault operator unseal
vault operator unseal
vault operator unseal

# install vault on your workstation
export VAULT_ADDR="https://vault.aperture.ad:8200"
vault login
# Token (will be hidden):
```
