<#

Exchange DDL Attribute Sync On-Premises to Online
8/29/2018

Steps:
-Needs to be run from Exchange On-Premises Powershell Console
-Will connect to Exchange Online, enter creds for EXO when prompted
-Will go through each on-prem DDL and run the set-clouddynamicdistributiongroup cmdlet to make the changes Online

Attributes:
-Notes 1-1
-CustomAttribute3 1-1
-ManagedBy 1-1
-AcceptMessagesOnlyFrom Multival
-RejectMessagesFrom Multival


#>
Param(
  [boolean]$ReRun
)

if ($Rerun -ne $true)
{
    import-module activedirectory

    #Connect On Line
    $creds = get-credential
    $exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $creds -Authentication "Basic" -AllowRedirection
    Import-PSSession $exchangeSession -DisableNameChecking -Prefix Cloud
}

function GetSMTPAddress($CanName)
{
    return get-aduser -filter 'cn -eq $CanName' -properties * | select -ExpandProperty mail
}

$OnPremisesDDLs = Get-DynamicDistributionGroup

foreach ($OnPremiseDDL in $OnPremisesDDLs)
{
    write-host "STARTING: " $OnPremiseDDL
    #get on prem object
    $OnPremBuffer = Get-DynamicDistributionGroup $OnPremiseDDL.Name
    
    #set the online object for singles
    Set-CloudDynamicDistributionGroup $OnPremiseDDL.Name -Notes $OnPremBuffer.Notes -CustomAttribute3 $OnPremBuffer.CustomAttribute3

    #setup to run for multivalues
    if ($onPremBuffer.AcceptMessagesOnlyFrom -ne $null)
    {
        $AcceptBuffer = $onPremBuffer.AcceptMessagesOnlyFrom
        Write-host "BEGIN ACCEPT*************************************" 
        Write-host "Accept Buffer: " $acceptBuffer
        foreach ($acceptsingle in $AcceptBuffer)
        {
            #-AcceptMessagesOnlyFrom $OnPremBuffer.AcceptMessagesOnlyFrom
            #only grab right of last "/"
            $acceptSingleTempBuffer = $acceptsingle.tostring().Remove(0,$acceptsingle.tostring().LastIndexOf("/") + 1)
            $acceptSingleTempBuffer = GetSMTPAddress($acceptSingleTempBuffer)
            write-host "Accept Buffer PRE"  $acceptsingle
            write-host "Accept Buffer POST"  $acceptSingleTempBuffer
            set-CloudDynamicDistributionGroup -identity $OnPremiseDDL.Name -AcceptMessagesOnlyFrom @{Add=$acceptSingleTempBuffer}
        }
        Write-host "END ACCEPT*************************************" 
    }

    if ($OnPremBuffer.RejectMessagesFrom -ne $null)
    {
        $RejectBuffer = $OnPremBuffer.RejectMessagesFrom
        Write-host "BEGIN REJECT*************************************" 
        Write-host "RejectBuffer: " $rejectBuffer

        foreach ($rejectSingle in $RejectBuffer)
        {
            #-RejectMessagesFrom $OnPremBuffer.RejectMessagesFrom
            #only grab right of last "/"
            $rejectSingleTempBuffer = $rejectSingle.tostring().Remove(0,$rejectSingle.tostring().LastIndexOf("/") + 1)
            $rejectSingleTempBuffer = GetSMTPAddress($rejectSingleTempBuffer)
            write-host "Reject Buffer PRE" $rejectSingle
            write-host "Reject Buffer POST" $rejectSingleTempBuffer
            set-CloudDynamicDistributionGroup -identity $OnPremiseDDL.Name -RejectMessagesFrom @{Add=$rejectSingleTempBuffer}
        }
        Write-host "END REJECT*************************************" 
    }

    if ($OnPremBuffer.managedby -ne $null)
    {
        $ManagedByBuffer = $OnPremBuffer.managedby
        Write-host "BEGIN OWNER*************************************" 
        Write-host "Owner Buffer: " $ManagedByBuffer

        #only grab right of last "/"
        $ManagedBySingleTempBuffer = $ManagedByBuffer.tostring().Remove(0,$ManagedByBuffer.tostring().LastIndexOf("/") + 1)
        $ManagedBySingleTempBuffer = GetSMTPAddress($ManagedBySingleTempBuffer)
        write-host "ManagedBy Buffer PRE" $ManagedByBuffer
        write-host "ManagedBy Buffer POST" $ManagedBySingleTempBuffer
        set-CloudDynamicDistributionGroup -identity $OnPremiseDDL.Name -ManagedBy $ManagedBySingleTempBuffer

        Write-host "END OWNER*************************************" 
    }
}



