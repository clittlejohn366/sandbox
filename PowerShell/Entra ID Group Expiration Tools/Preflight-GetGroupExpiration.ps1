#*****************************************************************************************************
#
#     PREFLIGHT TOOL BEFORE TURNING IT ON
#     Get all groups by expiration date via PowerShell, AzureAD, and Exchange Online PowerShell
#        
#     Prior to run, need to log in with AzureAD and ExchangeOnline v2
#          Connect-ExchangeOnline
#          Import-Module AzureAD 
#          Connect-AzureAD
#
#*****************************************************************************************************

#$UserCred = get-credential -Message "Tenant Login" -UserName "admin@M365w897810.onmicrosoft.com"
#Connect-ExchangeOnline -UserPrincipalName $usercred.UserName
#Connect-AzureAD -Credential $UserCred

<#
Set Threshold Var
Read groups
compare created/renewed with Threshold Var
    Compare var = Renewed + threshold var
    If < today
        Then 
        Get owner
        write to screen/csv
    else if > today
        Then 
        no action


When not enabled ExpirationTime is null
AzureADMSGroup --- Created and Renewed are the same
No get-unified group
only get-azureadmsgroup

#>
#*******************************************BEGIN VARIABLES*******************************************

$CSVFileOutput =  "C:\temp\GroupExpirationChecks\GroupExport_Preflight_" + (Get-Date -format "yyyyMMdd-hhmmss") + ".csv"
$ExpirationThreshold = 14

#*******************************************END VARIABLES*********************************************

#*******************************************BEGIN FUNCTION********************************************

function GetGroupOwnerByObject {
    param ($InputGUID)

        if ($InputGUID -ne $null)
        {
            ForEach ($MangBy in $InputGUID)
            {
                #write-host "            Looking up:  " $MangBy
                $Buffer = Get-AzureADUser -ObjectId $mangby | select userprincipalname
                #write-host "            Buffer :  " $Buffer
                if ($buffer -ne $null)
                {
                    if ($ManagedByLookUp -eq "")
                    {$ManagedByLookUp = $Buffer.UserPrincipalName}
                    else
                    {$ManagedByLookUp = $ManagedByLookUp + ";" + $Buffer.UserPrincipalName}
                }
                else
                {
                    $ManagedByLookUp = "**LOOKUPFAILED**"
                }
            }
        }
        else
        {
            write-host "        **MANGBY NULL"
            $ManagedByLookUp = "**EMPTY**"
        }
    return $ManagedByLookUp
}

#*******************************************END FUNCTION********************************************


#*******************************************BEGIN MAIN**********************************************
Write-Host "*******************************************"
Write-Host "Pre-Flight Checks"
Write-Host "Finding NASA Microsoft 365 Groups to check..."
Write-Host "*******************************************"

$Noexpirecount = 0
$Expirecount = 0
$iGroupCountGlobal = 1

[array]$ExpirationPolicyGroups  = (Get-UnifiedGroup -ResultSize Unlimited | Select DisplayName, ExternalDirectoryObjectId, WhenCreated, ExpirationTime, ManagedBy)
If (!($ExpirationPolicyGroups)) { Write-Host "No groups found subject to the expiration policy - exiting" ; break }

Write-Host $ExpirationPolicyGroups.Count “groups found. Now checking expiration status.”
$Report = [System.Collections.Generic.List[Object]]::new(); $Today = (Get-Date)

ForEach ($G in $ExpirationPolicyGroups) 
    {
        write-host "     " $iGroupCountGlobal " - Group: " $G.DisplayName
        #$LastRenewed = (Get-AzureADMSGroup -Id $G.ExternalDirectoryObjectId).RenewedDateTime
        $CurrentAge = (New-TimeSpan -Start $G.WhenCreated -End $Today).Days  # Age of group

        [datetime]$DateCreated = $G.WhenCreated     
        $WouldExpireOn = $DateCreated.AddDays($ExpirationThreshold)
        $DaysLeft = ($ExpirationThreshold - $CurrentAge)

        if ($CurrentAge -gt $ExpirationThreshold)    #Expiring
        {
            write-host "    Expires -- " $G.DisplayName
            $Expirecount ++
            $ExpireResult = $true
        }
        else    #Not expiring
        {
            write-host "    No expire -- " $G.DisplayName
            $Noexpirecount ++
            $ExpireResult = $false
        }

        write-host "     RAW ManagedBy: " $G.ManagedBy
        $ManagedByLookUp = GetGroupOwnerByObject $G.ManagedBy
        $ManagedByRaw = $g | Select-object @{name="ManagedByRaw";expression={$_.ManagedBy -join ";"}}
 
        $ReportLine = [PSCustomObject]@{
            Group           = $G.DisplayName
            DateCreated         = $DateCreated
            CurrentAge      = $CurrentAge
            ExpirationThreshold       = $ExpirationThreshold
            ExpireResult    = $ExpireResult
            WouldExpireOn   = $WouldExpireOn
            DaysLeft        = $DaysLeft
            ManagedBy       = $ManagedByLookUp
            ManagedByRaw    = $ManagedByRaw.managedbyRaw
        }
        $Report.Add($ReportLine)
        $ManagedByLookUp = ""
        $ManagedByRaw = ""
        $ExpireResult = ""
        $iGroupCountGlobal ++
}

Write-Host ""
Write-Host "Total Microsoft 365 Groups covered by expiration policy:" $ExpirationPolicyGroups.Count
Write-host "    Expire Count:  " $Expirecount
Write-host "    Non Expiring Count:  " $Noexpirecount
Write-Host ""

$Report | Sort DaysLeft | Select Group, DateCreated, CurrentAge, ExpireResult, ExpirationThreshold, WouldExpireOn, DaysLeft, ManagedByRaw, ManagedBy | ft
$Report | export-csv $CSVFileOutput -NoTypeInformation

Write-host -ForegroundColor Green "CSV file output saved to:  " $CSVFileOutput

#*******************************************END MAIN************************************************


