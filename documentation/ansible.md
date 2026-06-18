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
- l'initialisation du control-plane
- la jonction des `3` workers généralistes au cluster
- la configuration du registry privé sur tous les nœuds
- le déploiement de Traefik, ArgoCD et du Dashboard

La règle d'architecture suivie est simple : **un seul control-plane et trois workers interchangeables**.

---

## 🏗️ Architecture

| Hôte | Type | `server_role` |
|------|------|---------------|
| `node-4` | Control-plane | `control-plane` |
| `node-1` | Worker | `worker` |
| `node-2` | Worker | `worker` |
| `node-3` | Worker | `worker` |

Les services ne doivent plus dépendre d'un worker dédié. Les pods applicatifs doivent pouvoir tourner sur plusieurs workers.

---

## 📂 Structure

```text
infra/ansible/
├── inventory.ini          ← liste des hôtes (sans variables de connexion)
├── group_vars/
│   └── all/
│       ├── vars.yml       ← variables de connexion (commité, non chiffré)
│       └── vault.yml      ← clé SSH chiffrée (commité, chiffré ansible-vault)
├── playbook.yml
└── roles/

ansible.cfg                ← à la racine du projet, pointe vers .vault_pass
.vault_pass                ← mot de passe vault (non commité, dans .gitignore)
```

---

## 📦 Inventory

Fichier : `infra/ansible/inventory.ini`

```ini
[controlPlane]
34.254.23.101 server_role=control-plane

[worker]
52.213.136.208 server_role=worker
3.254.114.4    server_role=worker
108.131.55.2   server_role=worker
```

Les variables de connexion sont centralisées dans `group_vars/all/vars.yml` :

```yaml
ansible_user: ec2-user
ansible_ssh_private_key_file: /tmp/kubequest_deploy_key
ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
```

---

## 📋 Playbook

### Tags disponibles

| Tag | Comportement par défaut | Description |
|-----|------------------------|-------------|
| `setup` | s'exécute | Installation containerd, kubeadm, init cluster, join workers |
| `update` | s'exécute | Configuration du registry |
| `services` | **jamais** (`never`) | Déploiement Traefik + ArgoCD + Dashboard |
| `argo` | **jamais** (`never`) | Déploiement ArgoCD seul |
| `delete` | **jamais** (`never`) | Suppression de tous les services |
| `always` | toujours | Écriture de la clé SSH depuis le vault |

Les tags `services`, `argo` et `delete` sont marqués `never` : ils ne s'exécutent jamais lors d'un run global, uniquement si explicitement demandés avec `--tags`.

---

## 🔐 Clé SSH via Ansible Vault

La clé SSH est stockée chiffrée dans `group_vars/all/vault.yml`. Les développeurs n'ont pas besoin d'avoir le fichier `.pem` sur leur poste — seul le mot de passe du vault est nécessaire.

Au lancement du playbook, le premier play (tag `always`) déchiffre la clé et l'écrit dans `/tmp/kubequest_deploy_key`. Ce fichier est utilisé par tous les plays suivants pour la connexion SSH.

### Procédure — déverrouiller le vault (une fois par développeur)

**1. Créer le fichier de mot de passe vault**

```bash
echo "le_mot_de_passe_vault" > .vault_pass
chmod 600 .vault_pass
```

> Demande le mot de passe à un membre de l'équipe. Ce fichier ne doit jamais être commité (il est dans `.gitignore`).

**2. Vérifier que le vault se déchiffre correctement**

```bash
ansible-vault view infra/ansible/group_vars/all/vault.yml
```

Tu dois voir le contenu YAML avec la clé `vault_ssh_private_key`.

**3. C'est tout** — les commandes `make` fonctionnent directement.

---

### Modifier le vault (si besoin de changer la clé SSH)

```bash
ansible-vault edit infra/ansible/group_vars/all/vault.yml
```

Le contenu doit respecter ce format (indentation de 2 espaces obligatoire) :

```yaml
vault_ssh_private_key: |
  -----BEGIN RSA PRIVATE KEY-----
  MIIJJwIBAAK...
  -----END RSA PRIVATE KEY-----
```

Pour remplacer complètement le vault depuis un fichier en clair :

```bash
ansible-vault encrypt fichier_cle.txt --output infra/ansible/group_vars/all/vault.yml
rm fichier_cle.txt
```

---

## 🚀 Déploiement

### Prérequis

- Ansible installé sur la machine de contrôle
- Collection `kubernetes.core` installée (`ansible-galaxy collection install kubernetes.core`)
- Fichier `.vault_pass` à la racine du projet (voir procédure ci-dessus)

### Commandes

```bash
# Bootstrap complet du cluster (setup + update)
make setup

# Déployer les services (Traefik, ArgoCD, Dashboard)
make setup-services

# Déployer ArgoCD seul
make setup-argo

# Supprimer les services
make delete
```

---

## 🏷️ Labels et taints

Le rôle `Init_Kube` applique :

- `workload=control-plane` sur le control-plane
- `workload=general` sur tous les workers
- suppression des anciens taints applicatifs `role=*`

Vérification :

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

## ✅ Critères de résilience à vérifier

- `kubectl get nodes -L workload` montre `1` control-plane et `3` workers généralistes
- Traefik tourne sur au moins `2` workers
- l'application Helm tourne sur `2` à `3` workers avec plusieurs replicas
- ArgoCD et Headlamp ne sont plus épinglés à un worker spécifique

---
<div align="center">

**Projet KubeQuest**

</div>
