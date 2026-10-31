# Kubernetes 101 — Day 3 Follow-along

**Class:** July DevOps Bootcamp, 24 October 2026  
**Code:** [day3-part1](../day3-part1) and [day3-part2](../day3-part2)

This is the step-by-step guide for the whole class. Part A is the file-mount lab. Part B is StatefulSets, Helm, Vault, and External Secrets Operator. Do Part A first. It is the setup Part B builds on.

## Goal

By the end you should be able to:

- Explain why app pods talk to PostgreSQL through a Service DNS name.
- Feed a Secret and a ConfigMap as files inside a pod, and show that those values are not environment variables.
- Switch `kubectl` between two Kind clusters without deploying to the wrong one.
- Explain why a database uses a StatefulSet and a headless Service.
- Install Vault and External Secrets Operator with Helm, and let ESO create `postgres-secret` from Vault.

## Prerequisites

- Docker is running.
- `kubectl`, [Kind](https://kind.sigs.k8s.io/), and [Helm](https://helm.sh/) are installed.
- On macOS, Helm is `brew install helm`.
- You are at the repository root:

```bash
cd july-devops/kubernetes101
```

Check the active cluster before every apply or delete:

```bash
kubectl config current-context
```

---

## What day 1 and day 2 already covered

Day 1 was the cluster itself: control plane (`kube-apiserver`, `kube-scheduler`, `kube-controller-manager`, `etcd`) and worker nodes (`kubelet`, `kube-proxy`, container runtime).

Day 2 was storage and configuration:

- A PersistentVolumeClaim and a StorageClass for PostgreSQL data.
- A Secret for the database password, user, database name, and `DB_URL`.
- The app received `DB_URL` as an environment variable (`secretKeyRef` in `day2/app-depl.yaml`).
- CoreDNS publishes a name for every Service.

Day 2 fed the secret like this:

```yaml
env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: postgres-secret
        key: DB_URL
```

That value is fixed when the container starts. A new password in the Secret shows up only in pods created after the change.

---

## How the app reaches the database

Pods get new IPs when they are replaced. The app does not store a pod IP.

```text
you
  -> app-service
    -> one of the app pods
      -> postgres-service   (DNS inside the cluster)
        -> the postgres pod
```

`postgres-service` in the `default` namespace is:

```text
postgres-service.default.svc.cluster.local
```

Pattern: `<service>.<namespace>.svc.cluster.local`.

This traffic stays on the cluster network. From your laptop you reach the app with `kubectl port-forward`. You do not open the database to your home network.

Day 2 ran PostgreSQL as a Deployment with one replica so the Service idea was easy to see. A Deployment is a weak place to run a database. Part B replaces it with a StatefulSet.

---

# Part A — Read secrets from files

Work in `kubernetes101/day3-part1`.

The app code reads files. `SECRET_DIR` defaults to `/etc/postgres-secret`. `CONFIG_DIR` defaults to `/etc/app-config`. `connect()` in `app/app.py` reads `DB_URL` on every new database connection. Config files are read again on each page request.

Kubernetes can refresh a mounted Secret or ConfigMap in a running pod. It cannot change environment variables in a running container.

## A1. Fix the app manifest before you apply it

Open `day3-part1/app-depl.yaml`.

1. The volume is named `postgres-secret`. The volume mount must use that same name. Change `postgres-secretcd` to `postgres-secret`.
2. `image: day3` means `day3:latest`. Kind will try to pull that from a registry. Set the image to the tag you build, and keep it on the node:

```yaml
image: day3:1.0
imagePullPolicy: IfNotPresent
```

The ConfigMap `app-config` in the same file is plain configuration: title, environment, and the lab text. The Secret stays in `database/postgres-secret.yaml`. The password in that file is `RotatedDb2026`. It is lab-only. Do not treat a Secret manifest in git as a real credential store.

## A2. Create the day3 cluster and load the image

```bash
cd kubernetes101/day3-part1

kind create cluster --name day3 --config kind-config.yaml
kubectl config use-context kind-day3

docker build -t day3:1.0 app
kind load docker-image day3:1.0 --name day3
```

`kind load` copies the local image onto the Kind nodes. The cluster cannot see images that exist only in your Docker daemon.

## A3. Deploy the database, then the app

Apply the volume first, then the Secret, then PostgreSQL, then the app:

```bash
kubectl apply -f database/pvc.yaml
kubectl apply -f database/postgres-secret.yaml
kubectl apply -f database/postgres-dep.yaml
kubectl apply -f app-depl.yaml

kubectl rollout status deployment/postgres
kubectl rollout status deployment/2tierapp
```

`POSTGRES_PASSWORD_FILE`, `POSTGRES_USER_FILE`, and `POSTGRES_DB_FILE` point the Postgres image at files under `/etc/postgres-secret`. The Postgres image reads those files when it initializes an empty data directory. A later file change does not change the password of a database that already exists.

## A4. Prove the values are files, not env vars

```bash
kubectl get pods
kubectl exec deployment/2tierapp -- sh -c 'env | grep -E "DATABASE_URL|DB_URL|POSTGRES" || true'
kubectl exec deployment/2tierapp -- ls -l /etc/postgres-secret /etc/app-config
kubectl exec deployment/2tierapp -- cat /etc/postgres-secret/DB_URL
kubectl exec deployment/2tierapp -- cat /etc/app-config/APP_TITLE
```

`DB_URL` is absent from the environment. It is the file `/etc/postgres-secret/DB_URL`. The title is `/etc/app-config/APP_TITLE`.

Open the app:

```bash
kubectl port-forward service/app-service 8080:8080
```

Visit <http://localhost:8080>. Leave this terminal running, or use another terminal for the next commands.

## A5. Change the password without replacing the app pods

Note the app pod names and start times:

```bash
kubectl get pods -l app=app -o wide
```

Pick a new lab password and change it inside PostgreSQL. This command runs in the database pod, not on your laptop:

```bash
NEW_PASSWORD='NewAdmin5678'

kubectl exec deployment/postgres -- \
  psql -U postgres -d postgres -v ON_ERROR_STOP=1 \
  -c "ALTER ROLE postgres WITH PASSWORD '${NEW_PASSWORD}';"
```

Update the Secret. Both fields must change. The database checks `POSTGRES_PASSWORD` only on first init. The app connects with `DB_URL`.

```bash
kubectl patch secret postgres-secret --type merge -p \
  "{\"stringData\":{\"POSTGRES_PASSWORD\":\"${NEW_PASSWORD}\",\"DB_URL\":\"postgresql://postgres:${NEW_PASSWORD}@postgres-service.default.svc.cluster.local:5432/postgres\"}}"
```

The kubelet refreshes mounted Secret files on its sync interval, often within about a minute. Watch the file from a pod you did not delete:

```bash
kubectl exec deployment/2tierapp -- cat /etc/postgres-secret/DB_URL
```

Repeat until the new password is in the file. Then:

```bash
kubectl get pods -l app=app
curl -fsS http://localhost:8080/healthz
```

The pod names and start times stay the same. `/healthz` returns `{"status":"ok"}` after the file catches up. There is a short failure window between `ALTER ROLE` and the file refresh. During that window the app still has the old password and `/healthz` returns 503.

Also put the new password into `database/postgres-secret.yaml` before the next `kubectl apply`, or that file will write the old password back.

What this does **not** do:

- Environment variables in an already running container stay at the old value. That is the day 2 behavior.
- A process that reads the password once at startup keeps the old password until it reads the file again. This app reads it inside `connect()`, so the next request uses the new file.
- An open connection pool would keep using the old password until those connections are replaced. Refreshing the file and refreshing the connection are two separate steps.

`kubectl patch` is fine for this lab. In a real cluster, change the source of the secret (Vault or a cloud secret manager) and roll the app through its normal release path. Do not hand-edit live production objects as the way you manage credentials.

## A6. Switch clusters on purpose

If the day 2 cluster is still around, you now have two contexts. The star in `get-contexts` is the one `kubectl` will change.

```bash
kubectl config get-contexts
kubectl config current-context

kubectl config use-context kind-day2
kubectl get pods

kubectl config use-context kind-day3
kubectl get pods
```

A deploy or delete goes to the current context. Check it before you apply. A shell prompt that prints the current context is worth setting up so the cluster name is visible in the terminal.

Stop here if you only wanted the file-mount lab. Part B uses a new cluster and a new directory. Leave the `day3` cluster up if you want both sides available.

---

# Part B — StatefulSet, Helm, Vault, and ESO

Work in `kubernetes101/day3-part2`.

Three things change from Part A:

1. PostgreSQL becomes a StatefulSet with a headless Service. You do not write a PersistentVolumeClaim yourself.
2. You do not `kubectl apply` a Secret manifest. Vault holds the password. External Secrets Operator creates `postgres-secret`.
3. The app manifest is the same file-mount idea, plus an init container that waits until PostgreSQL answers.

## B1. Read the StatefulSet before you install anything

Open `database/postgres-statefulset.yaml`.

| Piece | What it does |
| --- | --- |
| `clusterIP: None` | Headless Service. No virtual IP. DNS answers with the pod IPs. |
| `serviceName: postgres-service` | Gives each pod a stable DNS name. |
| `replicas` | Set this to `1` before the first apply. |
| `volumeClaimTemplates` | StatefulSet creates one PVC per pod. |
| Secret volume | Mounted at `/etc/postgres-secret`, same idea as Part A. |

Change `replicas: 2` to `replicas: 1` for the first deploy. One writer is the database you can reason about. You scale to 2 later to see what a StatefulSet does and what it does not do.

Why this object exists:

- A Deployment pod name ends in a random suffix. Kill it and the new pod has a new name. A database needs a stable identity: `postgres-0`.
- The data volume has to follow that identity. `postgres-0` must come back on `postgres-data-postgres-0`. A Deployment does not create one PVC per pod.
- The volume attaches to a node. The replacement pod has to land on a node that can mount that same volume. The StatefulSet tracks that relationship.
- Pods start in order. `postgres-0` becomes Ready before `postgres-1` is created. A Deployment starts every replica at once.

DNS names with a headless Service look like this:

```text
postgres-0.postgres-service.default.svc.cluster.local
postgres-1.postgres-service.default.svc.cluster.local
```

A normal ClusterIP Service hides the pods behind one address. A database client that must reach a specific pod, or that must discover every pod, uses the headless name.

A StatefulSet does not copy data from pod 0 to pod 1, take backups, or fail over a writer. Those jobs belong to an operator. CloudNativePG (CNPG) is the usual PostgreSQL operator: it runs the database as a StatefulSet and adds replication, backup, and failover. This lab stops at the StatefulSet.

In `app-depl.yaml`, set the same image fields you used in Part A:

```yaml
image: day3-part2:1.0
imagePullPolicy: IfNotPresent
```

That line is the application container, not the `wait-for-postgres` init container.

## B2. The path the password takes

```text
Vault KV  secret/day3-part2/postgres
  -> SecretStore "vault"  (ESO knows how to log in)
    -> ExternalSecret "postgres"  (which keys to copy)
      -> Kubernetes Secret "postgres-secret"  (ESO creates this)
        -> files in postgres-0 and the app pods
          -> app reads DB_URL again on the next connection
```

ESO does not inject credentials into a running process. It writes a normal Kubernetes Secret. The pod spec still mounts that Secret. Putting the password in Vault means the git repo does not contain `postgres-secret.yaml`.

A Vault Agent injector is a different tool: a sidecar that pulls from Vault into the app pod. This lab uses ESO.

Vault in this lab runs in development mode: in-memory, auto-unsealed, root token `root`. That is acceptable on a disposable Kind cluster and nowhere else.

## B3. Create the cluster and load the app image

```bash
cd kubernetes101/day3-part2

kind create cluster --name day3-part2 --config kind-config.yaml
kubectl config use-context kind-day3-part2

docker build -t day3-part2:1.0 app
kind load docker-image day3-part2:1.0 --name day3-part2
```

Confirm the context before Helm or `kubectl apply`:

```bash
kubectl config current-context
```

Expected value: `kind-day3-part2`.

## B4. Install Vault and ESO with Helm

Helm is the Kubernetes package manager. A chart is the bundle of Deployments, Services, RBAC, and CRDs for one product. A values file is the configuration you pass in. You do not write those manifests yourself.

Add the two chart repositories once:

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
```

`platform/vault-values.yaml` turns on dev mode and sets the lab root token to `root`.

```bash
export VAULT_ROOT_TOKEN='root'

helm upgrade --install vault hashicorp/vault \
  --namespace vault \
  --create-namespace \
  --values platform/vault-values.yaml \
  --wait

kubectl wait --namespace vault \
  --for=condition=Ready pod/vault-0 \
  --timeout=180s
```

`helm upgrade --install` installs the release, or upgrades it if you run the command again. A second run is how you pick up a values change. See revisions with:

```bash
helm list --all-namespaces
```

Vault UI, in a second terminal:

```bash
kubectl get svc -n vault
kubectl port-forward --namespace vault service/vault-ui 8200:8200
```

If `vault-ui` is missing, port-forward the Service that publishes port 8200. Open <http://localhost:8200>, choose **Token**, and sign in with `root`.

Install ESO in its own namespace:

```bash
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --values platform/external-secrets-values.yaml \
  --wait

kubectl get pods -n external-secrets
```

You should see operator pods in `external-secrets` and `vault-0` in `vault`. The `default` namespace does not have `postgres-secret` yet.

## B5. Write the database credentials into Vault

Run the Vault CLI inside `vault-0`. Use an alphanumeric password. ESO embeds it in a PostgreSQL URL.

```bash
kubectl exec -n vault vault-0 -- \
  env VAULT_TOKEN="$VAULT_ROOT_TOKEN" \
  vault kv put secret/day3-part2/postgres \
  username=postgres \
  password=VaultDb2026 \
  database=postgres
```

Check that the path exists. This command prints metadata, not the password:

```bash
kubectl exec -n vault vault-0 -- \
  env VAULT_TOKEN="$VAULT_ROOT_TOKEN" \
  vault kv metadata get secret/day3-part2/postgres
```

In the UI: **Secrets** → `secret/` → `day3-part2/postgres`. The keys are `username`, `password`, and `database`.

The dev server stores this in memory. A Vault pod restart wipes it. Put the keys back with the same `vault kv put` if that happens.

## B6. Point ESO at Vault

`external-secrets/external-secret.yaml` contains a `test` remote ref left over from the live demo (`key: data/name/test`). Delete that whole list item before you apply. ESO will not become Ready while any remote key is missing, and `postgres-secret` will not appear.

Keep the three refs for `day3-part2/postgres`: `username`, `password`, and `database`. The template builds `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, and `DB_URL`. `refreshInterval: 15s` is how often ESO re-reads Vault.

The SecretStore talks to Vault at:

```text
http://vault.vault.svc.cluster.local:8200
```

That name only works because Vault is in this same cluster. A company Vault usually has its own address. Authentication in this lab is a token stored in a Kubernetes Secret named `vault-token`. Create that Secret from the shell so the token is not committed in a YAML file:

```bash
kubectl create secret generic vault-token \
  --namespace default \
  --from-literal=token="$VAULT_ROOT_TOKEN" \
  --dry-run=client \
  --output=yaml |
kubectl apply -f -

kubectl apply -f external-secrets/secret-store.yaml
kubectl apply -f external-secrets/external-secret.yaml

kubectl wait --for=condition=Ready secretstore/vault --timeout=120s
kubectl wait --for=condition=Ready externalsecret/postgres --timeout=120s
```

You did not apply a `postgres-secret` manifest. List the keys ESO wrote:

```bash
kubectl get secret postgres-secret \
  -o go-template='{{ range $key, $_ := .data }}{{ printf "%s\n" $key }}{{ end }}'
```

Expected keys:

```text
DB_URL
POSTGRES_DB
POSTGRES_PASSWORD
POSTGRES_USER
```

If `externalsecret/postgres` stays Not Ready:

```bash
kubectl describe externalsecret postgres
kubectl describe secretstore vault
kubectl get pods -n vault
kubectl config current-context
```

Typical causes from the class: wrong context, Vault pod not Ready, credentials never written (or wiped by a Vault restart), `vault-token` missing, or the demo `test` key still in the ExternalSecret.

`external-secrets/service-account.yaml`, `platform/external-secrets-policy.hcl`, and `platform/vault-token-reviewer.yaml` belong to Vault's Kubernetes auth method. This lab uses the root token instead. Leave those files unused.

## B7. Deploy PostgreSQL and the app

The Secret has to exist first. The StatefulSet mounts it during container start.

```bash
kubectl apply -f database/postgres-statefulset.yaml
kubectl rollout status statefulset/postgres --timeout=180s

kubectl apply -f app-depl.yaml
kubectl rollout status deployment/2tierapp --timeout=180s
```

```bash
kubectl get pods,svc,pvc
kubectl get secretstore,externalsecret,secret
```

You should see:

- Pod `postgres-0` (a stable name, not a random Deployment suffix).
- PVC `postgres-data-postgres-0`.
- Service `postgres-service` with `CLUSTER-IP` of `None`.
- App pods Ready, Secret `postgres-secret` present, and no Secret YAML applied for it.

Open the app:

```bash
kubectl port-forward service/app-service 8080:8080
```

Visit <http://localhost:8080>.

Confirm the app still reads files:

```bash
kubectl exec deployment/2tierapp -- sh -c 'env | grep DB_URL || true'
kubectl exec deployment/2tierapp -- cat /etc/postgres-secret/DB_URL
```

## B8. See the stable identity

```bash
kubectl delete pod postgres-0
kubectl get pods,pvc -w
```

The new pod is `postgres-0` again, and it mounts `postgres-data-postgres-0` again. The game score survives because the volume survived.

Scale to a second pod:

```bash
kubectl scale statefulset postgres --replicas=2
kubectl get pods,pvc
```

`postgres-1` starts after `postgres-0` is Ready. Its PVC is `postgres-data-postgres-1`, a new empty volume. Nothing copied the data from pod 0. That is the limit of a StatefulSet, and the reason a real PostgreSQL install on Kubernetes uses an operator such as CNPG.

Scale back to one writer when you are done looking:

```bash
kubectl scale statefulset postgres --replicas=1
```

The PVC for pod 1 remains until you delete it. The StatefulSet does not throw away a data volume just because the replica count dropped.

## B9. Rotate the password from Vault

Keep one replica for this check. Record the app pods so you can see they were not replaced:

```bash
kubectl get pods -l app=app
```

Change the password inside PostgreSQL, then change Vault. ESO copies Vault into `postgres-secret`. The mounted file updates. The app reads that file on the next connection.

```bash
NEW_PASSWORD='NewVaultDb2026'

kubectl exec postgres-0 -- \
  psql -U postgres -d postgres -v ON_ERROR_STOP=1 \
  -c "ALTER ROLE postgres WITH PASSWORD '${NEW_PASSWORD}';"

kubectl exec -n vault vault-0 -- \
  env VAULT_TOKEN="$VAULT_ROOT_TOKEN" \
  vault kv put secret/day3-part2/postgres \
  username=postgres \
  password="${NEW_PASSWORD}" \
  database=postgres
```

Wait until the file inside an existing app pod shows the new password, then hit the app:

```bash
kubectl exec deployment/2tierapp -- cat /etc/postgres-secret/DB_URL
curl -fsS http://localhost:8080/healthz
kubectl get pods -l app=app
```

Pod names stay the same when the file refresh is what picked up the password. `/healthz` may return 503 for a short time. That is the gap between the database password and the file.

`rotate-db-creds-job.yaml` is the same idea as a suspended CronJob: generate a password, write Vault, `ALTER ROLE`, wait until the mounted Secret matches. Apply it only after the manual rotation makes sense. The commands to run it once are in `readme.md`.

## B10. Clean up

```bash
kubectl config current-context

kind delete cluster --name day3-part2
kind delete cluster --name day3
```

Delete the day 2 cluster only if you are finished with that lab too:

```bash
kind delete cluster --name day2
```

---

## Questions that came up in class

**If three pods die at once, where is the mounted secret?**  
The Secret object is in the cluster (`etcd`), not on the pod disk. Each new pod mounts `postgres-secret` again at `/etc/postgres-secret`. The pod is replaceable. The Secret is the shared source.

**Where do real credentials live?**  
In Vault, AWS Secrets Manager, GCP Secret Manager, or a similar store. ESO (or another operator) creates the Kubernetes Secret from that store. You still choose env vars or a volume when you connect the Secret to the container. ESO does not skip that choice.

**Does a volume mount mean the live app sees a new password with no restart?**  
The file can change with no restart. This Flask app reads `DB_URL` on every `connect()`, so the next request uses the new password. An app that keeps a connection open from startup keeps the old password until it opens a new connection. Environment variables do not update in place at all.

**Why was the database a Deployment yesterday?**  
So the Service and DNS story was visible with one pod. Deployments give random names, shared rollout behavior, and no per-pod volume identity. Use a StatefulSet for the database, and an operator when you also need replication and backups.

**Why a headless Service?**  
`clusterIP: None` makes DNS return pod identities (`postgres-0.postgres-service...`) instead of one shared virtual IP. Clients that must find a specific database pod use those names.

**What was failing when ESO never created the Secret?**  
The ExternalSecret was not Ready, usually because it could not read Vault: auth token, wrong context, empty dev Vault after a restart, or a remote key that does not exist. `kubectl describe externalsecret postgres` is the first command.

## Checklist

- [ ] App pods reach PostgreSQL through `postgres-service`, not a pod IP.
- [ ] Part A: `DB_URL` is a file under `/etc/postgres-secret`, not an environment variable.
- [ ] Part A: after `ALTER ROLE` and a Secret patch, the file changes and the app pod is the same pod.
- [ ] `kubectl config current-context` before every apply.
- [ ] Part B: Vault and ESO installed with Helm.
- [ ] Part B: `postgres-secret` exists and you never applied a Secret manifest for it.
- [ ] `postgres-0` keeps its name and its PVC after a delete.
- [ ] A second replica gets its own empty PVC. The StatefulSet does not replicate data.
