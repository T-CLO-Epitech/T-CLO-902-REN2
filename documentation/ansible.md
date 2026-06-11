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

## 📖 À propos

Le playbook Ansible automatise :

- l'installation de `containerd`, `kubeadm`, `kubelet` et `kubectl`
- l'initialisation du control-plane `kube1`
- la jonction des `3` workers généralistes au cluster
- la configuration du registry privé sur tous les nœuds
- le déploiement de Traefik, ArgoCD et Headlamp

La règle d'architecture suivie est simple : **un seul control-plane et trois workers interchangeables**.

---

## 🏗️ Architecture

| Hôte | Type | Label `workload` | Taint |
|------|------|------------------|-------|
| `kube1` | Control-plane | `control-plane` | taint Kubernetes par défaut |
| `kube2` | Worker | `general` | aucun |
| `monitoring` | Worker | `general` | aucun |
| `ingress` | Worker | `general` | aucun |

Les services ne doivent plus dépendre d'un worker dédié. Les pods applicatifs doivent pouvoir tourner sur plusieurs workers.

---

## 📦 Inventory

Le fichier `inventory.ini` conserve la même topologie machine, mais les trois nœuds non master utilisent tous `server_role=worker`.

```ini
[kube1]
(IP) ansible_user=ec2-user server_role=control-plane
[kube2]
(IP) ansible_user=ec2-user server_role=worker
[monitoring]
(IP) ansible_user=ec2-user server_role=worker
[ingress]
(IP) ansible_user=ec2-user server_role=worker
```

---

## 📋 Playbook

```yaml
---
- name: Install containerd, Kubeadm, Kubelet and Kubectl
  hosts: all
  become: true
  tags: setup
  roles:
    - Deploy_Containerd
    - Deploy_Kube

- name: Configure Master Node
  hosts: kube1
  become: true
  tags: setup
  roles:
    - Init_Kube

- name: Join Worker Nodes to Cluster
  hosts: kube2 monitoring ingress
  become: true
  tags: setup
  roles:
    - Join_Cluster
```

Les déploiements Helm continuent d'être exécutés depuis `kube1`, car c'est le nœud qui possède le kubeconfig d'administration.

---

## 🏷️ Labels et taints

Le rôle `Init_Kube` applique :

- `workload=control-plane` sur `kube1`
- `workload=general` sur tous les workers
- suppression des anciens taints applicatifs `role=*`

Exemple de vérification :

```bash
kubectl get nodes -L workload
kubectl describe node <NODE_NAME> | grep Taints
```

Résultat attendu :

```text
NAME                                        STATUS   ROLES           WORKLOAD
ip-10-1-23-119.eu-west-1.compute.internal   Ready    control-plane   control-plane
ip-10-1-23-169.eu-west-1.compute.internal   Ready    <none>          general
ip-10-1-23-29.eu-west-1.compute.internal    Ready    <none>          general
ip-10-1-23-52.eu-west-1.compute.internal    Ready    <none>          general
```

---

## 🚀 Déploiement

### Prérequis

- Ansible installé sur la machine de contrôle
- collection `kubernetes.core` installée
- accès SSH aux quatre VMs
- `inventory.ini` renseigné

### Commandes utiles

```bash
make setup
make setup-services
make setup-argo
make delete
```

---

## ✅ Critères de résilience à vérifier

- `kubectl get nodes -L workload` montre `1` control-plane et `3` workers généralistes
- Traefik tourne sur au moins `2` workers
- l'application Helm tourne sur `2` à `3` workers avec plusieurs replicas
- ArgoCD et Headlamp ne sont plus épinglés à un worker spécifique

---
<div align="center">

**Projet KubeQuest**

</div>
