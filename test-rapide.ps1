# Version de test rapide - 3 cycles de 15 secondes
# Script pour maintenir le modele Ollama granite-code:3b actif

# Configuration
$Uri = "https://ollamaaccel-chatbotaccel.apps.senum.heritage.africa/api/generate"
$Headers = @{"Content-Type" = "application/json"}
$Body = @{
    model = "granite-code:3b"
    prompt = "Test rapide"
    stream = $false
} | ConvertTo-Json

$IntervalSeconds = 15  # Test avec 15 secondes au lieu de 2 minutes
$MaxTests = 3  # Seulement 3 tests

Write-Host "=== Test Rapide Keep-Ollama-Alive ===" -ForegroundColor Green
Write-Host "Modele: granite-code:3b" -ForegroundColor Yellow
Write-Host "Intervalle: $IntervalSeconds secondes" -ForegroundColor Yellow
Write-Host "Nombre de tests: $MaxTests" -ForegroundColor Yellow
Write-Host ""

$RequestCount = 0

while ($RequestCount -lt $MaxTests) {
    try {
        $RequestCount++
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        Write-Host "[$Timestamp] Test #$RequestCount/$MaxTests - Envoi du ping..." -ForegroundColor White
        
        # Execution de la requete
        $Response = Invoke-WebRequest -Uri $Uri -Method POST -Headers $Headers -Body $Body -TimeoutSec 30
        
        if ($Response.StatusCode -eq 200) {
            Write-Host "[$Timestamp] Succes - Code 200" -ForegroundColor Green
            
            # Afficher une partie de la reponse
            $ResponseData = $Response.Content | ConvertFrom-Json
            if ($ResponseData.response) {
                $Preview = $ResponseData.response.Substring(0, [Math]::Min(80, $ResponseData.response.Length))
                Write-Host "   Reponse: $Preview..." -ForegroundColor Gray
            }
        } else {
            Write-Host "[$Timestamp] Code de statut: $($Response.StatusCode)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[$Timestamp] Erreur: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Attendre seulement si ce n'est pas le dernier test
    if ($RequestCount -lt $MaxTests) {
        Write-Host "   Attente de $IntervalSeconds secondes..." -ForegroundColor Gray
        Start-Sleep -Seconds $IntervalSeconds
    }
}

Write-Host ""
Write-Host "=== Test rapide termine avec succes! ===" -ForegroundColor Green
Write-Host "Le script principal est pret pour le deploiement." -ForegroundColor Cyan