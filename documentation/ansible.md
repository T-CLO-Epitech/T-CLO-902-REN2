<div align="center">

# ⚓ KubeQuest

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)
![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)

**Automatisation et déploiement d'infrastructure cloud sur AWS**

</div>

---

## 📖 À propos

Ce playbook Ansible automatise le déploiement complet d'un cluster Kubernetes en trois étapes :

- Installation de **containerd**, **kubeadm**, **kubelet** et **kubectl** sur tous les nœuds
- Initialisation du **nœud master** (kube1)
- Jonction des **nœuds workers** (kube2, monitoring, ingress) au cluster

---

## 🏗️ Architecture

| Hôte | Rôle | Description |
|------|------|-------------|
| `kube1` | Master | Nœud control plane du cluster |
| `kube2` | Worker | Nœud worker applicatif |
| `monitoring` | Worker | Nœud dédié au monitoring (Prometheus/Grafana) |
| `ingress` | Worker | Nœud dédié à l'Ingress Controller (Nginx) |

---

## 📁 Structure des rôles

| Rôle | Cible | Description |
|------|-------|-------------|
| `Deploy_Containerd` | Tous les nœuds | Installe et configure le runtime containerd |
| `Deploy_Kube` | Tous les nœuds | Installe kubeadm, kubelet et kubectl |
| `Init_Kube` | Master uniquement | Initialise le cluster avec `kubeadm init` |
| `Join_Cluster` | Workers uniquement | Joint les workers au cluster via le token du master |

---

## 🚀 Déploiement

### Prérequis

- Ansible installé sur la machine de contrôle
- Accès SSH configuré vers tous les nœuds
- Fichier `inventory` correctement renseigné

### Lancement du playbook
```bash
ansible-playbook -i inventory playbook.yml
```

### Vérifier le cluster après déploiement

Depuis le nœud master (`kube1`) :
```bash
kubectl get nodes
```

Résultat attendu :
```
NAME         STATUS   ROLES           AGE   VERSION
kube1        Ready    control-plane   XXm   v1.XX.X
kube2        Ready    <none>          XXm   v1.XX.X
monitoring   Ready    <none>          XXm   v1.XX.X
ingress      Ready    <none>          XXm   v1.XX.X
```

---

## 🔄 Ordre d'exécution
```
1. Deploy_Containerd  →  tous les nœuds
2. Deploy_Kube        →  tous les nœuds
3. Init_Kube          →  kube1 (master)
4. Join_Cluster       →  kube2, monitoring, ingress (workers)
```

---

<div align="center">

**Projet KubeQuest**

</div>