# Test simple du script Keep-Ollama-Alive
# Version de test avec seulement 2 requêtes

$Uri = "https://ollamaaccel-chatbotaccel.apps.senum.heritage.africa/api/generate"
$Headers = @{"Content-Type" = "application/json"}
$Body = @{
    model = "granite-code:3b"
    prompt = "Test de fonctionnement"
    stream = $false
} | ConvertTo-Json

Write-Host "=== Test Keep-Ollama-Alive ===" -ForegroundColor Green
Write-Host "URI: $Uri" -ForegroundColor Yellow
Write-Host "Test avec 2 requêtes espacées de 10 secondes" -ForegroundColor Cyan
Write-Host ""

for ($i = 1; $i -le 2; $i++) {
    try {
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$Timestamp] Test #$i - Envoi de la requête..." -ForegroundColor White
        
        $Response = Invoke-WebRequest -Uri $Uri -Method POST -Headers $Headers -Body $Body -TimeoutSec 30
        
        if ($Response.StatusCode -eq 200) {
            Write-Host "[$Timestamp] ✓ Succès - Code 200" -ForegroundColor Green
            
            # Afficher un aperçu de la réponse
            $ResponseData = $Response.Content | ConvertFrom-Json
            if ($ResponseData.response) {
                $Preview = $ResponseData.response.Substring(0, [Math]::Min(100, $ResponseData.response.Length))
                Write-Host "   Aperçu: $Preview..." -ForegroundColor Gray
            }
        } else {
            Write-Host "[$Timestamp] ⚠ Code de statut: $($Response.StatusCode)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[$Timestamp] ✗ Erreur: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    if ($i -lt 2) {
        Write-Host "   Attente de 10 secondes..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
    }
}

Write-Host ""
Write-Host "=== Test termine ===" -ForegroundColor Green