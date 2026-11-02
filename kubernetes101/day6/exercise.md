# Kubernetes 101 — Day 6 Hands-on (First EKS Cluster + 3-Tier App)

**Bootcamp:** July DevOps  
**Class:** Nov 1, 2026  
**Path:** `kubernetes101/day6/`  
**App:** Frontend + Backend + RDS Postgres (demo 3-tier on EKS)

Till Day 5 you used **Kind**. From Day 6 you use **Amazon EKS** (managed control plane). This lab is **console-first / demo-grade** — Terraform, Ingress, TLS, and Argo CD come next.

---

## Goals

By the end you should be able to:

1. Create an EKS cluster from the console (custom config, not Auto Mode).
2. Explain **public / private / public+private** API endpoint access.
3. Install required add-ons: **VPC CNI**, **CoreDNS**, **kube-proxy**.
4. Create a **managed node group**, authenticate with `kubectl`, and fix **EKS Access** for your CLI IAM user.
5. Build/push images to **ECR**, create **RDS**, deploy the 3-tier app from `k8s/`.
6. Demo **NodePort** and **LoadBalancer** Services (and know why Ingress is preferred later).
7. Optionally install **EBS CSI** and run a StatefulSet that needs a volume (`running-db/`).
8. **Delete** the node group and cluster so you are not billed overnight.

---

## Repo layout

```text
kubernetes101/day6/
├── exercise.md          ← this file
├── readme.md            ← topic roadmap
├── app/
│   ├── docker-compose.yml
│   ├── backend/         ← Flask API + migrate.sh
│   └── frontend/        ← React / nginx
├── k8s/
│   ├── 00-namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── backend.yaml
│   └── frontend.yaml
└── running-db/
    └── postgres.yaml    ← StatefulSet + PVC (needs EBS CSI)
```

---

## Recap — what we already covered (Days 1–5)

| Area | Topics |
|------|--------|
| Core | Architecture, Freelens, Pod / Deployment / Service / ConfigMap / Secret / Endpoints / Namespace |
| Workloads | StatefulSet, storage, probes (startup / readiness / liveness), requests & limits |
| Scaling | HPA, VPA, metrics-server |
| Secrets | Vault + External Secrets Operator |
| Packaging | Helm (basics) |

---

## Concepts (read before clicking Create)

### Why managed EKS?

You *can* install Kubernetes yourself on EC2 (or at home on VMs). Control plane ops are hard. Cloud providers give a **managed control plane**. You still choose networking, nodes, IAM, and add-ons.

### Cluster endpoint access

| Mode | Who can call the API | Typical use |
|------|----------------------|-------------|
| **Public** | Internet (optionally CIDR-restricted) | Lab / VPN egress IPs only |
| **Private** | Only from inside the VPC | Highest lock-down; use bastion/SSM jump box for `kubectl` |
| **Public and private** | Nodes stay private; API can be reached from allowed public CIDRs | Common in companies (VPN IP ranges) |

For this first demo, public (or public+private with public subnets) is OK so you can run `kubectl` from your laptop.

### VPC CNI (why it matters on EKS too)

Same idea as Kind’s CNI: pods need IPs and node/pod networking. On EKS, **Amazon VPC CNI** assigns **VPC IPs** to pods from your subnet CIDRs so Kubernetes networking aligns with AWS networking. Pods should live on **private** networking in real setups.

### Add-ons you must enable at create (minimum)

| Add-on | Why |
|--------|-----|
| **VPC CNI** | Pod IPs from the VPC |
| **CoreDNS** | In-cluster DNS (`backend.3-tier-app-eks.svc…`) |
| **kube-proxy** | Service / iptables (or equivalent) networking |

Optional later: **EBS CSI** (StatefulSets with EBS), **EFS CSI**, metrics-server (often appears via add-ons), etc.

### Node options (decision making)

| Option | You see EC2? | Patching | EBS volumes | Speed / cost notes |
|--------|--------------|----------|-------------|--------------------|
| **Managed node group** | Yes (via ASG) | AWS helps with EKS-optimized AMI / updates | Yes | Pods schedule in seconds; good default |
| **Fargate** | No | AWS | **EFS only** (no EBS) | ~60s cold start; costly; needs **private** subnets |
| **Self-managed nodes** | Yes (you own ASG/AMI) | **You** patch (~7–15 days) | Yes | Banks/compliance (Qualys, Trend, custom AMI) |

