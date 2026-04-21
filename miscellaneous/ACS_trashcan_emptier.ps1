# On garde les param\Uffffffffes pour ignorer les certificats SSL si besoin
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# --- CONFIGURATION ---
$baseUrl = "http://127.0.0.1:8080/alfresco/api/-default-/public/alfresco/versions/1"
$username = "XXXXX"  
$password = "XXXXX"  
$maxItems = 500

$logFile = ".\Alfresco_Purge_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
# ---------------------

function Write-Log {
    param ( [string]$Message, [string]$Type = "INFO" )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$Type] $Message"
    
    switch ($Type) {
        "OK"    { Write-Host $logLine -ForegroundColor Green }
        "WARN"  { Write-Host $logLine -ForegroundColor Yellow }
        "ERROR" { Write-Host $logLine -ForegroundColor Red }
        Default { Write-Host $logLine -ForegroundColor Cyan }
    }
    Add-Content -Path $logFile -Value $logLine
}

Write-Log -Message "=== D\UffffffffUT DE LA SESSION DE PURGE (AVEC SAUT DES N\UffffffffUDS FANT\UffffffffES) ===" -Type "INFO"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))
$headers = @{
    Authorization = "Basic $base64AuthInfo"
    Accept        = "application/json"
}

$totalDeleted = 0
$currentSkip = 0
$consecutiveErrors = 0

do {
    # On utilise maintenant la variable $currentSkip qui va augmenter si on rencontre une erreur
    $getUrl = "$baseUrl/deleted-nodes?skipCount=$currentSkip&maxItems=$maxItems"
    Write-Log -Message "Tentative de GET sur : $getUrl" -Type "INFO"

    try {
        $response = Invoke-RestMethod -Uri $getUrl -Method Get -Headers $headers -TimeoutSec 600
        $entries = $response.list.entries

        if ($null -eq $entries -or $entries.Count -eq 0) {
            Write-Log -Message "La corbeille est vide (ou la fin de la liste est atteinte) !" -Type "OK"
            break 
        }

        Write-Log -Message "Nouveau lot trouv\Uffffffff $($entries.Count) n\Uffffffffuds. Suppression en cours..." -Type "WARN"

        $deletedInBatch = 0
        foreach ($item in $entries) {
            $nodeId = $item.entry.id
            $deleteUrl = "$baseUrl/deleted-nodes/$nodeId"

            try {
                Invoke-RestMethod -Uri $deleteUrl -Method Delete -Headers $headers
                Write-Log -Message "  [OK] N\Uffffffffud effac\Uffffffff $nodeId" -Type "OK"
                $totalDeleted++
                $deletedInBatch++
            }
            catch {
                Write-Log -Message "  [ERREUR] Impossible d'effacer le n\Uffffffffud $nodeId. D\Uffffffffils: $_" -Type "ERROR"
            }
        }

        # Si on a r\Uffffffffsi \Uffffffffupprimer des \Uffffffffments, on ne change PAS le skipCount.
        # Pourquoi ? Parce que les \Uffffffffments suivants vont "glisser" vers la gauche pour remplir le vide.
        # Mais si tout a \Uffffffffou\Uffffffffans ce lot, on avance pour ne pas bloquer.
        if ($deletedInBatch -eq 0) {
            $currentSkip += $maxItems
            Write-Log -Message "Aucun n\Uffffffffud purg\UffffffffOn avance le skipCount \UffffffffcurrentSkip." -Type "WARN"
        }

        $consecutiveErrors = 0 # On r\Uffffffffitialise le compteur d'erreurs
        Start-Sleep -Seconds 90 
    }
    catch {
        # C'EST ICI LA MAGIE
        Write-Log -Message "Erreur fatale sur le lot (Pr\Uffffffffnce de n\Uffffffffuds corrompus). D\Uffffffffils: $_" -Type "ERROR"
        
        # On saute ce lot de 50 \Uffffffffments "malades"
        $currentSkip += $maxItems
        $consecutiveErrors++
        
        Write-Log -Message "-> Lot ignor\UffffffffProchaine tentative \Uffffffffartir de l'\Uffffffffment $currentSkip..." -Type "WARN"

        # S\Uffffffffrit\Uffffffff si on a plus de 50 erreurs de suite, c'est que la corbeille est finie ou totalement corrompue
        if ($consecutiveErrors -ge 50) {
            Write-Log -Message "Trop d'erreurs cons\Ufffffffftives ($consecutiveErrors). Arr\Uffffffffdu script." -Type "ERROR"
            break
        }
    }

} while ($true)

Write-Log -Message "Script termin\UffffffffTotal g\Uffffffffral des n\Uffffffffuds effac\Uffffffff: $totalDeleted" -Type "INFO"
