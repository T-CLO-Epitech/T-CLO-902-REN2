<div align="center">

# ⚓ KubeQuest

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)
![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=for-the-badge&logo=traefikproxy&logoColor=white)

**Automatisation et déploiement d'infrastructure cloud sur AWS**

</div>

---

## 📖 À propos

Traefik est l'**Ingress Controller** du cluster KubeQuest.
Il reçoit le trafic via un **load balancer externe**, puis distribue les requêtes vers les services Kubernetes.

Objectifs de cette configuration :

- éviter un point de panne unique
- ne plus lier l'ingress à une seule VM
- permettre à plusieurs pods Traefik de tourner sur des workers différents

---

## 🏗️ Architecture

```text
Internet / DNS
    ↓
Load Balancer externe
    ↓
NodePorts Traefik sur les workers
    ↓
Traefik
    ↓
Services Kubernetes
    ↓
Pods applicatifs
```

| Composant | Détail |
|-----------|--------|
| Réplicas Traefik | `2` |
| Service | `NodePort` |
| Ports externes | `30080` / `30443` |
| Déploiement | Helm chart `traefik/traefik` via Ansible |
| Répartition | anti-affinity sur `kubernetes.io/hostname` |

---

## 📦 Déploiement via Ansible

Le rôle `Deploy_Traefik` applique des values Helm orientées résilience :

```yaml
deployment:
  replicas: 2

affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app.kubernetes.io/name: traefik
            app.kubernetes.io/instance: traefik
        topologyKey: kubernetes.io/hostname

podDisruptionBudget:
  enabled: true
  minAvailable: 1

service:
  enabled: true
  type: NodePort

ports:
  web:
    port: 80
    nodePort: 30080
  websecure:
    port: 443
    nodePort: 30443
```

---

## 🌐 Contrat d'exposition

Le load balancer externe doit pointer vers les trois workers sur :

- `TCP 30080` pour HTTP
- `TCP 30443` pour HTTPS

Exemple de parcours utilisateur :

```text
app.kubequest.local
    ↓
Load Balancer externe
    ↓
worker:30080
    ↓
Traefik
    ↓
Service ClusterIP
    ↓
Pods de l'application
```

---

## 🔍 Vérification

### Vérifier les pods Traefik

```bash
kubectl get pods -n traefik -o wide
```

Attendu :

- `2` pods Traefik
- au moins `2` workers distincts

### Vérifier le service

```bash
kubectl get svc -n traefik
```

Attendu :

```text
NAME      TYPE       CLUSTER-IP     PORT(S)
traefik   NodePort   <cluster-ip>   80:30080/TCP,443:30443/TCP
```

### Tester le routing

```bash
curl -H "Host: traefik.kubequest.local" http://<IP_OU_DNS_LB>/dashboard/
curl -H "Host: app.kubequest.local" http://<IP_OU_DNS_LB>/
```

---

## 🛠️ Commandes utiles

```bash
kubectl logs -n traefik -l app.kubernetes.io/name=traefik -f
kubectl get svc -n traefik
helm list -n traefik
```

---
<div align="center">

**Projet KubeQuest**

</div>