**Banking/compliance example from class:** self-managed when policy requires agents on every VM. **Fargate:** security scanners often do not “see” EC2, so they cannot demand those agents — but you pay more and lose EBS.

### IAM: two planes

1. **AWS IAM** — cluster role, node role (ECR pull, CNI, etc.).
2. **EKS Access / Kubernetes RBAC** — who may run `kubectl`. Console creator (root/IAM) gets admin if you check “cluster admin”; your **CLI IAM user** must be added under **Access** or `kubectl` fails with Unauthorized.

You can scope access **cluster-wide** or **namespace**. Later: Argo CD for developers; admins keep cluster access.

### Service types in this lab

| Type | Demo purpose | Production? |
|------|--------------|-------------|
| **ClusterIP** | Default private in-cluster | Yes (internal) |
| **NodePort** | Hit `http://<node-public-ip>:<30000–32767>` | Avoid (opens a port on every node) |
| **LoadBalancer** | EKS creates a classic/NLB/CLB-style AWS LB from the Service | Rare for apps; teams use **Ingress + ALB controller** instead |

Frontend is what users hit; backend can stay ClusterIP.

### Image platform + pull policy

- Build on Apple Silicon Mac → use `--platform linux/amd64` for EKS Linux nodes.
- Same tag (`:backend`) after rebuild → set `imagePullPolicy: Always` or change tags, or nodes keep the old image.

### Migrations

`migrate.sh` (Flask-Migrate) creates/updates schema. Demo runs it in the backend container command. **Production:** run migrations as a **Job once** before scaling many backend pods (100 pods all migrating = risk).

---

## Prerequisites

- [ ] AWS account with permission for EKS, EC2, ECR, RDS, IAM
- [ ] AWS CLI configured (`aws sts get-caller-identity`)
- [ ] `kubectl` installed
- [ ] Docker running
- [ ] Clone: `https://github.com/akhileshmishrabiz/july-devops`

```bash
cd july-devops/kubernetes101/day6
```

Replace placeholders:

| Placeholder | Meaning |
|-------------|---------|
| `<ACCOUNT_ID>` | Your AWS account ID |
| `<REGION>` | e.g. `ap-south-1` |
| `<CLUSTER_NAME>` | e.g. `demo-cluster` |
| `<RDS_ENDPOINT>` | RDS hostname after create |

---

## Part 1 — Create the EKS cluster (console)

1. EKS → **Create cluster** → **Custom configuration** (skip Auto Mode for now — extra cost / magic).
2. Name: `<CLUSTER_NAME>` (e.g. `demo-cluster`).
3. Kubernetes version: a **stable** recent version (class used a non-bleeding version).
4. Cluster IAM role: use/create **Amazon EKS Cluster role** (default policies).
5. Enable **cluster administrator access** for the creator user.
6. Authentication mode: **EKS API** (preferred over legacy ConfigMap-only).
7. Networking:
   - VPC: default VPC **or** a custom VPC with public (+ private if you have them).
   - For the **first demo**, public subnets are enough so laptop `kubectl` works.
   - Endpoint: **Public** (demo) or **Public and private** if you have private subnets for workers later.
8. Control plane logging: leave off for lab.
9. Add-ons: **VPC CNI**, **CoreDNS**, **kube-proxy** (required). Skip EBS CSI until Part 7.
10. Create — wait **~10–15 minutes**. This is **control plane only** — no worker nodes yet.

**Security group note (lab only):** opening wide inbound helps demos; tighten later. Delete the cluster when done.

**Deliverable:** Cluster status **Active** in console.

---

## Part 2 — Wire kubectl + EKS Access

```bash
aws eks update-kubeconfig --region <REGION> --name <CLUSTER_NAME>
kubectl config get-contexts
kubectl config rename-context <long-arn-context> demo
kubectl config use-context demo
kubectl get nodes
```

Expect **no nodes** yet. `kubectl get pods -A` may show add-on pods **Pending** until nodes exist.

If you get **Unauthorized**:

1. Console → EKS cluster → **Access**
2. Create access entry for your **CLI IAM principal** (the user from `aws sts get-caller-identity`)
3. Attach **AmazonEKSClusterAdminPolicy** (lab) at **cluster** scope
4. Wait a few seconds; retry `kubectl get ns`

You will **not** see `kube-apiserver` / etcd pods — those are managed by AWS.

**Deliverable:** `kubectl get ns` works with your CLI user.

---

## Part 3 — Managed node group

