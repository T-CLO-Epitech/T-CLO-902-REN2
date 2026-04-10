<div align="center">

# ⚓ KubeQuest — Observability (Prometheus / Grafana / Loki)

</div>

## What this repo does (high level)

- Metrics: `kube-prometheus-stack` (Prometheus + Grafana + exporters)
- Logs: `loki-stack` (Loki + Promtail)
- Scheduling: everything is pinned to the `monitoring` node using `nodeSelector` + `tolerations`
- Access: Grafana is exposed via Traefik with an `IngressRoute` on `grafana.kubequest.local`

## Deploy

From `T-CLO-902-REN2/`:

```bash
make setup-observability
```

## Access

Add the ingress public IP to your local hosts file:

```txt
<IP_PUBLIQUE_INGRESS> grafana.kubequest.local
```

Grafana URL: `http://grafana.kubequest.local`

The playbook prints the generated Grafana admin password at the end of the run.

## Verify

```bash
kubectl get ns
kubectl get pods -n monitoring -o wide
kubectl get svc -n monitoring
kubectl get ingressroute -A
```
