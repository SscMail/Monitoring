#ProgressPreference = "SilentlyContinue"
#Install-Module -Name Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser
#exit 
param(
    [Parameter(Mandatory = $true)]
    [string] $tenantName,
    [Parameter(Mandatory = $false, HelpMessage="Use MSI to upload to MSI bloob. Leave blank for 163Dev")]
    [string] $storageEnvironment =""
)


function OMSLog {
    [CmdletBinding()]
    param (
        [string]
        $Status,
        [string]
        $StatusDescription,  
        [string] 
        $Tenant
    )
    $obj = [pscustomobject][ordered]@{
        Status            = $Status
        JobDetails       = "Liscencing Report"
        StatusDescription = $StatusDescription
        FireDateTime      = Get-Date
        JobType          = "Licencing"
        Category      = "Reports"
        JobId             = $jobid
        Tenant            = $Tenant
    }
    $JSON = $obj | ConvertTo-Json -Depth 10
    Send-OMSAPIIngestionFile -customerId $OMSWorkspaceId -sharedKey $OMSSharedKey -body $JSON -logType "ReportsLog" -Verbose
}


function Log($val) {
    $date = Get-Date
    if($MemLog){
        $Ram =(Get-Counter '\Memory\Available MBytes')[0].CounterSamples.CookedValue
    }
    if($Debug){
        Write-Output "$date : `t $Ram MB: `t$val"
    }
}

function Upload-Blob-Files {
    param (
        [string] $FilePath,
        [System.Collections.ArrayList] $FileNames,
        [string] $Directory,
        [string] $Url,
        [string] $ContainerName

    )
    try{
        $ctx = New-AzStorageContext -ConnectionString $Url
        foreach($fileName in $FileNames){
            Log "Uploading file $FileName..."
            # upload a file to the default account (inferred) access tier
            $Blob1HT = @{
                File      = ($FilePath + $FileName)
                Container = $ContainerName
                Blob      = ($Directory + $FileName)
                Context   = $ctx
            }
            $result = Set-AzStorageBlobContent @Blob1HT 
            Remove-Item ($FilePath + $FileName)

        }
    } Catch{
        $error ="Unable to upload files $FileNames . Errors: $_"
        Log $error
        Throw $error
    }

}

function Upload-Blob-File {
    param (
        [string] $FilePath,
        [string] $FileName,
        [string] $Directory,
        [string] $Url,
        [string] $ContainerName

    )
    $ctx = New-AzStorageContext -ConnectionString $Url

    Log "Uploading file $FileName..."
    # upload a file to the default account (inferred) access tier
    $Blob1HT = @{
        File      = ($FilePath + $FileName)
        Container = $ContainerName
        Blob      = ($Directory + $FileName)
        Context   = $ctx
    }
    $result = Set-AzStorageBlobContent @Blob1HT 
    Remove-Item ($FilePath + $FileName)
  
}

Import-Module MSAL.PS
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Users

######## Runbook configuration ##############
$MemLog = $false
$Debug = $false
$ErrorActionPreference = "Stop"

# Number of entries to be returned by each graph users call. 
# maximum number is 999 
$pageSize = 999
######## END Runbook configuration ##############

#--- Get Log Analytics authentication info from variables ---#
$OMSWorkspaceId = Get-AutomationVariable -Name 'OMSWorkSpaceID'
$OMSSharedKey = Get-AutomationVariable -Name 'OMSPrimaryKey'
$jobid = $PSPrivateMetadata.JobId.Guid

$tenantID = Get-AutomationVariable -Name ($tenantName + 'TenantID');
$clientID = Get-AutomationVariable -Name ($tenantName + 'ClientID');
$secureClientSecret = (Get-AutomationVariable -Name ($tenantName + 'ClientSecret')) | ConvertTo-SecureString -AsPlainText -Force;

