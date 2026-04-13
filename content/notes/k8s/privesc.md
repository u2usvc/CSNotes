# PrivEsc

## arbitrary pod creation abuse

If you're allowed to create

```bash
kubectl auth can-i create pods
# being able to create this resource effectively means the ability to execute following operations:

# Create *any* pod (if no policy engine (e.g. Kyverno) is present within the cluster)
kubectl apply -f myPod.yaml
```

Now, you should be able to create a pod and mount any secret (either as mount or enviroment variable) into it. That allows new opportunities to attack the rest of the cluster.
