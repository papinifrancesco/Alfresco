<#
.SYNOPSIS
    Synchronizes a single Alfresco group or dumps all groups from two servers for comparison.
.DESCRIPTION
    Run in 'Sync' mode (default) to sync a single group using -GroupName. Use the optional -Mirror switch to also remove extra members from the destination.
    Run in 'Compare' mode using -Compare to dump all groups and members from both servers to JSON files.
#>
[CmdletBinding(DefaultParameterSetName='Sync')]
param (
    # Parameters for the 'Sync' mode
    [Parameter(Mandatory = $true, ParameterSetName = 'Sync', HelpMessage = 'The name of the single group to synchronize.')]
    [string]$GroupName,

    [Parameter(ParameterSetName = 'Sync', HelpMessage = 'Simulate the sync without making changes and create a report.')]
    [switch]$Simulate,

    [Parameter(ParameterSetName = 'Sync', HelpMessage = 'Perform a mirror sync, removing extra members from the destination.')]
    [switch]$Mirror,

    # Parameter for the 'Compare' mode
    [Parameter(Mandatory = $true, ParameterSetName = 'Compare', HelpMessage = 'Switch to dump all groups from both servers to JSON files.')]
    [switch]$Compare
)

#region Configuration
# ------------------------------------------------------------------
$SourceAlfrescoHost      = "10.28.17.1"
$DestinationAlfrescoHost = "10.28.17.4"
$username                = "admin"
$password                = "1lWh6UIEJEx0AnaWEynX"
$reportFile              = ".\AlfrescoSyncReport.log" # For -Simulate mode
$sourceOutputFile        = ".\Groups1.json"         # For -Compare mode
$destinationOutputFile   = ".\Groups2.json"         # For -Compare mode
# ------------------------------------------------------------------

# Manually prepare the 'Authorization' header
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))
$headers = @{ "Authorization" = "Basic $base64AuthInfo" }
#endregion


#region Helper Functions
function Get-AllAlfrescoGroups {
    [CmdletBinding()]
    param(
        [string]$ServerAddress,
        [hashtable]$Headers
    )
    $allGroups = [System.Collections.Generic.List[PSObject]]::new()
    $skipCount = 0
    $hasMoreItems = $true

    do {
        $apiUrl = "http://$($ServerAddress):8080/alfresco/api/-default-/public/alfresco/versions/1/groups?skipCount=$skipCount&maxItems=100"
        try {
            Write-Host "[API CALL] GET: $apiUrl" -ForegroundColor DarkCyan
            $webResponse = Invoke-WebRequest -Uri $apiUrl -Method Get -Headers $Headers -UseBasicParsing
            $response = $webResponse.Content | ConvertFrom-Json
            
            if ($null -ne $response.list.entries) {
                $response.list.entries | ForEach-Object { $allGroups.Add($_.entry) }
            }
            $hasMoreItems = $response.list.pagination.hasMoreItems
            $skipCount += $response.list.pagination.count
        }
        catch {
            Write-Error "FATAL: Could not retrieve group list from '$($ServerAddress)'. Error: $($_.Exception.Message)"
            return $null
        }
    } while ($hasMoreItems)
    return $allGroups
}

