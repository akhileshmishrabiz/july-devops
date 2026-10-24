# PostgreSQL StatefulSet with Vault and External Secrets Operator

This lab runs Vault, External Secrets Operator (ESO), PostgreSQL, and the
Flask app in one Kubernetes cluster.

- PostgreSQL is a `StatefulSet` with a per-pod PVC.
- Vault is the source of truth for database credentials.
- ESO reads Vault through Kubernetes authentication.
- ESO owns the generated `postgres-secret`; there is no handwritten
  Kubernetes Secret manifest.
- PostgreSQL and the app mount `postgres-secret` as a read-only volume.

> The Vault server uses development mode to keep this local Kind lab simple.
> Development mode is in-memory, unsealed, and unsuitable for production.

## Prerequisites

Install Docker, Kind, `kubectl`, and Helm.

## 1. Create the cluster and application image

From `kubernetes101/day3-part2`:

```bash
kind create cluster --name day3-part2 --config kind-config.yaml
kubectl config use-context kind-day3-part2

docker build -t day3-part2:1.0 app
kind load docker-image day3-part2:1.0 --name day3-part2
```

## 2. Install Vault and ESO in the cluster

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
```

Install Vault in the `vault` namespace. The root token below is acceptable
only for this disposable lab:

```bash
export VAULT_ROOT_TOKEN='root'

helm upgrade --install vault hashicorp/vault \
  --namespace vault \
  --create-namespace \
  --values platform/vault-values.yaml \
  --wait

kubectl wait --namespace vault \
  --for=condition=Ready pod/vault-0 \
  --timeout=120s
```

Access the Vault UI from another terminal:

```bash
kubectl port-forward --namespace vault service/vault-ui 8200:8200
```

Open <http://localhost:8200>, select the **Token** authentication method, and
sign in with the lab root token:

```text
root
```

Install ESO and its CRDs in a separate namespace:

```bash
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --values platform/external-secrets-values.yaml \
  --wait
```

## 3. Configure Vault with Vault CLI commands

These commands execute the Vault CLI inside `vault-0`.

Create the database values in Vault. Use an alphanumeric password because
ESO uses it to construct a PostgreSQL URL:

```bash
kubectl exec -n vault vault-0 -- \
  env VAULT_TOKEN="$VAULT_ROOT_TOKEN" \
  vault kv put secret/day3-part2/postgres \
  username=postgres \
  password=VaultDb2026 \
  database=postgres
```

Confirm the path and field names without printing their values:

```bash
kubectl exec -n vault vault-0 -- \
  env VAULT_TOKEN="$VAULT_ROOT_TOKEN" \
  vault kv metadata get secret/day3-part2/postgres
```

## 4. Create the ESO resources

Create the Kubernetes Secret used by ESO to authenticate to Vault. This is
created imperatively and is not stored in a YAML file:

```bash
kubectl create secret generic vault-token \
  --namespace default \
  --from-literal=token="$VAULT_ROOT_TOKEN" \
  --dry-run=client \
  --output=yaml |
kubectl apply -f -

kubectl apply -f external-secrets/secret-store.yaml
kubectl apply -f external-secrets/external-secret.yaml

kubectl wait --for=condition=Ready \
  secretstore/vault \
  --timeout=120s

kubectl wait --for=condition=Ready \
  externalsecret/postgres \
  --timeout=120s
```

The root token is used only to simplify this disposable lab. In production,
create a restricted Vault token or use Vault Kubernetes authentication.

ESO now creates and owns `postgres-secret`. Verify the generated key names
without decoding the values:

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

## 5. Deploy PostgreSQL and the app

```bash
kubectl apply -f database/postgres-statefulset.yaml
kubectl rollout status statefulset/postgres --timeout=120s

kubectl apply -f app-depl.yaml
kubectl rollout status deployment/2tierapp --timeout=120s
kubectl port-forward service/app-service 8080:8080
```

Open <http://localhost:8080>.

The StatefulSet creates a PVC named `postgres-data-postgres-0`. Deleting
`postgres-0` recreates the pod with the same identity and volume:

```bash
kubectl delete pod postgres-0
kubectl get pod,pvc
```

## Verify the Vault-to-pod flow

```bash
kubectl get secretstore,externalsecret
kubectl describe externalsecret postgres
kubectl get statefulset,pod,pvc
```

The complete flow is:

```text
Vault KV v2
  -> SecretStore authenticates with Kubernetes auth
  -> ExternalSecret creates postgres-secret
  -> postgres-0 and app pods mount postgres-secret
  -> containers read credentials from files
```

## Rotate the database password

Changing Vault alone does not change the password already stored inside
PostgreSQL. Change PostgreSQL first, then update Vault:

```bash
export NEW_PASSWORD='VaultDb2027'

kubectl exec postgres-0 -- \
  psql -U postgres -d postgres -v ON_ERROR_STOP=1 \
  -c "ALTER ROLE postgres WITH PASSWORD '${NEW_PASSWORD}';"

kubectl exec -n vault vault-0 -- \
  env VAULT_TOKEN="$VAULT_ROOT_TOKEN" \
  vault kv patch secret/day3-part2/postgres \
  password="$NEW_PASSWORD"
```

ESO checks Vault every 15 seconds. To request an immediate reconciliation:

```bash
kubectl annotate externalsecret postgres \
  force-sync="$(date +%s)" \
  --overwrite
```

Kubernetes then updates the mounted Secret volumes. This can take roughly
one minute. The app rereads `DB_URL` for every database connection, so it
recovers with the new password without an app rollout.

## Cleanup

```bash
kind delete cluster --name day3-part2
```
