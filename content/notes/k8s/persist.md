# Persistence

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
