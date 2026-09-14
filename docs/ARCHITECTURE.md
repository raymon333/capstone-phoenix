# Architecture — Phoenix Capstone

## Node Topology

3 Azure VMs (Standard_B2als_v2, 2 vCPU / 4GB RAM each) in UAE North, in a single VNet/subnet (10.10.1.0/24):

| Node | Role | Private IP |
|---|---|---|
| phoenix-server | k3s control-plane | 10.10.1.4 |
| phoenix-agent-0 | k3s worker | 10.10.1.5 |
| phoenix-agent-1 | k3s worker | 10.10.1.6 |

All three run k3s v1.36.4. The control-plane also schedules workloads (no dedicated master-only taint), since the spec only requires 2+ worker nodes, not a fully isolated control plane.

## Network Security — Two Independent Firewall Layers

Two firewalls have to independently agree before traffic flows, which was the source of a real bug during this build (see Runbook, "Known Issues"):

- **NSG (Azure, cloud-level)**: only 22 (from admin IP), 80, 443 open to the internet. Port 6443 (k3s API) and node-to-node ports are never exposed publicly — intra-VNet traffic is allowed by Azure's default same-VNet rule.
- **UFW (host-level, via Ansible)**: 22/80/443 open to all; 6443 (k3s API), 8472/udp (Flannel VXLAN overlay), and 10250 (kubelet API) are opened but scoped to the private subnet only (`10.10.1.0/24`), never to the internet.

Both layers had to be independently correct — NSG alone was insufficient because UFW, running on the host, silently dropped inter-node cluster traffic even though NSG allowed it.

## Request Flow

1. Browser resolves phoenixproject.site / api.phoenixproject.site via DNS A records to phoenix-server's public IP.
2. Traffic hits Traefik (k3s built-in Ingress) on 80/443, TLS terminated with a cert-manager/Let's Encrypt cert, routed by hostname.
3. Frontend Service load-balances 2 nginx pods (static React build). Backend Service load-balances 2+ Flask/Gunicorn pods (HPA-scaled).
4. Backend connects to Postgres via postgres.taskapp.svc.cluster.local using 5 separate env vars (DATABASE_HOST/PORT/NAME/USER/PASSWORD).
5. Postgres is a single-replica StatefulSet on a PVC (local-path storage class), giving it stable identity/storage independent of node scheduling.

## Core Requirements vs. Single-Server Assumptions

| Requirement | What it fixes |
|---|---|
| Multi-node cluster | App no longer lives on one machine |
| Replicas + topologySpreadConstraints | One instance isn't enough; must survive a node failure |
| Migrations as separate Job | In-entrypoint migrations race at 2+ replicas |
| Postgres StatefulSet + PVC | Pod can reschedule to a different node; storage must stay bound to identity, not a machine |
| Probes | Kubernetes needs explicit health signal, not just "process running" |
| Ingress + cert-manager TLS | TLS can't live on "the one box" with 2+ replicas and no fixed machine |
| NSG + UFW firewall | 3 nodes need explicit inter-node traffic rules while staying closed to the internet |

## Key Design Decisions

- **Separate api.phoenixproject.site subdomain** (not same-origin /api): simpler Ingress routing, independent scaling/TLS per service, frontend's pre-built bundle already targets this subdomain.
- **Frontend runs as root**: stock nginx image has no non-root user defined; runAsNonRoot was tested and confirmed to break container startup (chown failure on /var/cache/nginx). Mitigated via capabilities drop ALL + add back only CHOWN/SETUID/SETGID/NET_BIND_SERVICE, rather than skipping hardening entirely.
- **Backend/Postgres run as explicit numeric UID** (10001, 70): Kubernetes' runAsNonRoot check requires a numeric UID, not a named user, discovered by testing and reading kubelet's actual rejection message.
- **HPA replicas excluded from GitOps diffing** (ignoreDifferences on backend Deployment): HPA and Argo CD both want ownership of spec.replicas; scoping ignoreDifferences to just that field lets both coexist correctly.
- **DATABASE_HOST/PORT/NAME/USER/PASSWORD as 5 separate vars, not one DATABASE_URL**: discovered by reading the actual Flask app source (app/__init__.py) rather than assuming a convention.
