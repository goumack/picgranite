# Script pour maintenir ALEX actif avec rotation de messages
# Version adaptee pour l'API ALEX

# Configuration via variables d'environnement avec valeurs par defaut
$AlexUri = if ($env:ALEX_URI) { $env:ALEX_URI } else { "https://alex-route-alex-granitechatbot.apps.ocp.heritage.africa/chat" }
$Message1 = if ($env:MESSAGE_1) { $env:MESSAGE_1 } else { "Quels sont les services d'Accel Tech ?" }
$Message2 = if ($env:MESSAGE_2) { $env:MESSAGE_2 } else { "Comment puis-je vous aider aujourd'hui ?" }
$IntervalMinutes = if ($env:INTERVAL_MINUTES) { [int]$env:INTERVAL_MINUTES } else { 2 }

# Liste des messages pour la rotation
$Messages = @($Message1, $Message2)

Write-Host "=== Keep-ALEX-Alive Container ===" -ForegroundColor Green
Write-Host "API URI: $AlexUri" -ForegroundColor Yellow
Write-Host "Intervalle: $IntervalMinutes minutes" -ForegroundColor Yellow
Write-Host "Messages:" -ForegroundColor Yellow
for ($i = 0; $i -lt $Messages.Count; $i++) {
    Write-Host "  $($i + 1). $($Messages[$i])" -ForegroundColor Cyan
}
Write-Host ""

# Variables de suivi
$RequestCount = 0
$LastSuccessTime = Get-Date
$IsHealthy = $true
$StartTime = Get-Date
$CurrentMessageIndex = 0

# Boucle principale
while ($true) {
    try {
        $RequestCount++
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # Selectionner le message actuel
        $CurrentMessage = $Messages[$CurrentMessageIndex]
        
        Write-Host "[$Timestamp] Requete #$RequestCount - Message: `"$CurrentMessage`"..." -ForegroundColor White
        
        # Preparer le body pour l'API ALEX
        $Body = @{
            message = $CurrentMessage
        } | ConvertTo-Json -Compress
        
        # Execution de la requete avec l'API ALEX
        $Response = Invoke-WebRequest -Uri $AlexUri -Method POST -Body $Body -ContentType "application/json" -TimeoutSec 30
        
        if ($Response.StatusCode -eq 200) {
            Write-Host "[$Timestamp] Succes - ALEX maintenu actif" -ForegroundColor Green
            $LastSuccessTime = Get-Date
            $IsHealthy = $true
            
            # Decoder et afficher la reponse d'ALEX
            try {
                $ResponseData = $Response.Content | ConvertFrom-Json
                if ($ResponseData.response -and $ResponseData.response.Length -gt 0) {
                    $Preview = $ResponseData.response.Substring(0, [Math]::Min(100, $ResponseData.response.Length))
                    Write-Host "   Reponse ALEX: $Preview..." -ForegroundColor Gray
                } else {
                    Write-Host "   Reponse ALEX recue (format inattendu)" -ForegroundColor Gray
                }
            }
            catch {
                Write-Host "   Reponse ALEX recue (parsing JSON echoue)" -ForegroundColor Gray
            }
            
            # Passer au message suivant pour la prochaine iteration
            $CurrentMessageIndex = ($CurrentMessageIndex + 1) % $Messages.Count
            
        } else {
            Write-Host "[$Timestamp] Code de statut: $($Response.StatusCode)" -ForegroundColor Yellow
            $IsHealthy = $false
        }
    }
    catch {
        Write-Host "[$Timestamp] Erreur: $($_.Exception.Message)" -ForegroundColor Red
        $IsHealthy = $false
        
        # Si pas de succes depuis plus de 10 minutes, considerer comme critique
        if (((Get-Date) - $LastSuccessTime).TotalMinutes -gt 10) {
            Write-Host "[$Timestamp] Aucun succes depuis plus de 10 minutes!" -ForegroundColor Red
        }
    }
    
    # Attendre l'intervalle configure
    Write-Host "   Attente de $IntervalMinutes minutes..." -ForegroundColor Gray
    Start-Sleep -Seconds ($IntervalMinutes * 60)
}