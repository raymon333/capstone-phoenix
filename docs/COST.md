# Cost — Phoenix Capstone

## Monthly Estimate (Azure, UAE North, on-demand pricing)

| Item | Spec | Est. $/month |
|---|---|---|
| phoenix-server (control-plane) | Standard_B2als_v2, 2 vCPU / 4GB | ~$33 |
| phoenix-agent-0 (worker) | Standard_B2als_v2, 2 vCPU / 4GB | ~$33 |
| phoenix-agent-1 (worker) | Standard_B2als_v2, 2 vCPU / 4GB | ~$33 |
| 3x Public IP (Static, Standard SKU) | | ~$11 (≈$3.65 each) |
| 3x OS disk (Standard_LRS, ~30GB default) | | ~$5 |
| Storage account (Terraform remote state) | Standard_LRS, negligible usage | <$1 |
| **Total** | | **~$116/month** |

Prices are on-demand pay-as-you-go estimates; actual billing may vary slightly by exact usage and any free-tier/student credits applied.

## How to Cut This in Half

The single biggest lever is **VM sizing** — and this project lived that lesson directly. The cluster originally ran on `Standard_B2ats_v2` (2 vCPU / ~1GB usable RAM), chosen purely for its low listed price. In practice, the control-plane's k3s-server process alone needs 500MB+, and the box spent most of its time swap-thrashing under load (observed: load average 15+, 85% iowait, no swap configured), which manifested as SSH timeouts and multi-hour hangs during cluster bring-up — a false economy, since the "cheap" VM cost more in debugging time than the price difference to a properly-sized one.

Concretely, to roughly halve the bill from here:

- **Reserved Instances / 1-year commitment**: ~35-40% off on-demand pricing for the same VM sizes, viable once the workload is stable and not still being iterated on.
- **Scale control-plane down, keep workers sized for the app**: the control-plane mostly runs k3s system components, not application pods — a smaller SKU there (once confirmed stable) while keeping workers sized for actual app load would save one VM's worth of the "large" tier.
- **Spot VMs for workers** (not control-plane): ~60-80% cheaper, acceptable for stateless worker nodes if the app tolerates occasional node eviction (backend/frontend already do, via PodDisruptionBudgets and multi-replica spread) — riskier for a graded live-demo environment, so not used here, but a real production lever.