1. Cluster → **Compute** → **Add node group**
2. Create/select **node IAM role** with the usual managed policies (WorkerNode, CNI, ECR pull — follow console defaults).
3. AMI: Amazon Linux 2023 (EKS-optimized — AWS picks the right image).
4. Capacity: On-Demand (Spot is optional later).
5. Instance type: small (e.g. `t3.medium`).
6. Scaling: desired **2**, min **1**, max **3**.
7. Subnets: same VPC as the cluster (public is OK for this NodePort demo).
8. Optional SSH: off for managed nodes unless you need it.
9. Create — wait until nodes show in console **and**:

```bash
kubectl get nodes
kubectl get pods -A
```

You should see **aws-node** (VPC CNI DaemonSet), **kube-proxy** DaemonSet, **coredns** Deployment, often metrics-server, etc.

### If nodes never join the cluster

Research: *“EKS node group nodes not visible”*. Common causes: subnet tags, CNI missing, IAM, user data. For console-created clusters, AWS usually tags subnets; Terraform labs must set shared/cluster tags explicitly.

### Fargate note (next class detail)

Fargate profiles need **private** subnets. A public-only cluster cannot demo Fargate cleanly — revisit when private subnets exist.

**Deliverable:** `kubectl get nodes` shows Ready workers.

---

## Part 4 — ECR images (linux/amd64)

1. ECR → Create repository `eks-3tierapp` (one repo, two tags).
2. Build and push from `day6/app`:

```bash
export ACCOUNT_ID=<ACCOUNT_ID>
export REGION=<REGION>
export REPO=${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/eks-3tierapp

aws ecr get-login-password --region ${REGION} \
  | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

cd app/backend
docker build --platform linux/amd64 -t ${REPO}:backend .
cd ../frontend
docker build --platform linux/amd64 -t ${REPO}:frontend .

docker push ${REPO}:backend
docker push ${REPO}:frontend
```

Update image lines in `k8s/backend.yaml` and `k8s/frontend.yaml` if your account/region differs from the sample.

**Deliverable:** Both tags visible in ECR.

---

## Part 5 — RDS Postgres (same VPC, demo-only)

1. RDS → Create → **Easy create** → PostgreSQL → Free tier / Dev if available.
2. Master user `postgres`, password e.g. `Admin1234` (lab only).
3. Place in the **same VPC** as EKS so pods can reach it.
4. Open security group **5432** from the node/pod path (lab may temporarily open more — **delete this DB soon**; Easy create can be overly open).
5. Copy endpoint. Default DB name is often `postgres`.

Edit before apply:

- `k8s/configmap.yaml` → `DB_HOST`
- `k8s/secret.yaml` → `DATABASE_URL` and password fields

**Deliverable:** Endpoint reachable conceptually from the VPC; manifests updated.

---

## Part 6 — Deploy the 3-tier app

```bash
cd kubernetes101/day6
# edit configmap + secret with YOUR RDS values and ECR images
kubectl apply -f k8s/
kubectl -n 3-tier-app-eks get all
kubectl -n 3-tier-app-eks get pods -w
```

What the manifests do:

| Resource | Behavior |
|----------|----------|
| Backend initContainer | Wait until Postgres accepts connections |
| Backend command | `./migrate.sh` then gunicorn `:8000` |
| Frontend initContainer | Wait until `${BACKEND_URL}/health` |
| Probes | `/health` readiness/startup (and liveness as defined) |
| Services | ClusterIP by default |

Debug:

```bash
kubectl -n 3-tier-app-eks describe pod <pod>
kubectl -n 3-tier-app-eks logs <backend-pod> -c wait-for-database
kubectl -n 3-tier-app-eks logs <backend-pod> -c backend
kubectl -n 3-tier-app-eks port-forward svc/frontend 8080:80
# open http://localhost:8080
```

**ImagePullBackOff:** wrong tag, not pushed, platform mismatch, or `IfNotPresent` with stale same tag → rebuild with `linux/amd64`, push, `imagePullPolicy: Always`, delete pods.

**Deliverable:** Backend + frontend Ready; app via port-forward.

---

## Part 7 — NodePort demo (then undo)

1. In `k8s/frontend.yaml`, comment ClusterIP Service; uncomment **NodePort** (`nodePort: 30080` example — must be **30000–32767**).
2. Optionally leave backend as ClusterIP (recommended).
3. `kubectl apply -f k8s/frontend.yaml`
4. Open node security group for that NodePort (or lab: broad inbound briefly).
5. Browse `http://<any-node-public-ip>:30080` — same app via **either** node.

