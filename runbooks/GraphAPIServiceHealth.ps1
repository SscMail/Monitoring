####################################################################################################
#-           New Runbook to query and digest service health API using Microsoft Graph APIs        -#
#- 	                                                                                              -#
####################################################################################################

Import-Module MSAL.PS
#--- Include module to format and send request to OMS ---#
Import-Module OMSIngestionAPI

$tenants = @(
    [pscustomobject]@{
        TenantName   = "SSC3Dev";
        TenantID     = Get-AutomationVariable -Name 'SSCDevTenantID';
        ClientID     = Get-AutomationVariable -Name 'SSCDevClientID';
        ClientSecret = Get-AutomationVariable -Name 'SSCDevClientSecret';
    },
    [pscustomobject]@{
        TenantName   = "IAAC";
        TenantID     = Get-AutomationVariable -Name 'IAACTenantID';
        ClientID     = Get-AutomationVariable -Name 'IAACClientID';
        ClientSecret = Get-AutomationVariable -Name 'IAACClientSecret';
    }
)

#--- Get Log Analytics authentication info from variables ---#
$CustomerId = Get-AutomationVariable -Name 'OMSWorkSpaceID'
$SharedKey = Get-AutomationVariable -Name 'OMSPrimaryKey'

# Microsoft M365 Services to query logs for   #
$M365Services = @('Exchange Online', 'Microsoft Teams', 'Identity Service','Microsoft 365 suite')

foreach ($tenant in $tenants){
    $tenantName  = $tenant.TenantName
    $tenantID = $tenant.TenantID
    $clientID = $tenant.ClientID
    
    Write-Output " Processing " $tenantName 
    $secureClientSecret = $tenant.ClientSecret | ConvertTo-SecureString -AsPlainText -Force
    $token = Get-MsalToken -clientID $clientID -clientSecret $secureClientSecret -tenantID $tenantID
    $accessToken = $token.AccessToken
    $header = @{"Authorization" = "Bearer $accessToken"; "Content-Type" = "application/json" };
    Try {
   
        #################################################
        #        Process M365 Service Health Status     #     
        #################################################
        $apiUrlPart1 = 'https://graph.microsoft.com/v1.0/admin/serviceAnnouncement/healthOverviews/'
        $apiUrlPart2 = '?$expand=issues'

        foreach ($M365service in $M365Services){
            $apiUrl = $apiUrlPart1 + $M365service + $apiUrlPart2
            $Data = Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken"} -Uri $apiUrl -Method Get
    
            $healthOverview =  [pscustomobject]@{
                    Tenant   = $tenantName;
                    TenantID     = $tenantID;
                    ServiceName  = $Data.service;
                    ServiceStatus =$Data.status;
                    ServiceId =$Data.id;
                }

            $JSON = $healthOverview| ConvertTo-Json -Depth 10
            $LogType = "M365ServiceStatus"
            Write-Output "digesting $LogType log for $tenantName"
            Send-OMSAPIIngestionFile -customerId $CustomerID -sharedKey $SharedKey -body $JSON -logType $LogType -Verbose

            $LogType = "M365ServiceIncidents"

            foreach ($issue in $Data.issues){
               $issue | Add-Member -NotePropertyName Tenant -NotePropertyValue $tenantName
            }
            $JSON =  $Data.issues | ConvertTo-Json -Depth 10
            Write-Output "digesting $LogType log for $tenantName"
            Send-OMSAPIIngestionFile -customerId $CustomerID -sharedKey $SharedKey -body $JSON -logType $LogType -Verbose   
        }
    }    
    Catch {
        $SendStatus = "failure"
        $TransMsg = "$_"
        Write-Output $TransMsg
    }

}

    try{
        ##########################################################
        #        Process M365 Messages  one for the last tenant  #     
        ##########################################################
        $uri = "https://graph.microsoft.com/v1.0/admin/serviceAnnouncement/messages"
        $LogType = "M365Messages"
        $Data = Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken"} -Uri $uri -Method Get    
        
        $JSON =  $Data.value | ConvertTo-Json -Depth 10
        Write-Output "digesting $LogType log for $tenantName"
        Send-OMSAPIIngestionFile -customerId $CustomerID -sharedKey $SharedKey -body $JSON -logType $LogType -Verbose
    } Catch{
         $SendStatus = "failure"
       
        Write-Output "Unable digest $LogType" 
        $TransMsg = "$_"
        Write-Output $TransMsg
    }

