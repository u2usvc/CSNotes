# General

## kompose (convert docker compose to k8s manifests)

- you can specify custom options using labels (e.g. if you want to use StatefulSet instead of a Deployment)

```yaml
version: "3.9"

services:
  app:
    image: your-spring-boot-app:latest
    container_name: springboot-app
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://db:5432/mydb
      SPRING_DATASOURCE_USERNAME: postgres
      SPRING_DATASOURCE_PASSWORD: postgres
      SPRING_REDIS_HOST: redis
      SPRING_REDIS_PORT: 6379
    depends_on:
      - db
      - redis

  db:
    image: postgres:15
    labels:
      kompose.service.type: nodeport
      kompose.controller.type: statefulset
    container_name: postgres-db
    environment:
      POSTGRES_DB: mydb
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - db-data:/var/lib/postgresql/data

  redis:
    image: redis:7
    container_name: redis
    ports:
      - "6379:6379"

volumes:
  db-data:
```

```bash
kompose convert -f compose.yaml

ls -la
# app-deployment.yaml                 db-service.yaml
# app-service.yaml                    redis-deployment.yaml
# compose.yaml                        redis-service.yaml
# db-data-persistentvolumeclaim.yaml  db-deployment.yaml
```

PersistentVolumeClaim is generated if `volumes` are attached.

## minikube

### Basic

```bash
# start multinode KVM cluster
minikube start --cpus 2 --memory 8000 --nodes 3 --kvm-network='k8s_lab' --cni=cilium

# delete existing cluster (e.g. to change options)
minikube delete

# add nodes to an existing cluster (minikube node add)

# list logs
minikube logs
```
