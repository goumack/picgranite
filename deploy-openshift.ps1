# Script PowerShell de déploiement pour OpenShift

param(
    [Parameter(Position=0)]
    [ValidateSet("deploy", "cleanup", "status")]
    [string]$Action = "deploy"
)

# Variables
$ProjectName = "ollama-keepalive"
$AppName = "ollama-keepalive"

# Fonction de vérification de connexion OpenShift
function Test-OCConnection {
    Write-Host "Vérification de la connexion OpenShift..." -ForegroundColor Yellow
    
    try {
        $user = oc whoami 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Connecté à OpenShift en tant que: $user" -ForegroundColor Green
            return $true
        }
    }
    catch {}
    
    Write-Host "❌ Erreur: Vous n'êtes pas connecté à OpenShift" -ForegroundColor Red
    Write-Host "Connectez-vous d'abord avec: oc login <server-url>" -ForegroundColor Yellow
    return $false
}

# Fonction de configuration du projet
function Initialize-Project {
    Write-Host "Configuration du projet OpenShift..." -ForegroundColor Yellow
    
    # Vérifier si le projet existe
    $projectExists = oc get project $ProjectName 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Le projet $ProjectName existe déjà" -ForegroundColor Green
        oc project $ProjectName
    }
    else {
        Write-Host "Création du projet $ProjectName" -ForegroundColor Yellow
        oc new-project $ProjectName --description="Ollama Keep-Alive Service" --display-name="Ollama Keep-Alive"
    }
}

# Fonction de déploiement
function Deploy-Application {
    Write-Host "Déploiement de l'application..." -ForegroundColor Yellow
    
    # Mettre à jour le Dockerfile pour utiliser le bon script
    $dockerfileContent = Get-Content "Dockerfile" -Raw
    $updatedDockerfile = $dockerfileContent -replace "keep-ollama-alive\.ps1", "keep-ollama-alive-container.ps1"
    Set-Content "Dockerfile" $updatedDockerfile
    
    try {
        # Appliquer la configuration de build
        Write-Host "Application de la configuration de build..." -ForegroundColor Cyan
        oc apply -f openshift-build.yaml
        
        # Démarrer le build
        Write-Host "Démarrage du build..." -ForegroundColor Cyan
        oc start-build "$AppName-build" --follow
        
        # Appliquer la configuration de déploiement
        Write-Host "Application de la configuration de déploiement..." -ForegroundColor Cyan
        oc apply -f openshift-deployment.yaml
        
        # Attendre que le déploiement soit prêt
        Write-Host "Attente du déploiement..." -ForegroundColor Cyan
        oc rollout status "deployment/$AppName" --timeout=300s
        
        Write-Host "✅ Déploiement terminé avec succès!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Erreur lors du déploiement: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# Fonction d'affichage des informations
function Show-DeploymentInfo {
    Write-Host ""
    Write-Host "=== Informations de déploiement ===" -ForegroundColor Green
    Write-Host "Projet: $ProjectName" -ForegroundColor White
    Write-Host "Application: $AppName" -ForegroundColor White
    Write-Host ""
    
    # État des pods
    Write-Host "État des pods:" -ForegroundColor Yellow
    oc get pods -l app=$AppName
    Write-Host ""
    
    # Services
    Write-Host "Services:" -ForegroundColor Yellow
    oc get svc -l app=$AppName
    Write-Host ""
    
    # Routes
    Write-Host "Routes:" -ForegroundColor Yellow
    oc get route -l app=$AppName
    
    # URL de l'application
    try {
        $routeUrl = oc get route "$AppName-route" -o jsonpath='{.spec.host}' 2>$null
        if ($LASTEXITCODE -eq 0 -and $routeUrl) {
            Write-Host ""
            Write-Host "🌐 URL de monitoring: https://$routeUrl" -ForegroundColor Cyan
        }
    }
    catch {}
}

# Fonction de nettoyage
function Remove-Deployment {
    Write-Host "Nettoyage des ressources existantes..." -ForegroundColor Yellow
    
    oc delete all -l app=$AppName --ignore-not-found=true
    oc delete route "$AppName-route" --ignore-not-found=true
    oc delete bc "$AppName-build" --ignore-not-found=true
    oc delete is $AppName --ignore-not-found=true
    
    Write-Host "✅ Nettoyage terminé" -ForegroundColor Green
}

# Fonction principale
function Main {
    param($Action)
    
    Write-Host "=== Déploiement Ollama Keep-Alive sur OpenShift ===" -ForegroundColor Green
    
    # Vérifier la connexion OpenShift
    if (-not (Test-OCConnection)) {
        exit 1
    }
    
    switch ($Action) {
        "deploy" {
            Initialize-Project
            Deploy-Application
            Show-DeploymentInfo
        }
        "cleanup" {
            try { oc project $ProjectName 2>$null } catch {}
            Remove-Deployment
        }
        "status" {
            try { oc project $ProjectName 2>$null } catch {}
            Show-DeploymentInfo
        }
        default {
            Write-Host "Usage: .\deploy-openshift.ps1 [deploy|cleanup|status]" -ForegroundColor Yellow
            Write-Host "  deploy  - Déploie l'application (défaut)" -ForegroundColor White
            Write-Host "  cleanup - Supprime toutes les ressources" -ForegroundColor White
            Write-Host "  status  - Affiche l'état actuel" -ForegroundColor White
            exit 1
        }
    }
}

# Exécution
try {
    Main $Action
}
catch {
    Write-Host "❌ Erreur critique: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}