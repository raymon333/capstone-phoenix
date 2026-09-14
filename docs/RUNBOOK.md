# Runbook — Phoenix Capstone

## Provision From Zero

```bash
# 1. Bootstrap remote state (one-time, outside main Terraform)
az group create --name rg-phoenix-tfstate --location uaenorth
az storage account create --name <unique-name> --resource-group rg-phoenix-tfstate --sku Standard_LRS --encryption-services blob
az storage container create --name tfstate --account-name <unique-name>

# 2. Infrastructure
cd infra/terraform
terraform init
terraform apply   # creates 1 control-plane + 2 workers

# 3. Cluster bring-up
cd ../ansible
ansible-playbook -i inventory.ini site.yml

# 4. Fetch kubeconfig, tunnel to API (6443 not internet-facing)
ssh -f -N -L 6443:127.0.0.1:6443 azureuser@<server-public-ip>
cp /tmp/k3s.yaml ~/.kube/config

# 5. Bootstrap GitOps (one-time manual apply, everything after this is git-driven)
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f manifests/argocd/application.yaml
```

## Deploy a Change

Edit the relevant file under `manifests/`, commit, push to `main`. Argo CD polls every ~3 minutes and auto-applies (or force with `kubectl -n argocd annotate application taskapp argocd.argoproj.io/refresh=hard --overwrite`). No manual `kubectl apply` in steady state.

## Scale

Backend autoscales automatically via HPA (2–6 replicas, 60% CPU target). To change bounds, edit `manifests/09-backend-hpa.yaml` and push — do not `kubectl edit` directly, GitOps will revert it.

## Rollback

```bash
git revert <bad-commit-sha>
git push origin main
```
Argo CD detects and reverts the live state to match.

## Recovery Scenarios

**Dead worker node:** Pods on the dead node are rescheduled to the remaining node(s) automatically once Kubernetes marks it NotReady (default ~5 min, or immediately on `kubectl drain`). PodDisruptionBudgets (minAvailable:1) ensure at least one replica of backend/frontend stays up throughout.

**Dead backend pod:** Deployment controller replaces it automatically. Readiness probe keeps the Service from routing traffic to it until `/api/health` returns 200.

**Bad migration:** Job has `backoffLimit: 3` and will not affect running replicas (migrations are isolated from app startup). Roll back via `git revert` on the migration Job/image tag, or manually run a down-migration via a one-off Job if the app supports it.
