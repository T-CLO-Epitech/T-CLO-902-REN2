<div align="center">

# ⚓ KubeQuest

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)
![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=for-the-badge&logo=traefikproxy&logoColor=white)
![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)

**Automatisation et déploiement d'infrastructure cloud sur AWS**

</div>

---

## 📋 À propos du projet

KubeQuest déploie un cluster Kubernetes automatisé avec Ansible, un ingress Traefik, un pipeline GitOps ArgoCD et une application Helm déployée avec plusieurs replicas.

La cible d'architecture retenue pour l'évaluation est :

- `1` VM control-plane : `kube1`
- `3` workers généralistes : `kube2`, `monitoring`, `ingress`
- aucun worker dédié à un seul produit
- exposition externe via un **load balancer** pointant vers les **NodePorts Traefik**

---

## 🏗️ Architecture cible

```text
Internet / DNS
    ↓
Load Balancer externe
    ↓
NodePorts Traefik sur les workers
    ↓
Services Kubernetes
    ↓
Pods répartis sur 3 workers
```

Cette organisation permet :

- de ne pas casser si un worker tombe
- de répartir les pods applicatifs sur plusieurs nœuds
- de conserver Kubernetes comme vrai orchestrateur, et non comme simple empilement de VMs spécialisées

---

## 🧩 Composants principaux

- **Ansible** : bootstrap cluster, join des workers, configuration registry
- **Traefik** : ingress controller répliqué, exposé en `NodePort`
- **ArgoCD** : déploiement GitOps des manifests et charts
- **Headlamp** : dashboard Kubernetes
- **Nexus** : registry privé pour les images Docker

---

## 📚 Documentation

- [Documentation Ansible](documentation/ansible.md)
- [Documentation Traefik](documentation/traefik.md)
- [Documentation ArgoCD](documentation/argocd.md)
- [Documentation Headlamp](documentation/headlamp.md)
- [Documentation Nexus](documentation/nexus.md)

---

## 📂 Structure du projet

```text
infra/
├── ansible/
│   ├── inventory.ini
│   ├── playbook.yml
│   └── roles/
├── docker/
└── kube/
```

---
<div align="center">

**Projet KubeQuest**

</div>