function Get-AlfrescoGroupMembers {
    [CmdletBinding()]
    param (
        [string]$ServerAddress,
        [string]$GroupId,
        [hashtable]$Headers,
        [switch]$Simulate
    )
    $allMembers = [System.Collections.Generic.List[PSObject]]::new()
    $skipCount = 0
    $hasMoreItems = $true

    do {
        $apiUrl = "http://$($ServerAddress):8080/alfresco/api/-default-/public/alfresco/versions/1/groups/$($GroupId)/members?skipCount=$skipCount&maxItems=100&fields=id,memberType"
        try {
            Write-Host "[API CALL] GET: $apiUrl" -ForegroundColor Cyan
            $webResponse = Invoke-WebRequest -Uri $apiUrl -Method Get -Headers $Headers -UseBasicParsing
            $response = $webResponse.Content | ConvertFrom-Json

            if ($null -ne $response.list.entries) {
                $response.list.entries | ForEach-Object { $allMembers.Add($_.entry) }
            }
            $hasMoreItems = $response.list.pagination.hasMoreItems
            $skipCount += $response.list.pagination.count
        }
        catch {
            Write-Error "Failed to get members for group '$($GroupId)' from '$($ServerAddress)'. Full Error: $($_.Exception.ToString())"
            if ($Simulate.IsPresent) { return [System.Collections.Generic.List[PSObject]]::new() }
            else {
                $webException = $_.Exception.GetBaseException()
                if ($webException -is [System.Net.WebException] -and $webException.Response -ne $null -and [int]$webException.Response.StatusCode -eq 404) {
                    return [System.Collections.Generic.List[PSObject]]::new()
                }
                return $null
            }
        }
    } while ($hasMoreItems)

    foreach ($member in $allMembers) {
        if ($member.memberType -eq 'GROUP' -and -not $member.id.StartsWith('GROUP_', [System.StringComparison]::OrdinalIgnoreCase)) {
            $member.id = "GROUP_$($member.id)"
        }
    }
    return $allMembers
}

function Add-AlfrescoGroupMember {
    [CmdletBinding()]
    param (
        [string]$ServerAddress,
        [string]$GroupId,
        [PSObject]$MemberToAdd,
        [hashtable]$Headers,
        [switch]$Simulate
    )
    $apiUrl = "http://$($ServerAddress):8080/alfresco/api/-default-/public/alfresco/versions/1/groups/$($GroupId)/members"
    if ($Simulate.IsPresent) {
        Write-Host "[API CALL] SIMULATED POST: $apiUrl" -ForegroundColor Cyan
        Write-Host "[SIMULATE] - Would add $($MemberToAdd.memberType) '$($MemberToAdd.id)'" -ForegroundColor Yellow
        return 
    }
    $body = @{ id = $MemberToAdd.id; memberType = $MemberToAdd.memberType } | ConvertTo-Json
    try {
        Write-Host "[API CALL] POST: $apiUrl" -ForegroundColor Cyan
        Invoke-WebRequest -Uri $apiUrl -Method Post -Headers $Headers -Body $body -ContentType 'application/json' -UseBasicParsing | Out-Null
        Write-Host "[SUCCESS] Added $($MemberToAdd.memberType) '$($MemberToAdd.id)' to group '$($GroupId)' on '$($ServerAddress)'." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to add member '$($MemberToAdd.id)' to group '$($ServerAddress)'. Full Error: $($_.Exception.ToString())"
    }
}

function Remove-AlfrescoGroupMember {
    [CmdletBinding()]
    param (
        [string]$ServerAddress,
        [string]$GroupId,
        [PSObject]$MemberToRemove,
        [hashtable]$Headers,
        [switch]$Simulate
    )
    $encodedMemberId = [System.Web.HttpUtility]::UrlEncode($MemberToRemove.id)
    $apiUrl = "http://$($ServerAddress):8080/alfresco/api/-default-/public/alfresco/versions/1/groups/$($GroupId)/members/$($encodedMemberId)"

    if ($Simulate.IsPresent) {
        Write-Host "[API CALL] SIMULATED DELETE: $apiUrl" -ForegroundColor DarkYellow
        Write-Host "[SIMULATE] - Would remove $($MemberToRemove.memberType) '$($MemberToRemove.id)'" -ForegroundColor DarkYellow
        return
    }
    try {
        Write-Host "[API CALL] DELETE: $apiUrl" -ForegroundColor DarkYellow
        Invoke-WebRequest -Uri $apiUrl -Method Delete -Headers $Headers -UseBasicParsing | Out-Null
        Write-Host "[SUCCESS] Removed $($MemberToRemove.memberType) '$($MemberToRemove.id)' from group '$($GroupId)' on '$($ServerAddress)'." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to remove member '$($MemberToRemove.id)' from group '$($GroupId)' on '$($ServerAddress)'. Full Error: $($_.Exception.ToString())"
    }
}

