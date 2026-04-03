<div align="center">

# ⚓ KubeQuest

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=for-the-badge&logo=traefikproxy&logoColor=white)
![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)

**Automatisation et déploiement d'infrastructure cloud sur AWS**

</div>

---

## 📖 À propos

Ce playbook Ansible automatise le déploiement complet d'un cluster Kubernetes et de ses services :

- Installation de **containerd**, **kubeadm**, **kubelet** et **kubectl** sur tous les nœuds
- Initialisation du **nœud master** (kube1) avec **Calico** comme CNI
- Jonction des **nœuds workers** (kube2, monitoring, ingress) au cluster
- Attribution des **labels** et **taints** sur chaque nœud
- Installation de **Helm** et déploiement des services (**Traefik**, **ArgoCD**)

---

## 🏗️ Architecture

| Hôte | Rôle | Label             | Taint                             | Description |
|------|------|-------------------|-----------------------------------|-------------|
| `kube1` | Master | `role=kube1`      | — (taint control-plane par défaut) | Nœud control plane du cluster |
| `kube2` | Worker | `role=kube2`      | `role=kube2:NoSchedule`           | Nœud worker applicatif + ArgoCD |
| `monitoring` | Worker | `role=monitoring` | `role=monitoring:NoSchedule`      | Nœud dédié au monitoring (Prometheus/Grafana) |
| `ingress` | Worker | `role=ingress`    | `role=ingress:NoSchedule`         | Nœud dédié à l'Ingress Controller (Traefik) |

Les **taints** garantissent que seuls les pods avec les **tolerations** correspondantes peuvent être schedulés sur un nœud donné. Par exemple, seul Traefik (avec sa toleration `role=ingress`) peut tourner sur le nœud ingress.

---

## 📁 Structure des rôles

| Rôle | Cible | Tag | Description |
|------|-------|-----|-------------|
| `Deploy_Containerd` | Tous les nœuds | `setup` | Installe et configure le runtime containerd |
| `Deploy_Kube` | Tous les nœuds | `setup` | Installe kubeadm, kubelet et kubectl |
| `Init_Kube` | Master uniquement | `setup` | Initialise le cluster avec `kubeadm init`, installe Calico, pose les labels et taints |
| `Join_Cluster` | Workers uniquement | `setup` | Joint les workers au cluster via le token du master |
| `Deploy_Traefik` | Master uniquement | `services` | Déploie Traefik via Helm sur le nœud ingress |
| `Deploy_ArgoCD` | Master uniquement | `services` | Déploie ArgoCD via Helm sur le nœud kube2 |

> **Note** : Les rôles de déploiement de services s'exécutent depuis `kube1` (le master) car c'est là que se trouve le kubeconfig et l'API Server. Le `nodeSelector` dans les values Helm détermine sur quel nœud les pods seront placés.

---

## 📦 Inventory

Le fichier `inventory.ini` doit définir les variables `server_role` pour chaque hôte :

```ini
[kube1]
(IP) ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/kubequest-epitech-group-23.pem server_role=kube1 ansible_ssh_common_args='-o StrictHostKeyChecking=no'
[kube2]
(IP) ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/kubequest-epitech-group-23.pem server_role=kube2 ansible_ssh_common_args='-o StrictHostKeyChecking=no'
[monitoring]
(IP) ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/kubequest-epitech-group-23.pem server_role=monitoring ansible_ssh_common_args='-o StrictHostKeyChecking=no'
[ingress]
(IP) ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/kubequest-epitech-group-23.pem server_role=ingress ansible_ssh_common_args='-o StrictHostKeyChecking=no'
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

- name: Deploy Services
  hosts: kube1
  become: true
  tags: services
  environment:
    KUBECONFIG: /etc/kubernetes/admin.conf
  roles:
    - Deploy_Traefik
    - Deploy_ArgoCD
```

---

## 🏷️ Labels et Taints

Le rôle `Init_Kube` attribue automatiquement les labels et taints sur chaque nœud à partir de la variable `server_role` définie dans l'inventory.

**Labels** — permettent de cibler un nœud via `nodeSelector` dans les values Helm :

```yaml
- name: Label all nodes
  ansible.builtin.command:
    cmd: "kubectl label nodes {{ hostvars[item]['ansible_nodename'] }} role={{ hostvars[item]['server_role'] }} --overwrite"
  environment:
    KUBECONFIG: /home/ec2-user/.kube/config
  loop: "{{ groups['all'] }}"
```

**Taints** — empêchent les pods non autorisés de se scheduler sur un nœud :

```yaml
- name: Taint nodes
  ansible.builtin.command:
    cmd: "kubectl taint nodes {{ hostvars[item]['ansible_nodename'] }} role={{ hostvars[item]['server_role'] }}:NoSchedule --overwrite"
  environment:
    KUBECONFIG: /home/ec2-user/.kube/config
  loop: "{{ groups['all'] }}"
  when: hostvars[item]['server_role'] != 'kube1'
```

Vérification :

```bash
kubectl get nodes -L role
kubectl describe node <NODE_NAME> | grep Taints
```

---

## 🚀 Déploiement

### Prérequis

- Ansible installé sur la machine de contrôle
- Collection `kubernetes.core` installée : `ansible-galaxy collection install kubernetes.core`
- Accès SSH configuré vers tous les nœuds
- Fichier `inventory.ini` correctement renseigné

### Makefile

```makefile
setup:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml

deploy:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags services
```

### Commandes

```bash
setup:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml

setup-traefik:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags services

setup-argo:
	ansible-playbook -i ./infra/ansible/inventory.ini ./infra/ansible/playbook.yml --tags argo
```

### Vérifier le cluster après déploiement

Depuis le nœud master (`kube1`) :

```bash
kubectl get nodes -L role
```

Résultat attendu :

```
NAME                                        STATUS   ROLES           VERSION    ROLE
ip-10-1-23-119.eu-west-1.compute.internal   Ready    control-plane   v1.31.14   kube1
ip-10-1-23-169.eu-west-1.compute.internal   Ready    <none>          v1.31.14   kube2
ip-10-1-23-29.eu-west-1.compute.internal    Ready    <none>          v1.31.14   monitoring
ip-10-1-23-52.eu-west-1.compute.internal    Ready    <none>          v1.31.14   ingress
```

---

## 🔄 Ordre d'exécution

```
1. Deploy_Containerd  →  tous les nœuds
2. Deploy_Kube        →  tous les nœuds
3. Init_Kube          →  kube1 (master) — init cluster + Calico + labels + taints
4. Join_Cluster       →  kube2, monitoring, ingress (workers)
6. Deploy_Traefik     →  kube1 → pods sur nœud ingress
7. Deploy_ArgoCD      →  kube1 → pods sur nœud kube2
```

---

## 🌐 Accès aux services

Ajouter dans le fichier hosts local (`/etc/hosts` ou `C:\Windows\System32\drivers\etc\hosts`) :

```
<IP_PUBLIQUE_INGRESS>  traefik.kubequest.local argocd.kubequest.local
```

| Service | URL | Identifiants |
|---------|-----|--------------|
| Dashboard Traefik | `http://traefik.kubequest.local/dashboard/` | — |
| ArgoCD | `http://argocd.kubequest.local` | `admin` / voir sortie Ansible |

---

<div align="center">

**Projet KubeQuest**

</div>