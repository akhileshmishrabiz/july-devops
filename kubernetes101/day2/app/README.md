# DevOps Deployment Game

A small Flask application that stores its deployment score in PostgreSQL.
PostgreSQL uses a 5 Gi PVC from the `standard` StorageClass.

## Run on Kind

From this directory:

```bash
docker build -t devops-game:latest .
kind load docker-image devops-game:latest
kubectl apply -f kubernetes.yaml
kubectl wait --for=condition=available deployment/postgres --timeout=120s
kubectl wait --for=condition=available deployment/devops-game --timeout=120s
kubectl port-forward service/devops-game 8080:80
```

Open <http://localhost:8080> and click **Ship a deployment** a few times.

## Demonstrate persistence

Check the current score, delete the PostgreSQL pod, and wait for Kubernetes
to recreate it:

```bash
kubectl delete pod -l app=postgres
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s
```

Refresh the page. The score is unchanged because the database files remain
on `postgres-pvc`.

You can also restart both deployments:

```bash
kubectl rollout restart deployment/postgres deployment/devops-game
kubectl rollout status deployment/postgres
kubectl rollout status deployment/devops-game
```

Deleting the PVC deletes the persisted game data:

```bash
kubectl delete -f kubernetes.yaml
```
