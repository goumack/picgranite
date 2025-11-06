# Script pour maintenir le modèle Ollama granite-code:3b actif
# Exécute une requête toutes les 2 minutes pour éviter que le modèle ne se mette en veille

# Configuration
$Uri = "https://ollamaaccel-chatbotaccel.apps.senum.heritage.africa/api/generate"
$Headers = @{"Content-Type" = "application/json"}
$Body = @{
    model = "granite-code:3b"
    prompt = "Bonjour"
    stream = $false
} | ConvertTo-Json

$IntervalMinutes = 2

Write-Host "=== Script Keep-Ollama-Alive ===" -ForegroundColor Green
Write-Host "Modèle: granite-code:3b" -ForegroundColor Yellow
Write-Host "Intervalle: $IntervalMinutes minutes" -ForegroundColor Yellow
Write-Host "URI: $Uri" -ForegroundColor Yellow
Write-Host "Appuyez sur Ctrl+C pour arrêter le script" -ForegroundColor Cyan
Write-Host ""

$RequestCount = 0

# Boucle infinie
while ($true) {
    try {
        $RequestCount++
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        Write-Host "[$Timestamp] Requête #$RequestCount - Envoi du ping..." -ForegroundColor White
        
        # Exécution de la requête
        $Response = Invoke-WebRequest -Uri $Uri -Method POST -Headers $Headers -Body $Body -TimeoutSec 30
        
        if ($Response.StatusCode -eq 200) {
            Write-Host "[$Timestamp] ✓ Succès - Modèle maintenu actif" -ForegroundColor Green
            
            # Optionnel: afficher une partie de la réponse
            $ResponseData = $Response.Content | ConvertFrom-Json
            if ($ResponseData.response) {
                $Preview = $ResponseData.response.Substring(0, [Math]::Min(50, $ResponseData.response.Length))
                Write-Host "   Réponse: $Preview..." -ForegroundColor Gray
            }
        } else {
            Write-Host "[$Timestamp] ⚠ Code de statut: $($Response.StatusCode)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[$Timestamp] ✗ Erreur: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Attendre 2 minutes
    Write-Host "   Attente de $IntervalMinutes minutes..." -ForegroundColor Gray
    Start-Sleep -Seconds ($IntervalMinutes * 60)
}