try{
    
    $token = Get-MsalToken -clientID $clientID -clientSecret $secureClientSecret -tenantID $tenantID
    $accessToken = $token.AccessToken
} Catch{
    $status ="fail"
    $TransMsg = "FAILED due to authentication while processing Licenses Report for $tenantName reason: $_"
    OMSLog -Status $status -StatusDescription $TransMsg -Tenant $tenantName
    Log $TransMsg
    $continue = $false
    Throw $TransMsg
}
$header = @{"Authorization" = "Bearer $accessToken"; "Content-Type" = "application/json" };

$path = ($env:TEMP + "\")
$dateString = Get-Date -Format "MM-dd-yyyy_HH-mm"
$fileNameSufix = "_" + $tenantName + "_" + $dateString + ".csv"

$storageAccountURLVariableName = $Env +'MonitoringStorageAccountURL'
$storageAccountContainerVariableName = $Env +'MonitoringStorageAccountContainerName'
$FileDirectoryVariableName = 'StorageAccountReportsDirectory'  

$Url = Get-AutomationVariable -Name $storageAccountURLVariableName 
$ContainerName = Get-AutomationVariable -Name $storageAccountContainerVariableName 
$Directory = Get-AutomationVariable -Name $FileDirectoryVariableName
$fileNamesToUpload = [System.Collections.ArrayList]@()
Log "############## Processing License Summary for Tenant $tenantName ###############"

$AggregateFileName = "Licences$fileNameSufix"
$ServicePlansFileName = "Licence_ServicePlans$fileNameSufix"
$PrepaidUnitsFilename = "Licence_PrepaidUnits$fileNameSufix"

try {
    
    Log "Connecting to graph..."
    $graphConnectResults = Connect-MgGraph -AccessToken $accessToken 
    Select-MgProfile beta
        
    ##############################################################
    ###     Get Aggregate SKU Data and upload to Blob storage ####
    ##############################################################
    Log "Calling Get-MgSubscribedSku..."
    $AggregateData = Get-MgSubscribedSku -All  | select CapabilityStatus, Id, ServicePlans, SkuId, SkuPartNumber, ConsumedUnits, PrepaidUnits

    $ServicePlans = [System.Collections.ArrayList]@()
    $PrepaidUnits = [System.Collections.ArrayList]@()

    foreach ($aggregateEntry in $AggregateData) {
        $aggregateEntry | Add-Member -NotePropertyName TenantID -NotePropertyValue $TenantID
        foreach ($servicePlan in $aggregateEntry.ServicePlans) {
            [PSObject] $entry = [PSCustomObject] @{
                TenantID                       = $tenantID
                Id                             = $aggregateEntry.Id
                SkuId                          = $aggregateEntry.SkuId
                SkuPartNumber                  = $aggregateEntry.SkuPartNumber
                ServicePlan_AppliesTo          = $servicePlan.AppliesTo
                ServicePlan_ProvisioningStatus = $servicePlan.ProvisioningStatus
                ServicePlan_ServicePlanId      = $servicePlan.ServicePlanId
                ServicePlan_ServicePlanName    = $servicePlan.ServicePlanName
            }    
            [void]$ServicePlans.Add($entry)
        }
        foreach ($prepaidUnit in $aggregateEntry.PrepaidUnits) {
            [PSObject] $entry = [PSCustomObject] @{
                TenantID              = $tenantID
                Id                    = $aggregateEntry.Id
                SkuId                 = $aggregateEntry.SkuId
                SkuPartNumber         = $aggregateEntry.SkuPartNumber
                PrepaidUnit_Enabled   = $prepaidUnit.Enabled 
                PrepaidUnit_Suspended = $prepaidUnit.Suspended
                PrepaidUnit_Warning   = $prepaidUnit.Warning
            }    
            [void]$PrepaidUnits.Add($entry)
        }
    }

    Log "Exporting $AggregateFileName..."
    $AggregateData | select tenantID, CapabilityStatus, Id, SkuId, SkuPartNumber, ConsumedUnits | Export-Csv -Path ($path + $AggregateFileName) -NoTypeInformation  
    [void] $fileNamesToUpload.Add($AggregateFileName)
    #Upload-Blob-File -FileName $AggregateFileName -FilePath  $path -Directory $Directory -Url $Url -ContainerName $ContainerName
      
    Log "Exporting $ServicePlansFileName..."
    $ServicePlans | Export-Csv -Path ($path + $ServicePlansFileName) -NoTypeInformation  
    [void] $fileNamesToUpload.Add($ServicePlansFileName)
    #Upload-Blob-File -FileName $ServicePlansFileName  -FilePath  $path -Directory $Directory -Url $Url -ContainerName $ContainerName
   
    Log "Exporting $PrepaidUnitsFilename..."
    $PrepaidUnits | Export-Csv -Path ($path + $PrepaidUnitsFilename) -NoTypeInformation  
    [void] $fileNamesToUpload.Add($PrepaidUnitsFilename)
    #Upload-Blob-File -FileName $PrepaidUnitsFilename  -FilePath  $path -Directory $Directory -Url $Url -ContainerName $ContainerName
        
    Log "Clearing Licences variables..."
    Clear-Variable -Name "ServicePlans" -Scope Global
    Clear-Variable -Name "PrepaidUnits" -Scope Global
    Clear-Variable -Name "AggregateData" -Scope Global

    Log "Calling Garbage Collection"
    [GC]::Collect()
    $continue =$true
}
Catch {
    $status ="fail"
    $TransMsg = "FAILED processing Licenses Report for $tenantName reason: $_"
    OMSLog -Status $status -StatusDescription $TransMsg -Tenant $tenantName
    Log $TransMsg
    $continue = $false
    Throw $TransMsg
}
Finally {
    $disconnectResults = Disconnect-MgGraph
     
}
# content of this block should never get to execute 
if($continue -eq $false){
    Throw $TransMsg
    exit; 

}

Log "############## Processing User Licenses for Tenant $tenantName ###############"

$UserFileName = "User$fileNameSufix"
$UserLicenseAssignmentStatesFileName = "User_LicenseAssignmentStates$fileNameSufix"
$UserLicenseAssignmentStatesDisabledPlansFileName = "User_DisabledPlans_LicenseAssignmentStates$fileNameSufix"
$UserProvisionedPlansFileName = "User_ProvisionedPlans$fileNameSufix"
$UserAssignedLicensesFileName = "User_AssignedLicenses$fileNameSufix"
$UserAssignedPlansFileName = "User_AssignedPlans$fileNameSufix"
$batch = 0
$actualUserCount = 0

$apiUrlPart1 = 'https://graph.microsoft.com/v1.0/users?$count=true'
$apiUrlPart2 = '&$top=' + $pageSize 
$apiUrlPart3 = '&$select=CreatedDateTime,AccountEnabled,AssignedLicenses,AssignedPlans,Id,LicenseAssignmentStates,LicenseDetails,ProvisionedPlans,UserType'
$UserNextLink = $apiUrlPart1 + $apiUrlPart2 + $apiUrlPart3 

Try {
    do {
        $batch += 1
        $UserLicenseAssignmentStates = [System.Collections.ArrayList]@()
        $UserProvisionedPlans = [System.Collections.ArrayList]@()
        $UserAssignedLicenses = [System.Collections.ArrayList]@() 
        $UserAssignedPlans = [System.Collections.ArrayList]@()
        $UserLicenseAssignmentStatesDisabledPlans = [System.Collections.ArrayList]@()
      
        Log "Calling $UserNextLink"
        $UserResponse = (Invoke-RestMethod -Uri $UserNextLink -Headers $header -Method Get)
        Log ("Api call complete with # of entries: " + $UserResponse.value.count)    
        $UserNextLink = $UserResponse."@odata.nextLink"
        $users = $UserResponse.value
            
        $bartchUserCount = $UserResponse.value.count 
        $actualUserCount += $users.length
        Log "Number of users returned: $bartchUserCount for batch $batch with accumulative count $actualUserCount"
        Log "Processing Users..."
        foreach ($user in $users) {
            $user | Add-Member -NotePropertyName TenantID -NotePropertyValue $TenantID
            foreach ($LicenseAssignmentState in $user.LicenseAssignmentStates) {
                [PSObject] $entry = [PSCustomObject] @{
                    TenantID            = $tenantID
                    UserId              = $user.Id
                    AssignedByGroup     = $LicenseAssignmentState.AssignedByGroup        
                    Error               = $LicenseAssignmentState.Error               
                    LastUpdatedDateTime = $LicenseAssignmentState.LastUpdatedDateTime  
                    SkuId               = $LicenseAssignmentState.SkuId               
                    State               = $LicenseAssignmentState.State
                }    
                [void]$UserLicenseAssignmentStates.Add($entry)
                        
                foreach ($DisabledPlan in $LicenseAssignmentState.DisabledPlans) {
                    [PSObject] $DisabledPlanEntry = [PSCustomObject] @{
                        TenantID     = $tenantID
                        UserId       = $user.Id
                        SkuId        = $LicenseAssignmentState.SkuId   
                        DisabledPlan = $DisabledPlan
                    }
                    [void]$UserLicenseAssignmentStatesDisabledPlans.Add($DisabledPlanEntry)
                }
            }

            foreach ($ProvisionedPlan in $user.ProvisionedPlans) {
                [PSObject] $entry = [PSCustomObject] @{
                    TenantID           = $tenantID
                    UserId             = $user.Id
                    CapabilityStatus   = $ProvisionedPlan.CapabilityStatus 
                    ProvisioningStatus = $ProvisionedPlan.ProvisioningStatus 
                    Service            = $ProvisionedPlan.Service    
                }    

                [void]$UserProvisionedPlans.Add($entry)
            }
       
            foreach ($AssignedLicense in $user.AssignedLicenses) {
                [PSObject] $entry = [PSCustomObject] @{
                    TenantID      = $tenantID
                    UserId        = $user.Id
                    DisabledPlans = $AssignedLicense.DisabledPlans 
                    SkuId         = $AssignedLicense.SkuId                                     
                }    
                [void]$UserAssignedLicenses.Add($entry)
            }

            foreach ($AssignedPlan in $user.AssignedPlans) {
                [PSObject] $entry = [PSCustomObject] @{
                    TenantID         = $tenantID
                    UserId           = $user.Id
                    AssignedDateTime = $AssignedPlan.AssignedDateTime
                    CapabilityStatus = $AssignedPlan.CapabilityStatus
                    Service          = $AssignedPlan.Service
                    ServicePlanId    = $AssignedPlan.ServicePlanId
                }    
                [void]$UserAssignedPlans.Add($entry)
            }
        }
            
        Log "Exporting for batch $batch  $UserFileName..." 
        $users | Select-Object TenantID, Id, CreatedDateTime, AccountEnabled, UserType | Export-Csv -Append -Path ($path + $UserFileName) -NoTypeInformation 
        Log "Clearing User variable users..."
        Clear-Variable -Name "users" -Scope Global
        Log "Calling Garbage Collection"
        [GC]::Collect()

        Log "Exporting for batch $batch  $UserLicenseAssignmentStatesFileName..."
        $UserLicenseAssignmentStates | Export-Csv -Append -Path ($path + $UserLicenseAssignmentStatesFileName) -NoTypeInformation  
        Log "Clearing User variable UserLicenseAssignmentStates..."
        Clear-Variable -Name "UserLicenseAssignmentStates" -Scope Global
        Log "Calling Garbage Collection"
        [GC]::Collect()

        Log "Exporting for batch $batch  $UserLicenseAssignmentStatesDisabledPlansFileName..."
        $UserLicenseAssignmentStatesDisabledPlans | Export-Csv -Append -Path ($path + $UserLicenseAssignmentStatesDisabledPlansFileName) -NoTypeInformation  
        Log "Clearing User variable UserLicenseAssignmentStatesDisabledPlans..."
        Clear-Variable -Name "UserLicenseAssignmentStatesDisabledPlans" -Scope Global
        Log "Calling Garbage Collection"
        [GC]::Collect()

        Log "Exporting for batch $batch  $UserProvisionedPlansFileName..."
        $UserProvisionedPlans | Export-Csv -Append -Path ($path + $UserProvisionedPlansFileName) -NoTypeInformation  
        Log "Clearing User variable UserProvisionedPlans..."
        Clear-Variable -Name "UserProvisionedPlans" -Scope Global
        Log "Calling Garbage Collection"
        [GC]::Collect()

        Log "Exporting for batch $batch  $UserAssignedLicensesFileName..."
        $UserAssignedLicenses | Export-Csv -Append -Path ($path + $UserAssignedLicensesFileName) -NoTypeInformation  
        Log "Clearing User variable UserAssignedLicenses..."
        Clear-Variable -Name "UserAssignedLicenses" -Scope Global
        Log "Calling Garbage Collection"
        [GC]::Collect()

        Log "Exporting for batch $batch  $UserAssignedPlansFileName..."
        $UserAssignedPlans | Export-Csv -Append -Path ($path + $UserAssignedPlansFileName) -NoTypeInformation 
        Log "Clearing User variable UserAssignedPlans..."
        Clear-Variable -Name "UserAssignedPlans" -Scope Global
        Log "Calling Garbage Collection"
        [GC]::Collect()
    }
    while ($UserNextLink -ne  $null )
    [void] $fileNamesToUpload.Add($UserFileName)
    [void] $fileNamesToUpload.Add($UserLicenseAssignmentStatesFileName)
    [void] $fileNamesToUpload.Add($UserLicenseAssignmentStatesDisabledPlansFileName)
    [void] $fileNamesToUpload.Add($UserProvisionedPlansFileName)
    [void] $fileNamesToUpload.Add($UserAssignedLicensesFileName)
    [void] $fileNamesToUpload.Add($UserAssignedPlansFileName)

    Upload-Blob-Files -FileNames $fileNamesToUpload -FilePath  $path -Directory $Directory -Url $Url -ContainerName $ContainerName 
    
    #Upload-Blob-File -FileName $UserFileName -FilePath  $path -Directory $Directory -Url $Url -ContainerName $ContainerName 
    #Upload-Blob-File -FileName $UserLicenseAssignmentStatesFileName -FilePath  $path -Directory $Directory -Url $Url -ContainerName $ContainerName 
    #Upload-Blob-File -FileName $UserLicenseAssignmentStatesDisabledPlansFileName -FilePath  $path -Directory $Directory -Url $Url -ContainerName $ContainerName 
    #Upload-Blob-File -FileName $UserProvisionedPlansFileName -FilePath  $path -Directory $Directory -Url $Url -ContainerName $ContainerName 
    #Upload-Blob-File -FileName $UserAssignedLicensesFileName -FilePath  $path -Directory $Directory -Url $Url -ContainerName $ContainerName 
    #Upload-Blob-File -FileName $UserAssignedPlansFileName -FilePath  $path -Directory $Directory -Url $Url -ContainerName $ContainerName 

    OMSLog -Status "pass" -StatusDescription "Processed Users Report for  for $tenantName " -Tenant $tenantName
    Log "############# Job Completed ##############"
    
}
Catch {
    $TransMsg = "FAILED processing Users Report for  for $tenantName with errors: $_"
    Log $TransMsg
     OMSLog -Status "fail" -StatusDescription $TransMsg -Tenant $tenantName
     -ErrorAction "Stop"  
    Throw $TransMsg
}



