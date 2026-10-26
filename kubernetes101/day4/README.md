# Kubernetes HPA and VPA Scaling Lab

This lab creates two independent applications in the `scaling` namespace:

- `hpa-app`: Horizontal Pod Autoscaler changes the replica count from 1 to 8
  based on CPU utilization.
- `vpa-app`: Vertical Pod Autoscaler changes the container CPU and memory
  requests and limits based on observed usage.

Metrics Server is installed with Kind-compatible TLS settings. The VPA
recommender, updater, and admission controller are installed with Helm.

## Run the lab

```bash
chmod +x run.sh
./run.sh
./run.sh hpa
./run.sh watch
```

Running `./run.sh` without arguments installs Metrics Server and VPA, then
deploys both applications with their load generators scaled to zero.

Run only the load scenario you want:

```bash
./run.sh hpa
./run.sh vpa
```

The two load generators are independent, so starting HPA load does not start
VPA load. Stop them independently or together:

```bash
./run.sh stop-hpa
./run.sh stop-vpa
./run.sh stop
```

Press `Ctrl+C` to stop `./run.sh watch`; traffic continues until stopped.

## What to expect

HPA normally reacts within one or two minutes. Watch the `hpa-app` replica
count increase while CPU remains above its 50% request-utilization target.
After stopping traffic, the replicas return toward one.

VPA needs several minutes of metrics before producing useful recommendations.
With `updateMode: Auto`, it may evict and recreate `vpa-app` so the pod starts
with its recommended requests and limits. Inspect the recommendation with:

```bash
kubectl describe vpa vpa-app -n scaling
kubectl get pod -n scaling \
  -l app=vpa-app \
  -o jsonpath='{.items[0].spec.containers[0].resources}{"\n"}'
```

Check Metrics Server directly:

```bash
kubectl top nodes
kubectl top pods -n scaling
```

## Commands

```bash
./run.sh
./run.sh hpa
./run.sh vpa
./run.sh stop-hpa
./run.sh stop-vpa
./run.sh stop
./run.sh status
./run.sh watch
./run.sh cleanup
```

`cleanup` removes the `scaling` namespace, VPA controllers, and Metrics
Server.
