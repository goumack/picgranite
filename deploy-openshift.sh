#!/bin/bash
# Script de déploiement pour OpenShift

set -e

echo "=== Déploiement Ollama Keep-Alive sur OpenShift ==="

# Variables
PROJECT_NAME="ollama-keepalive"
APP_NAME="ollama-keepalive"

# Fonction de vérification de connexion OpenShift
check_oc_connection() {
    echo "Vérification de la connexion OpenShift..."
    if ! oc whoami &> /dev/null; then
        echo "❌ Erreur: Vous n'êtes pas connecté à OpenShift"
        echo "Connectez-vous d'abord avec: oc login <server-url>"
        exit 1
    fi
    echo "✅ Connecté à OpenShift en tant que: $(oc whoami)"
}

# Fonction de création/sélection du projet
setup_project() {
    echo "Configuration du projet OpenShift..."
    
    if oc get project $PROJECT_NAME &> /dev/null; then
        echo "Le projet $PROJECT_NAME existe déjà"
        oc project $PROJECT_NAME
    else
        echo "Création du projet $PROJECT_NAME"
        oc new-project $PROJECT_NAME --description="Ollama Keep-Alive Service" --display-name="Ollama Keep-Alive"
    fi
}

# Fonction de build et déploiement
deploy_application() {
    echo "Déploiement de l'application..."
    
    # Appliquer la configuration de build
    echo "Application de la configuration de build..."
    oc apply -f openshift-build.yaml
    
    # Démarrer le build
    echo "Démarrage du build..."
    oc start-build $APP_NAME-build --follow
    
    # Appliquer la configuration de déploiement
    echo "Application de la configuration de déploiement..."
    oc apply -f openshift-deployment.yaml
    
    # Attendre que le déploiement soit prêt
    echo "Attente du déploiement..."
    oc rollout status deployment/$APP_NAME --timeout=300s
}

# Fonction d'affichage des informations
show_info() {
    echo ""
    echo "=== Informations de déploiement ==="
    echo "Projet: $PROJECT_NAME"
    echo "Application: $APP_NAME"
    echo ""
    
    # Afficher l'état des pods
    echo "État des pods:"
    oc get pods -l app=$APP_NAME
    echo ""
    
    # Afficher les services
    echo "Services:"
    oc get svc -l app=$APP_NAME
    echo ""
    
    # Afficher les routes
    echo "Routes:"
    oc get route -l app=$APP_NAME
    
    # URL de l'application
    ROUTE_URL=$(oc get route ${APP_NAME}-route -o jsonpath='{.spec.host}' 2>/dev/null || echo "Pas de route configurée")
    if [ "$ROUTE_URL" != "Pas de route configurée" ]; then
        echo ""
        echo "🌐 URL de monitoring: https://$ROUTE_URL"
    fi
}

# Fonction de nettoyage (optionnelle)
cleanup() {
    echo "Nettoyage des ressources existantes..."
    oc delete all -l app=$APP_NAME --ignore-not-found=true
    oc delete route ${APP_NAME}-route --ignore-not-found=true
    oc delete bc ${APP_NAME}-build --ignore-not-found=true
    oc delete is $APP_NAME --ignore-not-found=true
}

# Fonction principale
main() {
    case "${1:-deploy}" in
        "deploy")
            check_oc_connection
            setup_project
            deploy_application
            show_info
            ;;
        "cleanup")
            check_oc_connection
            oc project $PROJECT_NAME 2>/dev/null || true
            cleanup
            echo "✅ Nettoyage terminé"
            ;;
        "status")
            check_oc_connection
            oc project $PROJECT_NAME 2>/dev/null || true
            show_info
            ;;
        *)
            echo "Usage: $0 [deploy|cleanup|status]"
            echo "  deploy  - Déploie l'application (défaut)"
            echo "  cleanup - Supprime toutes les ressources"
            echo "  status  - Affiche l'état actuel"
            exit 1
            ;;
    esac
}

# Exécution
main "$@"