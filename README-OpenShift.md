# Instructions de déploiement sur OpenShift

## Prérequis
- Accès à un cluster OpenShift
- CLI OpenShift (`oc`) installé et configuré
- Connexion établie au cluster : `oc login <server-url>`

## Structure des fichiers
```
├── Dockerfile                           # Image de conteneur PowerShell
├── keep-ollama-alive-container.ps1     # Script adapté pour conteneur
├── openshift-build.yaml               # Configuration de build OpenShift
├── openshift-deployment.yaml          # Déploiement, Service et Route
├── deploy-openshift.ps1               # Script de déploiement PowerShell
└── deploy-openshift.sh                # Script de déploiement Bash
```

## Déploiement rapide

### Méthode 1: Script PowerShell (Windows)
```powershell
# Déploiement complet
.\deploy-openshift.ps1

# Vérifier le statut
.\deploy-openshift.ps1 status

# Nettoyer les ressources
.\deploy-openshift.ps1 cleanup
```

### Méthode 2: Script Bash (Linux/Mac)
```bash
# Rendre le script exécutable
chmod +x deploy-openshift.sh

# Déploiement complet
./deploy-openshift.sh

# Vérifier le statut
./deploy-openshift.sh status

# Nettoyer les ressources
./deploy-openshift.sh cleanup
```

### Méthode 3: Déploiement manuel
```bash
# 1. Créer le projet
oc new-project ollama-keepalive

# 2. Appliquer la configuration de build
oc apply -f openshift-build.yaml

# 3. Démarrer le build
oc start-build ollama-keepalive-build --follow

# 4. Appliquer le déploiement
oc apply -f openshift-deployment.yaml

# 5. Vérifier le déploiement
oc rollout status deployment/ollama-keepalive
```

## Configuration

### Variables d'environnement modifiables dans `openshift-deployment.yaml`:
- `OLLAMA_URI`: URL de l'API Ollama
- `MODEL_NAME`: Nom du modèle à maintenir actif
- `INTERVAL_MINUTES`: Intervalle entre les requêtes (en minutes)
- `PROMPT`: Message à envoyer au modèle

### Ressources allouées:
- **CPU**: 100m (request) / 200m (limit)
- **Mémoire**: 128Mi (request) / 256Mi (limit)

## Surveillance

### Health Checks
- **Liveness Probe**: Vérifie que l'application fonctionne
- **Readiness Probe**: Vérifie que l'application est prête à recevoir du trafic
- **Endpoint**: `http://pod:8080/` (retourne du JSON avec le statut)

### Logs
```bash
# Voir les logs en temps réel
oc logs -f deployment/ollama-keepalive

# Voir les logs d'un pod spécifique
oc logs <pod-name>
```

### Accès à l'interface de monitoring
Une fois déployé, l'application expose une route HTTPS pour monitorer son état:
- URL: `https://<route-url>/` (affichée après déploiement)
- Retour JSON avec statut, nombre de requêtes, dernière réussite, etc.

## Dépannage

### Problèmes courants
1. **Build qui échoue**: Vérifier que le Dockerfile est correct
2. **Pod qui redémarre**: Vérifier les logs et les limites de ressources
3. **Connexion refusée**: Vérifier l'URL d'Ollama et la connectivité réseau

### Commandes de diagnostic
```bash
# État général
oc get all -l app=ollama-keepalive

# Décrire le déploiement
oc describe deployment ollama-keepalive

# Événements récents
oc get events --sort-by=.metadata.creationTimestamp

# Entrer dans le conteneur
oc exec -it deployment/ollama-keepalive -- pwsh
```

## Personnalisation

### Modifier l'intervalle
Éditer la variable `INTERVAL_MINUTES` dans `openshift-deployment.yaml` puis:
```bash
oc apply -f openshift-deployment.yaml
```

### Changer le modèle
Éditer la variable `MODEL_NAME` dans `openshift-deployment.yaml` puis:
```bash
oc apply -f openshift-deployment.yaml
```

### Scaling
```bash
# Augmenter le nombre de replicas (non recommandé pour ce cas d'usage)
oc scale deployment ollama-keepalive --replicas=1
```

## Sécurité
- L'application s'exécute avec un utilisateur non-root (UID 1001)
- Utilise des Security Context appropriés pour OpenShift
- La route utilise TLS avec redirection automatique HTTPS