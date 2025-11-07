# Test rapide de l'API ALEX avec 2 cycles
$AlexUri = "https://alex-route-alex-granitechatbot.apps.ocp.heritage.africa/chat"
$Messages = @(
    "Quels sont les services d'Accel Tech ?",
    "Comment puis-je vous aider aujourd'hui ?"
)

Write-Host "=== Test ALEX API ===" -ForegroundColor Green
Write-Host "URI: $AlexUri" -ForegroundColor Yellow
Write-Host ""

for ($i = 0; $i -lt 2; $i++) {
    try {
        $Message = $Messages[$i]
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        Write-Host "[$Timestamp] Test #$($i + 1) - Message: `"$Message`"" -ForegroundColor White
        
        # Preparer le body
        $Body = @{
            message = $Message
        } | ConvertTo-Json -Compress
        
        Write-Host "   Body JSON: $Body" -ForegroundColor Gray
        
        # Faire la requete
        $Response = Invoke-WebRequest -Uri $AlexUri -Method POST -Body $Body -ContentType "application/json" -TimeoutSec 30
        
        if ($Response.StatusCode -eq 200) {
            Write-Host "   Succes - Code 200" -ForegroundColor Green
            
            # Decoder la reponse
            $ResponseData = $Response.Content | ConvertFrom-Json
            if ($ResponseData.response) {
                $Preview = $ResponseData.response.Substring(0, [Math]::Min(150, $ResponseData.response.Length))
                Write-Host "   Reponse ALEX: $Preview..." -ForegroundColor Cyan
            } else {
                Write-Host "   Reponse brute: $($Response.Content)" -ForegroundColor Gray
            }
        } else {
            Write-Host "   Code: $($Response.StatusCode)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "   Erreur: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    if ($i -lt 1) {
        Write-Host "   Attente de 5 secondes..." -ForegroundColor Gray
        Start-Sleep -Seconds 5
    }
}

Write-Host "=== Test termine ===" -ForegroundColor Green