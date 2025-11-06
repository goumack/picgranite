# Script pour maintenir le modèle Ollama actif dans un conteneur OpenShift
# Utilise les variables d'environnement et inclut un serveur HTTP pour les health checks

# Configuration via variables d'environnement avec valeurs par défaut
$Uri = $env:OLLAMA_URI ?? "https://ollamaaccel-chatbotaccel.apps.senum.heritage.africa/api/generate"
$ModelName = $env:MODEL_NAME ?? "granite-code:3b"
$IntervalMinutes = [int]($env:INTERVAL_MINUTES ?? "2")
$Prompt = $env:PROMPT ?? "Bonjour"

$Headers = @{"Content-Type" = "application/json"}
$Body = @{
    model = $ModelName
    prompt = $Prompt
    stream = $false
} | ConvertTo-Json

Write-Host "=== Keep-Ollama-Alive Container ===" -ForegroundColor Green
Write-Host "Modèle: $ModelName" -ForegroundColor Yellow
Write-Host "Intervalle: $IntervalMinutes minutes" -ForegroundColor Yellow
Write-Host "URI: $Uri" -ForegroundColor Yellow
Write-Host "Prompt: $Prompt" -ForegroundColor Yellow
Write-Host ""

# Variables de suivi
$RequestCount = 0
$LastSuccessTime = Get-Date
$IsHealthy = $true

# Fonction pour le serveur HTTP de health check
function Start-HealthCheckServer {
    $HttpListener = New-Object System.Net.HttpListener
    $HttpListener.Prefixes.Add("http://+:8080/")
    
    try {
        $HttpListener.Start()
        Write-Host "Serveur de health check démarré sur le port 8080" -ForegroundColor Cyan
        
        # Traitement asynchrone des requêtes de health check
        Register-ObjectEvent -InputObject $HttpListener -EventName "GetContextCompleted" -Action {
            param($sender, $e)
            $context = $e.AsyncResult.AsyncState
            $request = $context.Request
            $response = $context.Response
            
            $healthStatus = @{
                status = if ($script:IsHealthy) { "healthy" } else { "unhealthy" }
                lastRequest = $script:RequestCount
                lastSuccess = $script:LastSuccessTime.ToString("yyyy-MM-dd HH:mm:ss")
                uptime = [math]::Round(((Get-Date) - $script:StartTime).TotalMinutes, 2)
                model = $script:ModelName
            } | ConvertTo-Json
            
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($healthStatus)
            $response.ContentLength64 = $buffer.Length
            $response.ContentType = "application/json"
            $response.StatusCode = if ($script:IsHealthy) { 200 } else { 503 }
            
            $output = $response.OutputStream
            $output.Write($buffer, 0, $buffer.Length)
            $output.Close()
        }
    }
    catch {
        Write-Host "Impossible de démarrer le serveur de health check: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Démarrer le serveur de health check
$StartTime = Get-Date
#Start-HealthCheckServer

# Boucle principale
while ($true) {
    try {
        $RequestCount++
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        Write-Host "[$Timestamp] Requête #$RequestCount - Envoi du ping vers $ModelName..." -ForegroundColor White
        
        # Exécution de la requête avec timeout
        $Response = Invoke-WebRequest -Uri $Uri -Method POST -Headers $Headers -Body $Body -TimeoutSec 30
        
        if ($Response.StatusCode -eq 200) {
            Write-Host "[$Timestamp] ✓ Succès - Modèle maintenu actif" -ForegroundColor Green
            $LastSuccessTime = Get-Date
            $IsHealthy = $true
            
            # Optionnel: afficher une partie de la réponse
            try {
                $ResponseData = $Response.Content | ConvertFrom-Json
                if ($ResponseData.response -and $ResponseData.response.Length -gt 0) {
                    $Preview = $ResponseData.response.Substring(0, [Math]::Min(50, $ResponseData.response.Length))
                    Write-Host "   Réponse: $Preview..." -ForegroundColor Gray
                }
            }
            catch {
                Write-Host "   Réponse reçue (format non JSON)" -ForegroundColor Gray
            }
        } else {
            Write-Host "[$Timestamp] ⚠ Code de statut: $($Response.StatusCode)" -ForegroundColor Yellow
            $IsHealthy = $false
        }
    }
    catch {
        Write-Host "[$Timestamp] ✗ Erreur: $($_.Exception.Message)" -ForegroundColor Red
        $IsHealthy = $false
        
        # Si pas de succès depuis plus de 10 minutes, considérer comme critique
        if (((Get-Date) - $LastSuccessTime).TotalMinutes -gt 10) {
            Write-Host "[$Timestamp] ⚠ Aucun succès depuis plus de 10 minutes!" -ForegroundColor Red
        }
    }
    
    # Attendre l'intervalle configuré
    Write-Host "   Attente de $IntervalMinutes minutes..." -ForegroundColor Gray
    Start-Sleep -Seconds ($IntervalMinutes * 60)
}