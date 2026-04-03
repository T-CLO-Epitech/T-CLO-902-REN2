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

Traefik est utilisé dans le projet KubeQuest comme **Ingress Controller** pour :

- Router le trafic HTTP/HTTPS vers les services du cluster
- Exposer les applications via des noms de domaine (IngressRoutes)
- Fournir un **dashboard** de visualisation des routes et services

Traefik est déployé en mode **hostNetwork** directement sur le nœud `ingress`, ce qui lui permet de binder sur les ports 80 et 443 de la VM sans passer par un NodePort.

---

## 🏗️ Architecture

```
Internet → IP publique VM ingress → port 80/443 → Traefik (hostNetwork) → Services K8s
```

| Composant | Détail |
|-----------|--------|
| Nœud | VM `ingress` (label `role=ingress`) |
| Mode réseau | `hostNetwork: true` |
| Ports | 80 (HTTP), 443 (HTTPS) |
| Déploiement | Helm chart `traefik/traefik` via Ansible |
| Accès externe | IP publique de la VM ingress |

---

## 📦 Déploiement via Ansible

### Rôle `Deploy_Traefik`

```
roles/Deploy_Traefik/
├── tasks/
│   └── main.yml
└── files/
    └── values.yaml
```

### Tâches (`tasks/main.yml`)

```yaml
---
- name: Copy Traefik values
  copy:
    src: values.yaml
    dest: /tmp/traefik-values.yaml

- name: Add Traefik Helm repo
  kubernetes.core.helm_repository:
    name: traefik
    repo_url: https://traefik.github.io/charts

- name: Deploy Traefik
  kubernetes.core.helm:
    name: traefik
    chart_ref: traefik/traefik
    release_namespace: traefik
    create_namespace: true
    values_files:
      - /tmp/traefik-values.yaml
    wait: true
```

### Values Helm (`files/values.yaml`)

```yaml
nodeSelector:
  role: ingress

tolerations:
  - key: "role"
    operator: "Equal"
    value: "ingress"
    effect: "NoSchedule"

hostNetwork: true

service:
  enabled: false

securityContext:
  capabilities:
    add:
      - NET_BIND_SERVICE
    drop:
      - ALL
  runAsNonRoot: false
  runAsUser: 0
  runAsGroup: 0

podSecurityContext:
  runAsNonRoot: false
  runAsUser: 0
  runAsGroup: 0

ports:
  web:
    port: 80
    hostPort: 80
  websecure:
    port: 443
    hostPort: 443

ingressRoute:
  dashboard:
    enabled: true
    matchRule: Host(`traefik.kubequest.local`)
    entryPoints:
      - web

providers:
  kubernetesIngress:
    enabled: true
```

**Points clés de la configuration :**

- `hostNetwork: true` — Traefik se bind directement sur les ports de la VM, pas besoin de NodePort ni d'iptables
- `service.enabled: false` — pas de Service Kubernetes nécessaire en mode hostNetwork
- `securityContext` — nécessaire pour binder sur les ports privilégiés (80/443) avec `NET_BIND_SERVICE`
- `nodeSelector` + `tolerations` — garantit que Traefik ne tourne que sur le nœud ingress
- `ingressRoute.dashboard` — active le dashboard Traefik accessible via le host `traefik.kubequest.local`

---

## 🌐 Accès

### Configuration DNS locale

Ajouter dans le fichier hosts de votre machine :

- **Linux/Mac** : `/etc/hosts`
- **Windows** : `C:\Windows\System32\drivers\etc\hosts`

```
<IP_PUBLIQUE_INGRESS>  traefik.kubequest.local 
```

### URLs d'accès

| Service | URL |
|---------|-----|
| Dashboard Traefik | `http://traefik.kubequest.local/dashboard/` |


> **Note** : Le `/` final est obligatoire pour le dashboard : `/dashboard/` et non `/dashboard`

---

## 🔀 Exposer un nouveau service

Pour exposer une application via Traefik, créer un **IngressRoute** :

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: mon-app
  namespace: default
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`mon-app.kubequest.local`)
      kind: Rule
      services:
        - name: mon-app-service
          port: 80
```

Puis ajouter le domaine dans le fichier hosts local :

```
<IP_PUBLIQUE_INGRESS>  mon-app.kubequest.local
```

---

## 🔍 Vérification

### Vérifier que Traefik tourne

```bash
kubectl get pods -n traefik -o wide
```

Résultat attendu :

```
NAME                      READY   STATUS    NODE
traefik-xxxxx-xxxxx       1/1     Running   ip-10-1-23-52.eu-west-1.compute.internal
```

### Vérifier les ports

Depuis la VM ingress :

```bash
sudo ss -tlnp | grep -E ':80|:443|:8080'
```

### Tester le routing

```bash
# Depuis n'importe quel nœud du cluster
curl -H "Host: traefik.kubequest.local" http://<IP_INTERNE_INGRESS>/dashboard/

# Depuis l'extérieur
curl -H "Host: traefik.kubequest.local" http://<IP_PUBLIQUE_INGRESS>/dashboard/
```

---

## 🛠️ Commandes utiles

```bash
# Voir les logs Traefik
kubectl logs -n traefik -l app.kubernetes.io/name=traefik -f

# Redéployer avec de nouvelles values
helm upgrade traefik traefik/traefik -n traefik -f values.yaml

# Désinstaller Traefik
helm uninstall traefik -n traefik

# Vérifier le release Helm
helm list -n traefik
```

---

<div align="center">

**Projet KubeQuest**

</div>