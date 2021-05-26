##################################################################################################
#- Name: MultiTenantM365Query.ps1                                                               -#
#- Date: July 8, 2020                                                                           -#
#- Description: This script will leverage the Office 365 service communications API to pull     -# 
#-              service health and messages and feed into Log Analytics                         -#
#- Dependencies:                                                                                -#
#- 	- Azure Service Principal (Registered Client App) with API read permissions                 -#
#- 	- Log analytics workspace and key                                                           -#
#-      - OMSIngestionAPI v1.6.0 available from PowerShell Gallery:                             -# 
#-        https://www.powershellgallery.com/packages/OMSIngestionAPI/1.6.0                      -#
#-      -  M365Monitoring PowerShell Module                                                     -#
#- 	                                                                                            -#
##################################################################################################

#--- Include module to format and send request to OMS ---#
Import-Module OMSIngestionAPI
#--- Include the module to query M365 subscriptions.
Import-module M365Monitoring

#--- Get Log Analytics authentication info from variables ---#
$CustomerId = Get-AutomationVariable -Name 'OMSWorkSpaceID'
$SharedKey = Get-AutomationVariable -Name 'OMSPrimaryKey'

###################################################################################
#- See Section 4.6.1 and 4.6.2 of MSM14                                          -#
#- Array of tenants and the required parameters to authenticate with M365 tenant -#
#- You need to add a new array for each tenant that will be queried.             -#
#- Each Hashtable value will reference associated value in Azure Automation      -#
#- Variables.                                                                    -#
#- Each Azure Variable will use the following naming convention:                 -#
#- Dept Abbreviation<VariableName>                                               -#
#- Ex:                                                                           -#
#-     SSCTenantID                                                               -#
#-     SSCClientID                                                               -#
#-     SSCClientSecret                                                           -#
#-  TenantName is used to create a friendly name for the O365 subscription.      -#
#-  TenantName is used by the O365 Incident Workbook to scope the data to a      -#
#-  specific O365 subscription                                                   -#
###################################################################################
$tenants = @(
 <#
  [pscustomobject]@{
        TenantName   = "BryanZ-O365";
        TenantID     = Get-AutomationVariable -Name 'BZM365TenantID';
        ClientID     = Get-AutomationVariable -Name 'BZM365ClientID';
        ClientSecret = Get-AutomationVariable -Name 'BZM365ClientSecret';
    },
    [pscustomobject]@{
        TenantName   = "BrianK-O365";
        TenantID     = Get-AutomationVariable -Name 'BKM365TenantID';
        ClientID     = Get-AutomationVariable -Name 'BKClientID';
        ClientSecret = Get-AutomationVariable -Name 'BKClientSecret';
    },
    #>
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
    }
 
) 

#--- Query M365 Service Health Dashboard via O365 Services Communications API ---#
$Servicehealth = $tenants | foreach { get-M365ServiceHealth -TenantID $_.TenantID -ClientID $_.ClientID -ClientSecret $_.ClientSecret -TenantName $_.TenantName }
#write-output $Servicehealth

$JSON = $Servicehealth | ConvertTo-Json -Depth 10
#write-output $JSON

#--- Set the name of the log that will be created/appended to in Log Analytics. ---#
$LogType = "O365ServiceHealth"

#--- Submit the ServiceHealth Data to Log Analytics API endpoint. ---#

Send-OMSAPIIngestionFile -customerId $CustomerID -sharedKey $SharedKey -body $JSON -logType $LogType -Verbose

#--- Query M365 Message Center via O365 Services Communications API ---#
$Messages = $tenants | foreach { get-M365Messages -TenantID $_.TenantID -ClientID $_.ClientID -ClientSecret $_.ClientSecret -TenantName $_.TenantName }
write-output $Messages

#Convert Messages to JSON format before sending to Log Analytics.
$JSON = $Messages | ConvertTo-Json -Depth 10
#write-output $JSON

#--- Set the name of the log that will be created/appended to in Log Analytics. ---#
$LogType = "O365MessageCenter"

#--- Submit the ServiceHealth Data to Log Analytics API endpoint. ---#
Send-OMSAPIIngestionFile -customerId $CustomerID -sharedKey $SharedKey -body $JSON -logType $LogType -Verbose