function Export-AllGroupData {
    [CmdletBinding()]
    param (
        [string]$ServerAddress,
        [hashtable]$Headers
    )
    Write-Host "`nFetching list of all groups from '$($ServerAddress)'..." -ForegroundColor White
    $allGroups = Get-AllAlfrescoGroups -ServerAddress $ServerAddress -Headers $Headers
    if ($null -eq $allGroups) { return $null }
    
    Write-Host "Found $($allGroups.Count) groups. Now fetching members for each..."
    $fullReport = [System.Collections.Generic.List[object]]::new()
    $progress = 0

    foreach ($group in $allGroups) {
        $progress++
        Write-Progress -Activity "Fetching Group Members on $ServerAddress" -Status "Processing group $progress of $($allGroups.Count): $($group.id)" -PercentComplete (($progress / $allGroups.Count) * 100)
        
        $groupMembers = Get-AlfrescoGroupMembers -ServerAddress $ServerAddress -GroupId $group.id -Headers $Headers
        
        $groupData = @{
            groupId     = $group.id
            displayName = $group.displayName
            members     = $groupMembers
        }
        $fullReport.Add($groupData)
    }
    return $fullReport
}
#endregion

# --- Script Execution ---
[System.Net.WebRequest]::DefaultWebProxy = $null

