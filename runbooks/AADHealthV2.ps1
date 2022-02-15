##################################################################################################
#- Name: ADDHealthV2.ps1                                                                       -#
#- Date: November 28, 2021                                                                      -#
#- Description: This script uses Microsoft Graph to pull  AD Sync status                        -# 
#-                  and feed into Log Analtycis                                                 -#
#- Dependencies:                                                                                -#
#- 	- Azure Service Principal (Registered Client App) with API read permissions                 -#
#- 	- Log analytics workspace and key                                                           -#
#- 	                                                                                            -#
##################################################################################################

#--- Include module to format and send request to OMS ---#
Import-Module OMSIngestionAPI -Global
Import-Module MSAL.PS -Global

#--- Get Log Analytics authentication info from variables ---#
$CustomerId = Get-AutomationVariable -Name 'OMSWorkSpaceID'
$SharedKey = Get-AutomationVariable -Name 'OMSPrimaryKey'

$tenants = @(
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
    } ,
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
    }
 
)

####### Queries Org Synch Health and returns results ############
function Get-OrgSyncHealth {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]
        $TenantID,
		
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('ApplicationID', 'AppID')]
        [string]
        $ClientID,
		
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]
        $ClientSecret,
		
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]
        $TenantName
    )
	
    begin {
        $loginURL = "https://login.windows.net/"
    }
    process {
        $tenantLoginURL = $loginURL + $TenantID
        #May need to add /v2.0 after oauth2 in URI below
        $oauth = New-OAuthToken -Uri "$tenantLoginURL/oauth2/token" -Resource 'https://graph.microsoft.com/' -ClientID $ClientID -ClientSecret $ClientSecret
        $headerParams = @{ 'Authorization' = "$($oauth.token_type) $($oauth.access_token)" }
		
        $paramInvokeRestMethod = @{
            Headers   = $headerParams
            Uri       = 'https://graph.microsoft.com/v1.0/domains'
            UserAgent = 'application/json'
            Method    = 'Get'
        }
        $domain = ((Invoke-RestMethod @paramInvokeRestMethod).value | Where-Object isDefault).id
		
        $oauth = New-OAuthToken -Uri "$tenantLoginURL/oauth2/token" -Resource 'https://graph.microsoft.com/' -ClientID $ClientID -ClientSecret $ClientSecret
        $header = @{ "Authorization" = "Bearer $($oauth.access_token)"; "Content-Type" = "application/json" }
		
        #--- Get the data ---#
        $OrgSyncHealth = Invoke-RestMethod -Method GET -Headers $header -Uri "https://graph.microsoft.com/beta/organization"
		
        foreach ($OrgSyncHealthState in $OrgSyncHealth.value) {
            [pscustomobject][ordered]@{
                Computer                          = $env:COMPUTERNAME
                OrgOnPremSyncEnabled              = $OrgSyncHealthState.onPremisesSyncEnabled
                O365TenantName                    = $TenantName
                O365DefaultId                     = $domain
                OrgDisplayName                    = $OrgSyncHealthState.displayName
                O365Tenant                        = $TenantID
                OrgOnPremLastSyncDateTime         = $OrgSyncHealthState.onPremisesLastSyncDateTime
                OrgOnPremLastPasswordSyncDateTime = $OrgSyncHealthState.onPremisesLastPasswordSyncDateTime
            }
        }
    }
}

#--- Query M365 Service Health Dashboard via O365 Services Communications API ---#
$AADOrghealth = $tenants | foreach { Get-OrgSyncHealth -TenantID $_.TenantID -ClientID $_.ClientID -ClientSecret $_.ClientSecret -TenantName $_.TenantName }

$JSON = $AADOrghealth | ConvertTo-Json -Depth 10
#write-output $JSON

#--- Set the name of the log that will be created/appended to in Log Analytics. ---#
$LogType = "AADOrgHealth"

#--- Submit the ServiceHealth Data to Log Analytics API endpoint. ---#
Send-OMSAPIIngestionFile -customerId $CustomerID -sharedKey $SharedKey -body $JSON -logType $LogType -Verbose