Why not production: every node exposes the port; no path/host routing or clean TLS story.

Restore ClusterIP when done.

**Deliverable:** Screenshot or note of app on NodePort; then revert.

---

## Part 8 — LoadBalancer Service demo (then undo)

1. Uncomment **LoadBalancer** Service on frontend; apply.
2. Wait for `EXTERNAL-IP` / hostname:

```bash
kubectl -n 3-tier-app-eks get svc frontend -o wide
```

3. Open the hostname in a browser (may take a minute; check SG / target registration if stuck).
4. In EC2 → Load balancers, see the AWS LB Kubernetes created via control-plane IAM.

Class note: **almost nobody ships apps this way long-term** — next topic is **Ingress** (path/host rules, TLS, shared LB).

Revert to ClusterIP afterward.

**Deliverable:** App reachable via LB DNS once; then ClusterIP again.

---

## Part 9 — Optional: EBS CSI + in-cluster Postgres StatefulSet

`running-db/postgres.yaml` needs a volume provisioner.

1. EKS → Add-ons → **Amazon EBS CSI Driver**
2. Associate IAM (IRSA / EBS CSI policy — console or custom role; class previewed **OIDC identity provider** + IRSA — deeper next class)
3. Wait until add-on **Active**
4. Apply:

```bash
kubectl apply -f running-db/
kubectl -n 3-tier-app-eks get pvc,pods
```

Without CSI, PVC stays Pending (`waiting for a volume to be created by external provisioner…`).

**Deliverable (optional):** PVC Bound and Postgres pod Running.

---

## Part 10 — Cleanup (do this)

EKS is expensive.

1. Delete workloads: `kubectl delete -f k8s/` (and `running-db/` if used)
2. Delete **node group** first; wait until gone (~10 min)
3. Delete **EKS cluster**
4. Delete **RDS** demo instance
5. Optional: delete unused ECR images / classic LBs left behind

**Deliverable:** No idle EKS cluster in the account.

---

## Short notes / interview prompts

1. Managed control plane vs self-installed Kubernetes — what do you not see in `kubectl get pods -A` on EKS?
2. Public vs private vs public+private API endpoints — when is each appropriate?
3. Why VPC CNI on EKS?
4. Managed node group vs Fargate vs self-managed — pick one for (a) EBS StatefulSet, (b) compliance agents on every VM, (c) no EC2 visible to scanners.
5. Why add your CLI IAM user under EKS Access after creating the cluster as root?
6. Why `--platform linux/amd64` and `imagePullPolicy: Always` in this lab?
7. Why run DB migrations as a Job in production instead of in every backend replica?
8. NodePort vs LoadBalancer Service vs Ingress — what will we use next and why?

---

## Submission checklist

- [ ] EKS cluster Active with VPC CNI + CoreDNS + kube-proxy
- [ ] Managed node group; `kubectl get nodes` Ready
- [ ] CLI IAM principal has EKS Access (admin for lab)
- [ ] ECR `:backend` and `:frontend` (linux/amd64) pushed
- [ ] RDS in same VPC; ConfigMap/Secret updated
- [ ] `kubectl apply -f k8s/` — pods Ready; port-forward works
- [ ] NodePort and/or LoadBalancer demo tried and reverted
- [ ] Optional: EBS CSI + `running-db` PVC Bound
- [ ] Cluster + node group + RDS deleted (or scheduled delete)
- [ ] Short notes answered

---

## Pre-read for next class

- Instructor Substack / blog series on **EKS with `eksctl`** (parts covering Ingress / IRSA) — follow along if you want CLI-based practice before Ingress week.
- Skim: Kubernetes **Ingress**, AWS Load Balancer Controller, ACM TLS, Route 53.
- IRSA (IAM Roles for Service Accounts) + cluster OIDC provider — previewed when installing EBS CSI.

Next: **Ingress** (object + controller), then Terraform EKS, Argo CD, basic observability — then microservices.

---

## Quick reference

```bash
# kubeconfig
aws eks update-kubeconfig --region <REGION> --name <CLUSTER_NAME>

# deploy app
kubectl apply -f k8s/
kubectl -n 3-tier-app-eks get pods,svc

# logs / forward
kubectl -n 3-tier-app-eks logs deploy/backend -c backend
kubectl -n 3-tier-app-eks port-forward svc/frontend 8080:80
```

Good luck — get the cluster talking to `kubectl`, ship the 3-tier app, then **tear it down**.
