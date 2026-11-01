

## 3. Deploy all probe demos

```bash
kubectl apply -f probes/
kubectl get pods -n probe-demo -w
```

Wait until all three pods are ready before continuing:

```bash
kubectl wait \
  --for=condition=Ready \
  pod \
  --all \
  -n probe-demo \
  --timeout=120s
```

## 4. Startup probe simulation

The default startup delay is 20 seconds. The startup probe permits 15 failures
at two-second intervals, giving the application roughly 30 seconds to start.

Watch the initial delayed startup:

```bash
kubectl get pods -n probe-demo -l app=startup-demo -w
```

```bash
kubectl logs -n probe-demo deployment/startup-demo -f
```

Set a delay longer than the startup-probe allowance:

```bash
kubectl set env deployment/startup-demo \
  -n probe-demo \
  STARTUP_DELAY_SECONDS=40
```

Watch Kubernetes repeatedly restart the container:

```bash
kubectl get pods -n probe-demo -l app=startup-demo -w
kubectl describe pod -n probe-demo -l app=startup-demo
```

Restore a successful startup time:

```bash
kubectl set env deployment/startup-demo \
  -n probe-demo \
  STARTUP_DELAY_SECONDS=5

kubectl rollout status deployment/startup-demo -n probe-demo
```

## 5. Readiness probe simulation

Start a port-forward in one terminal:

```bash
kubectl port-forward \
  -n probe-demo \
  deployment/readiness-demo \
  8081:8080
```

In another terminal, make the readiness endpoint fail:

```bash
curl http://localhost:8081/control/not-ready
```

The container remains running, but the pod changes to `0/1` Ready and is
removed from the Service endpoints:

```bash
kubectl get pods,endpoints -n probe-demo -w
kubectl describe pod -n probe-demo -l app=readiness-demo
```

Restore readiness:

```bash
curl http://localhost:8081/control/ready
```

The pod returns to `1/1` Ready and is added back to the Service endpoints.

## 6. Liveness probe simulation

Start a port-forward:

```bash
kubectl port-forward \
  -n probe-demo \
  deployment/liveness-demo \
  8082:8080
```

In another terminal, make the liveness endpoint fail:

```bash
curl http://localhost:8082/control/fail
```

The probe runs every three seconds. After three failures, Kubernetes restarts
the container:

```bash
kubectl get pods -n probe-demo -l app=liveness-demo -w
kubectl describe pod -n probe-demo -l app=liveness-demo
```

Verify that the restart count increased and inspect the previous container's
logs:

```bash
kubectl get pods -n probe-demo -l app=liveness-demo
kubectl logs -n probe-demo deployment/liveness-demo --previous
```

After restarting, the application's in-memory liveness state resets and the
new container becomes healthy.

## 7. Cleanup

```bash
kubectl delete -f probes/
kubectl delete -f memory-hpa-lab.yaml
```
