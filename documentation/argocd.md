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

ArgoCD est utilisé dans le projet KubeQuest comme outil de **GitOps** pour :

- Déployer et synchroniser automatiquement les applications depuis un dépôt Git
- Visualiser l'état des déploiements via une **interface web**
- Détecter les dérives entre l'état désiré (Git) et l'état réel (cluster)
- Gérer les **rollbacks** automatiques en cas de déploiement cassé

---

## 🏗️ Architecture

```
Internet → Traefik (nœud ingress) → IngressRoute → ArgoCD Server (nœud kube2)
                                                         ↓
                                                    Dépôt Git ←→ Cluster K8s
```

| Composant | Détail |
|-----------|--------|
| Nœud | VM `kube2` (label `role=kube2`) |
| Namespace | `argocd` |
| Helm chart | `argo/argo-cd` |
| Exposition | IngressRoute Traefik sur `argocd.kubequest.local` |
| Mode | HTTP (flag `--insecure`) |

---

## 🌐 Accès

### Configuration DNS locale

Ajouter dans le fichier hosts de votre machine :

- **Linux/Mac** : `/etc/hosts`
- **Windows** : `C:\Windows\System32\drivers\etc\hosts`

```
<IP_PUBLIQUE_INGRESS>  argocd.kubequest.local
```

### Première connexion

| Champ | Valeur |
|-------|--------|
| URL | `http://argocd.kubequest.local` |
| Login | `admin` |
| Mot de passe | Voir commande ci-dessous |

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

---

## 🔗 Ajouter une application à ArgoCD

### Via l'interface web

1. Se connecter à `http://argocd.kubequest.local`
2. Cliquer sur **New App**
3. Remplir les champs :
    - **Application Name** : `mon-app`
    - **Project** : `default`
    - **Repository URL** : URL du dépôt Git
    - **Path** : chemin vers les manifests dans le repo
    - **Cluster URL** : `https://kubernetes.default.svc`
    - **Namespace** : namespace de destination
4. Cliquer sur **Create**

### Via la CLI

```bash
# Installer la CLI ArgoCD
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd && sudo mv argocd /usr/local/bin/

# Se connecter
argocd login argocd.kubequest.local --insecure --username admin --password <MOT_DE_PASSE>

# Ajouter un dépôt
argocd repo add https://github.com/user/repo.git

# Créer une application
argocd app create mon-app \
  --repo https://github.com/user/repo.git \
  --path manifests/ \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated
```

### Via un manifest Kubernetes

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: mon-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/user/repo.git
    targetRevision: main
    path: manifests/
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

```bash
kubectl apply -f application.yaml
```

---

## 🔍 Vérification

### Vérifier que tous les pods tournent

```bash
kubectl get pods -n argocd -o wide
```

Tous les pods doivent être sur le nœud `kube2`.

### Vérifier l'accès

```bash
# Depuis l'extérieur
curl http://argocd.kubequest.local

# Depuis le cluster
curl http://argocd-server.argocd.svc.cluster.local
```

---

## 🛠️ Commandes utiles

```bash
# Voir les logs du server ArgoCD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f

# Lister les applications
argocd app list

# Synchroniser une application manuellement
argocd app sync mon-app

# Voir le statut d'une application
argocd app get mon-app

# Rollback vers une version précédente
argocd app rollback mon-app <REVISION>

# Désinstaller ArgoCD
helm uninstall argocd -n argocd
```

---

<div align="center">

**Projet KubeQuest**

</div>