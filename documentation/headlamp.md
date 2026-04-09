<div align="center">

# ⚓ KubeQuest

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)
![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=for-the-badge&logo=traefikproxy&logoColor=white)

**Automatisation et déploiement d'infrastructure cloud sur AWS**

</div>

---

## 📖 À propos

Headlamp est utilisé dans le projet KubeQuest comme **dashboard Kubernetes** pour :

- Visualiser et gérer les ressources du cluster (Pods, Deployments, Services, etc.)
- Inspecter les logs et l'état des workloads en temps réel
- Naviguer dans les namespaces et les configurations
- Accéder à l'interface sans installer kubectl en local

Headlamp est déployé via **Helm** sur le nœud `kube2` et exposé via une **IngressRoute Traefik**.

---

## 🏗️ Architecture

```
Internet → Traefik (nœud ingress) → IngressRoute → Headlamp (nœud kube2)
```

| Composant | Détail |
|-----------|--------|
| Nœud | VM `kube2` (label `role=kube2`) |
| Namespace | `dashboard` |
| Helm chart | `headlamp/headlamp` |
| Exposition | IngressRoute Traefik sur `headlamp.kubequest.local` |
| Port service | `80` |

---

## 📦 Déploiement via Ansible

### Rôle `Deploy_Dashboard`

```
roles/Deploy_Dashboard/
├── tasks/
│   └── main.yml
└── files/
    ├── values.yaml
    └── ingressroute.yaml
```

### Tâches (`tasks/main.yml`)

```yaml
---
- name: Install Helm
  shell: |
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  args:
    creates: /usr/local/bin/helm
  become: true

- name: Copy Headlamp values
  copy:
    src: values.yaml
    dest: /tmp/headlamp-values.yaml

- name: Copy Headlamp IngressRoute
  copy:
    src: ingressroute.yaml
    dest: /tmp/headlamp-ingressroute.yaml

- name: Add Headlamp Helm repo
  kubernetes.core.helm_repository:
    name: headlamp
    repo_url: https://kubernetes-sigs.github.io/headlamp/

- name: Deploy Headlamp Dashboard
  kubernetes.core.helm:
    name: headlamp
    chart_ref: headlamp/headlamp
    release_namespace: dashboard
    create_namespace: true
    values_files:
      - /tmp/headlamp-values.yaml
    wait: true

- name: Apply Headlamp IngressRoute
  kubernetes.core.k8s:
    src: /tmp/headlamp-ingressroute.yaml
    state: present
```

### Values Helm (`files/values.yaml`)

```yaml
nodeSelector:
  role: kube2

tolerations:
  - key: "role"
    operator: "Equal"
    value: "kube2"
    effect: "NoSchedule"

ingress:
  enabled: false
```

**Points clés de la configuration :**

- `nodeSelector` + `tolerations` — garantit que Headlamp tourne uniquement sur le nœud `kube2`
- `ingress.enabled: false` — l'exposition est gérée par une IngressRoute Traefik dédiée

### IngressRoute (`files/ingressroute.yaml`)

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: headlamp
  namespace: dashboard
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`headlamp.kubequest.local`)
      kind: Rule
      services:
        - name: headlamp
          port: 80
```

---

## 🌐 Accès

### Configuration DNS locale

Ajouter dans le fichier hosts de votre machine :

- **Linux/Mac** : `/etc/hosts`
- **Windows** : `C:\Windows\System32\drivers\etc\hosts`

```
<IP_PUBLIQUE_INGRESS>  headlamp.kubequest.local
```

### URL d'accès

| Service | URL |
|---------|-----|
| Headlamp Dashboard | `http://headlamp.kubequest.local` |

---

## 🔐 Authentification

Headlamp utilise les **tokens de service account** Kubernetes pour l'authentification.

### Créer un token d'accès

```bash
# Créer un service account dédié
kubectl create serviceaccount headlamp-admin -n dashboard

# Créer un ClusterRoleBinding pour l'accès cluster-admin
kubectl create clusterrolebinding headlamp-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=dashboard:headlamp-admin

# Générer un token
kubectl create token headlamp-admin -n dashboard
```

Copier le token affiché et le coller dans l'interface web de Headlamp.

---

## 🗑️ Suppression

Le rôle `Delete_Dashboard` supprime Headlamp et son namespace :

```yaml
- name: Uninstall Headlamp Helm release
  kubernetes.core.helm:
    name: headlamp
    release_namespace: dashboard
    state: absent
    wait: true

- name: Delete Dashboard namespace
  kubernetes.core.k8s:
    kind: Namespace
    name: dashboard
    state: absent
```

### Via Makefile

```bash
make delete
```

---

## 🔍 Vérification

### Vérifier que Headlamp tourne

```bash
kubectl get pods -n dashboard -o wide
```

Résultat attendu :

```
NAME                        READY   STATUS    NODE
headlamp-xxxxx-xxxxx        1/1     Running   ip-10-1-23-169.eu-west-1.compute.internal
```

### Vérifier le service et l'IngressRoute

```bash
kubectl get svc -n dashboard
kubectl get ingressroute -n dashboard
```

### Tester l'accès

```bash
# Depuis l'extérieur
curl -H "Host: headlamp.kubequest.local" http://<IP_PUBLIQUE_INGRESS>

# Depuis le cluster
curl http://headlamp.dashboard.svc.cluster.local
```

---

## 🛠️ Commandes utiles

```bash
# Voir les logs Headlamp
kubectl logs -n dashboard -l app.kubernetes.io/name=headlamp -f

# Redéployer avec de nouvelles values
helm upgrade headlamp headlamp/headlamp -n dashboard -f values.yaml

# Désinstaller Headlamp
helm uninstall headlamp -n dashboard

# Vérifier le release Helm
helm list -n dashboard
```

---

<div align="center">

**Projet KubeQuest**

</div>