# Mode 1: Dump all groups for comparison
if ($PSCmdlet.ParameterSetName -eq 'Compare') {
    Write-Host "--- COMPARE MODE ---" -ForegroundColor Green
    $sourceData = Export-AllGroupData -ServerAddress $SourceAlfrescoHost -Headers $headers
    if ($sourceData) {
        $sourceData | ConvertTo-Json -Depth 10 | Out-File -FilePath $sourceOutputFile -Encoding utf8
        Write-Host "`nSUCCESS: Source server data dumped to '$($sourceOutputFile)'" -ForegroundColor Green
    }
    $destinationData = Export-AllGroupData -ServerAddress $DestinationAlfrescoHost -Headers $headers
    if ($destinationData) {
        $destinationData | ConvertTo-Json -Depth 10 | Out-File -FilePath $destinationOutputFile -Encoding utf8
        Write-Host "SUCCESS: Destination server data dumped to '$($destinationOutputFile)'" -ForegroundColor Green
    }
    Write-Host "`nComparison dump complete."
}
# Mode 2: Sync a single group
elseif ($PSCmdlet.ParameterSetName -eq 'Sync') {
    if ($Simulate.IsPresent) {
        Write-Host "`n--- SIMULATION MODE ENABLED ---" -ForegroundColor Yellow
        Write-Host "All console output will be redirected to: $reportFile`n" -ForegroundColor Yellow
        Start-Transcript -Path $reportFile -Force
    }
    try {
        Write-Host "--- Starting Group Sync ---"; Write-Host "Run started: $(Get-Date)"; Write-Host "Group Name: $GroupName"; Write-Host "---------------------------`n"
        if ($Mirror.IsPresent) { Write-Host "MIRROR MODE is enabled." -ForegroundColor Magenta }
        $fullGroupName = "GROUP_$($GroupName)"
        
        Write-Host "Fetching members from source: $($SourceAlfrescoHost)..."
        $sourceMembers = @(Get-AlfrescoGroupMembers -ServerAddress $SourceAlfrescoHost -GroupId $fullGroupName -Headers $headers -Simulate:$Simulate)
        if ($null -eq $sourceMembers) { throw "Halting script due to critical error fetching source members." }
        Write-Host "Found $($sourceMembers.Count) members on source."; Write-Host "Source Members:"; $sourceMembers | ForEach-Object { Write-Host " - $($_.memberType): $($_.id)" }; Write-Host ""
        
        Write-Host "Fetching members from destination: $($DestinationAlfrescoHost)..."
        $destinationMembers = @(Get-AlfrescoGroupMembers -ServerAddress $DestinationAlfrescoHost -GroupId $fullGroupName -Headers $headers -Simulate:$Simulate)
        if ($null -eq $destinationMembers) { throw "Halting script due to critical error fetching destination members." }
        Write-Host "Found $($destinationMembers.Count) members on destination."; Write-Host "Destination Members:"
        if ($destinationMembers.Count -gt 0) { $destinationMembers | ForEach-Object { Write-Host " - $($_.memberType): $($_.id)" } } else { Write-Host " (No members found)" }; Write-Host ""
        
        # ## CORRECTED ##: Replaced both comparison one-liners with verbose, explicit loops for maximum reliability.
        
        # 1. Calculate members to ADD
        Write-Host "`n--- Verifying members for Addition (Verbose) ---" -ForegroundColor Cyan
        $membersToAdd = @()
        $destinationMemberIdsSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($member in $destinationMembers) { $destinationMemberIdsSet.Add($member.id) | Out-Null }

        foreach ($sourceMember in $sourceMembers) {
            Write-Host "[DEBUG] Checking Source Member [ID: $($sourceMember.id)]..." -NoNewline
            if ($destinationMemberIdsSet.Contains($sourceMember.id)) {
                Write-Host " Found in destination. Action: IGNORE." -ForegroundColor Gray
            } else {
                Write-Host " NOT found in destination. Action: ADD." -ForegroundColor Green
                $membersToAdd += $sourceMember
            }
        }
        
        # 2. Calculate members to REMOVE (only in Mirror mode)
        $membersToRemove = @()
        if ($Mirror.IsPresent) {
            Write-Host "`n--- Verifying members for Mirror Mode (Verbose) ---" -ForegroundColor Cyan
            $sourceIdArray = @($sourceMembers.id)
            
            foreach ($destMember in $destinationMembers) {
                $isFoundInSource = $false
                foreach ($sourceId in $sourceIdArray) {
                    if ($sourceId.Equals($destMember.id, [System.StringComparison]::OrdinalIgnoreCase)) {
                        $isFoundInSource = $true
                        break
                    }
                }
                
                Write-Host "[DEBUG] Checking Destination Member [ID: $($destMember.id)]..." -NoNewline
                if ($isFoundInSource) {
                    Write-Host " Found in source. Action: KEEP." -ForegroundColor Gray
                } else {
                    Write-Host " NOT found in source. Action: REMOVE." -ForegroundColor Red
                    $membersToRemove += $destMember
                }
            }
        }

        # Process actions
        if ($membersToAdd.Count -eq 0 -and $membersToRemove.Count -eq 0) {
            Write-Host "`n--- No Actions Needed ---"; Write-Host "Destination group is already up-to-date."
        } else {
            if ($membersToAdd.Count -gt 0) {
                Write-Host "`n--- Proposed Actions (Additions) ---"
                foreach ($member in $membersToAdd) { Add-AlfrescoGroupMember -ServerAddress $DestinationAlfrescoHost -GroupId $fullGroupName -MemberToAdd $member -Headers $headers -Simulate:$Simulate }
            }
            if ($membersToRemove.Count -gt 0) {
                Write-Host "`n--- Proposed Actions (Removals) ---"
                foreach ($member in $membersToRemove) { Remove-AlfrescoGroupMember -ServerAddress $DestinationAlfrescoHost -GroupId $fullGroupName -MemberToRemove $member -Headers $headers -Simulate:$Simulate }
            }
        }
    }
    catch {
        Write-Error "A fatal error occurred in the main script body: $($_.ToString())"
    }
    finally {
        if ($Simulate.IsPresent) {
            Write-Host "`n---------------------------"; Write-Host "Run finished: $(Get-Date)"; Stop-Transcript
            Write-Host "`n--- Simulation Complete. Report saved to '$reportFile' ---" -ForegroundColor Green
        } else {
            Write-Host "`n--- Group Sync Complete ---"
        }
    }
}
