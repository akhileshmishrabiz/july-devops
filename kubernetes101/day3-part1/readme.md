# DevOps Incident Arena

The Flask app includes a persistent deployment counter and a Linux
disk-usage troubleshooting lab. PostgreSQL credentials and the database URL
are mounted as secret files. Application and lab settings are mounted from a
ConfigMap.

## Run with Docker Compose

```bash
docker compose up --build
```

Open <http://localhost:8080>. Stop the stack with:

```bash
docker compose down
```

Add `-v` to remove the PostgreSQL volume and its saved score.

Compose creates secret mounts from the files in `secrets/`. These values are
for this local lab only; use a secret manager or untracked files for real
credentials. The app reads `DB_URL` from `/run/secrets/DB_URL` and reads its
settings from files under `/etc/app-config`.

## Run on Kind

Build and load the application image:

```bash
docker build -t appwithdb:1.0 app
kind load docker-image appwithdb:1.0 --name day2
```

Create the PVC, Secret, PostgreSQL deployment, ConfigMap, and app:

```bash
kubectl apply -f database/pvc.yaml
kubectl apply -f database/postgres-secret.yaml
kubectl apply -f database/postgres-dep.yaml
kubectl apply -f app-depl.yaml
kubectl port-forward service/app-service 8080:8080
```

The PostgreSQL service DNS name is
`postgres-service.default.svc.cluster.local`.

Kubernetes creates `postgres-secret` from `database/postgres-secret.yaml` and
mounts it at `/etc/postgres-secret`. It creates `app-config` from
`app-depl.yaml` and mounts it at `/etc/app-config`.

## Rotate the database password without restarting the app

The app rereads `/etc/postgres-secret/DB_URL` whenever it opens a database
connection. Kubernetes updates mounted Secret volumes automatically, so the
app pods do not need a rollout.

First, note the existing app pods so you can verify they are not replaced:

```bash
kubectl get pods -l app=app
```

Choose a simple lab password and change the password inside the running
database:

```bash
NEW_PASSWORD='NewAdmin5678'

kubectl exec deployment/postgres -- \
  psql -U postgres -d postgres -v ON_ERROR_STOP=1 \
  -c "ALTER ROLE postgres WITH PASSWORD '${NEW_PASSWORD}';"
```

Now update both password values in the normal Kubernetes Secret:

```bash
kubectl patch secret postgres-secret --type merge -p \
  "{\"stringData\":{\"POSTGRES_PASSWORD\":\"${NEW_PASSWORD}\",\"DB_URL\":\"postgresql://postgres:${NEW_PASSWORD}@postgres-service.default.svc.cluster.local:5432/postgres\"}}"
```

Kubernetes may take up to roughly two minutes to refresh a mounted Secret.
With the app still port-forwarded, watch it recover using the new file value:

```bash
until curl -fsS http://localhost:8080/healthz; do
  echo "Waiting for the Secret volume to refresh..."
  sleep 5
done

kubectl get pods -l app=app
```

The pod names and start times remain unchanged. There may be a short database
error window between changing PostgreSQL and the Secret volume refresh.

`POSTGRES_PASSWORD_FILE` is only used when PostgreSQL initializes an empty
data directory. Updating the Secret alone does not alter the password in an
existing database, which is why the `ALTER ROLE` command is required.
Also update `database/postgres-secret.yaml` with the new values before its
next `kubectl apply`, or that manifest will restore the old Secret.

## Change the lab

For Kubernetes, edit the `app-config` ConfigMap in `app-depl.yaml`. For
Compose, edit the files in `config/`. The app rereads these files for every
page request, so mounted updates do not require an app restart.

```bash
kubectl apply -f app-depl.yaml
```



#######

# on the app path 

kind create cluster --name day2 --config kind-config 

cd july-devops/kubernetes101/day2/app

docker build -t day2 .

kind load docker-image day2 --name day2

cd .. 

10041  kubectl config use-context kind-day2
10042  kubectl apply -f database/
10043  kubectl apply -f app-depl.yaml


####

cd  july-devops/kubernetes101/day3-part1

kind create cluster --name day2 --config kind-config 

cd app

docker build -t day3 .

kind load docker-image day3 --name day3

cd july-devops/kubernetes101/day3-part1

kubectl config use-context kind-day3

❯ kubectl apply -f database

❯ kubectl apply -f app-depl.yaml