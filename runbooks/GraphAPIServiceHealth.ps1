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
        TenantName   = "SSC";
        TenantID     = Get-AutomationVariable -Name 'SSCTenantID';
        ClientID     = Get-AutomationVariable -Name 'SSCClientID';
        ClientSecret = Get-AutomationVariable -Name 'SSCClientSecret';
    },
    [pscustomobject]@{
        TenantName  = "IRB";
        TenantID    = Get-AutomationVariable -Name 'IRBTenantID';
        ClientID    = Get-AutomationVariable -Name 'IRBClientID';
        ClientSecret = Get-AutomationVariable -Name 'IRBClientSecret';
    },
    [pscustomobject]@{
        TenantName  = "ACOA";
        TenantID    = Get-AutomationVariable -Name 'ACOATenantID';
        ClientID    = Get-AutomationVariable -Name 'ACOAClientID';
        ClientSecret = Get-AutomationVariable -Name 'ACOAClientSecret';
    },
    [pscustomobject]@{
        TenantName  = "WD";
        TenantID    = Get-AutomationVariable -Name 'WDTenantID';
        ClientID    = Get-AutomationVariable -Name 'WDClientID';
        ClientSecret = Get-AutomationVariable -Name 'WDClientSecret';
    },
    [pscustomobject]@{
        TenantName  = "AADNC";
        TenantID    = Get-AutomationVariable -Name 'AADNCTenantID';
        ClientID    = Get-AutomationVariable -Name 'AADNCClientID';
        ClientSecret = Get-AutomationVariable -Name 'AADNCClientSecret';
    },
    [pscustomobject]@{
        TenantName  = "CSA";
        TenantID    = Get-AutomationVariable -Name 'CSATenantID';
        ClientID    = Get-AutomationVariable -Name 'CSAClientID';
        ClientSecret = Get-AutomationVariable -Name 'CSAClientSecret';
    },
    [pscustomobject]@{
        TenantName  = "CSPS";
        TenantID    = Get-AutomationVariable -Name 'CSPSTenantID';
        ClientID    = Get-AutomationVariable -Name 'CSPSClientID';
        ClientSecret = Get-AutomationVariable -Name 'CSPSClientSecret';
    },
    [pscustomobject]@{
        TenantName  = "PS";
        TenantID    = Get-AutomationVariable -Name 'PSTenantID';
        ClientID    = Get-AutomationVariable -Name 'PSClientID';
        ClientSecret = Get-AutomationVariable -Name 'PSClientSecret';
    },
    [pscustomobject]@{
        TenantName  = "ISED";
        TenantID    = Get-AutomationVariable -Name 'ISEDTenantID';
        ClientID    = Get-AutomationVariable -Name 'ISEDClientID';
        ClientSecret = Get-AutomationVariable -Name 'ISEDClientSecret';
    },
    [pscustomobject]@{
        TenantName  = "PC";
        TenantID    = Get-AutomationVariable -Name 'PCTenantID';
        ClientID    = Get-AutomationVariable -Name 'PCClientID';
        ClientSecret = Get-AutomationVariable -Name 'PCClientSecret';
    },
    [pscustomobject]@{
        TenantName  = "PCH";
        TenantID    = Get-AutomationVariable -Name 'PCHTenantID';
        ClientID    = Get-AutomationVariable -Name 'PCHClientID';
        ClientSecret = Get-AutomationVariable -Name 'PCHClientSecret';
    },
    [pscustomobject]@{
        TenantName  = "CFIA";
        TenantID    = Get-AutomationVariable -Name 'CFIATenantID';
        ClientID    = Get-AutomationVariable -Name 'CFIAClientID';
        ClientSecret = Get-AutomationVariable -Name 'CFIAClientSecret';
    },
    [pscustomobject]@{
        TenantName  = "LAC";
        TenantID    = Get-AutomationVariable -Name 'LACTenantID';
        ClientID    = Get-AutomationVariable -Name 'LACClientID';
        ClientSecret = Get-AutomationVariable -Name 'LACClientSecret';
    },
    [pscustomobject]@{
        TenantName  = "NRCan";
        TenantID    = Get-AutomationVariable -Name 'NRCanTenantID';
        ClientID    = Get-AutomationVariable -Name 'NRCanClientID';
        ClientSecret = Get-AutomationVariable -Name 'NRCanClientSecret';
    },
    [pscustomobject]@{
        TenantName  = "TC";
        TenantID    = Get-AutomationVariable -Name 'TCTenantID';
        ClientID    = Get-AutomationVariable -Name 'TCClientID';
        ClientSecret = Get-AutomationVariable -Name 'TCClientSecret';
    },
  
    [pscustomobject]@{
        TenantName  = "VAC";
        TenantID    = Get-AutomationVariable -Name 'VACTenantID';
        ClientID    = Get-AutomationVariable -Name 'VACClientID';
        ClientSecret = Get-AutomationVariable -Name 'VACClientSecret';
    },
    [pscustomobject]@{
        TenantName  = "FIN";
        TenantID    = Get-AutomationVariable -Name 'FINTenantID';
        ClientID    = Get-AutomationVariable -Name 'FINClientID';
        ClientSecret = Get-AutomationVariable -Name 'FINClientSecret';
    },
    [pscustomobject]@{
        TenantName  = "ECCC";
        TenantID    = Get-AutomationVariable -Name 'ECCCTenantID';
        ClientID    = Get-AutomationVariable -Name 'ECCCClientID';
        ClientSecret = Get-AutomationVariable -Name 'ECCCClientSecret';
    },
    [pscustomobject]@{
        TenantName  = "IAAC";
        TenantID    = Get-AutomationVariable -Name 'IAACTenantID';
        ClientID    = Get-AutomationVariable -Name 'IAACClientID';
        ClientSecret = Get-AutomationVariable -Name 'IAACClientSecret';
    },

    [pscustomobject]@{
        TenantName  = "CED";
        TenantID    = Get-AutomationVariable -Name 'CEDTenantID';
        ClientID    = Get-AutomationVariable -Name 'CEDClientID';
        ClientSecret = Get-AutomationVariable -Name 'CEDClientSecret';
    },

    [pscustomobject]@{
        TenantName  = "AAFC";
        TenantID    = Get-AutomationVariable -Name 'AAFCTenantID';
        ClientID    = Get-AutomationVariable -Name 'AAFCClientID';
        ClientSecret = Get-AutomationVariable -Name 'AAFCClientSecret';
    }, 

    [pscustomobject]@{
        TenantName  = "INFC";
        TenantID    = Get-AutomationVariable -Name 'INFCTenantID';
        ClientID    = Get-AutomationVariable -Name 'INFCClientID';
        ClientSecret = Get-AutomationVariable -Name 'INFCClientSecret';
    },
  
    [pscustomobject]@{
        TenantName  = "PSC";
        TenantID    = Get-AutomationVariable -Name 'PSCTenantID';
        ClientID    = Get-AutomationVariable -Name 'PSCClientID';
        ClientSecret = Get-AutomationVariable -Name 'PSCClientSecret';
    },
    
    [pscustomobject]@{
        TenantName  = "JUS";
        TenantID    = Get-AutomationVariable -Name 'JUSTenantID';
        ClientID    = Get-AutomationVariable -Name 'JUSClientID';
        ClientSecret = Get-AutomationVariable -Name 'JUSClientSecret';
    },
        [pscustomobject]@{
        TenantName  = "STATCAN";
        TenantID    = Get-AutomationVariable -Name 'STATCANTenantID';
        ClientID    = Get-AutomationVariable -Name 'STATCANClientID';
        ClientSecret = Get-AutomationVariable -Name 'STATCANClientSecret';
    },
        [pscustomobject]@{
        TenantName  = "HC";
        TenantID    = Get-AutomationVariable -Name 'HCTenantID';
        ClientID    = Get-AutomationVariable -Name 'HCClientID';
        ClientSecret = Get-AutomationVariable -Name 'HCClientSecret';
    },
        [pscustomobject]@{
        TenantName  = "ESDC";
        TenantID    = Get-AutomationVariable -Name 'ESDCTenantID';
        ClientID    = Get-AutomationVariable -Name 'ESDCClientID';
        ClientSecret = Get-AutomationVariable -Name 'ESDCClientSecret';
    },
        [pscustomobject]@{
        TenantName  = "PPSC";
        TenantID    = Get-AutomationVariable -Name 'PPSCTenantID';
        ClientID    = Get-AutomationVariable -Name 'PPSCClientID';
        ClientSecret = Get-AutomationVariable -Name 'PPSCClientSecret';
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
		Write-Output "FAILED processing $LogType log for $tenantName"
        Write-Output $TransMsg
    }
    
    try{
        ##########################################################
        #        Process M365 Messages  one for the last tenant  #     
        ##########################################################
        $uri = "https://graph.microsoft.com/v1.0/admin/serviceAnnouncement/messages"
        $LogType = "M365Messages"
        $Data = Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken"} -Uri $uri -Method Get
        
        foreach ($msg in $Data.value){
            $msg | Add-Member -NotePropertyName Tenant -NotePropertyValue $tenantName
        }
        
        $JSON =  $Data.value | ConvertTo-Json -Depth 10
        Write-Output "digesting $LogType log for $tenantName"
        Send-OMSAPIIngestionFile -customerId $CustomerID -sharedKey $SharedKey -body $JSON -logType $LogType -Verbose
    } Catch{
         $SendStatus = "failure"
       
        Write-Output "FAILED  digesting $LogType for $tenantName" 
        $TransMsg = "$_"
        Write-Output $TransMsg
    }
}
<#
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
#>
