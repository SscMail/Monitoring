####################################################################################################
#-           New Runbook to query and digest service health API using Microsoft Graph APIs        -#
#- 	                                                                                              -#
####################################################################################################

Import-Module MSAL.PS
#--- Include module to format and send request to OMS ---#
Import-Module OMSIngestionAPI
$tenantCodes = @('AADNC', 'AAFC', 'ACOA', 'CED', 'CFIA', 'CSA', 'CSPS', 'DFO', 'ECCC', 'ESDC', 'FIN', 'HC', 'IAAC', 'INFC', 'IRB', 'ISED', 'JUS', 'LAC', 'NRCan', 'PC', 'PCO', 'PCH', 'PPSC', 'PS', 'PSC', 'SSC', 'STATCAN', 'TC', 'VAC', 'WD')

#--- Get Log Analytics authentication info from variables ---#
$workspaceId = Get-AutomationVariable -Name 'OMSWorkSpaceID'
$workspaceKey = Get-AutomationVariable -Name 'OMSPrimaryKey'
$LogType = "MonitoringHealth"

$testCategory = "API Permission"
$jobid = $PSPrivateMetadata.JobId.Guid

Write-Output "Initializing Variables..."
Write-Output "----------------------------"

foreach ($tenantCode in $tenantCodes) {
    $proceed = $true
    $outputLogs = [System.Collections.ArrayList]@()
    Try {
        $TransMsg =""
        $testDetails = "Testing configured authentication variables"
        
        $testType = "variables"
        $ClientID = Get-AutomationVariable -Name ($tenantCode + 'ClientID');
        $TenantID = Get-AutomationVariable -Name ($tenantCode + 'TenantID');
        $secureClientSecret = (Get-AutomationVariable -Name ($tenantCode + 'ClientSecret')) | ConvertTo-SecureString -AsPlainText -Force
        if($ClientID -and $clientID -and $secureClientSecret){
            $proceed = $true
            $status = "success"
            Write-Output "Variables: `t Pass"

        } else {
            $proceed = $false
            $status = "failure"
            Write-Output "Variables: `t Fail"
            $TransMsg ="Unable to find app registration varables for"
        }
    }
    Catch {
        $proceed = $false
        $TransMsg = $_
        $status = "failure"
        Write-Output "Variables: `t Fail"
        Write-Output $TransMsg
    }
    finally {
        $omsjson = @"
[{  
	"Status": "$status",
	"TestDetails": "$testDetails",
	"StatusDescription": "$TransMsg",
	"TestType": "$testType",
	"TestCategory": "$testCategory",
	"JobId": "$jobid",
	"Tenant": "$tenantCode", 
    "ApplicationID": "$ClientID"
}]
"@
        [void]$outputLogs.add($omsjson)
    }
    
    if ($proceed) {
        Write-Output "Testing permissions for $tenantCode"
        # ---------------------Authenticate -------------- #
        Try {
            $TransMsg =""
            $testDetails = "Testing authentication"
            $status = "success"
            $testType = "authentication"
            $token = Get-MsalToken -clientID $clientID -clientSecret $secureClientSecret -tenantID $tenantID
            $accessToken = $token.AccessToken
            $header = @{"Authorization" = "Bearer $accessToken"; "Content-Type" = "application/json" };
            Write-Output "Authentication: `t Pass"
        }
        Catch {
            $proceed = $false
            Write-Output "Authentication: `t Fail"
            $TransMsg = $_
            Write-Output $TransMsg
            $status = "failure"
        
        }
        finally {
            $omsjson = @"
[{  
	"Status": "$status",
	"TestDetails": "$testDetails",
	"StatusDescription": "$TransMsg",
	"TestType": "$testType",
	"TestCategory": "$testCategory",
	"JobId": "$jobid",
	"Tenant": "$tenantCode", 
    "ApplicationID": "$ClientID"
}]
"@
            $outputLogs.add($omsjson)
        }
    }
    if ($proceed) {
        # --------- Test Service Health  -------------- #
        Try {
            $TransMsg =""
            $testDetails = "Testing service health incidents permission"
            $status = "success"
            $testType = "healthOverviews"
            $apiUrl = 'https://graph.microsoft.com/v1.0/admin/serviceAnnouncement/healthOverviews?$top=1&$select=id'
            $Data = Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken" } -Uri $apiUrl -Method Get
            Write-Output "HealthOverview: `t Pass"
        }
        Catch {
            $TransMsg = $_
            $status = "failure"
            Write-Output "HealthOverview: `t Fail"
            Write-Output $TransMsg
        }
        finally {
            $omsjson = @"
[{  
	"Status": "$status",
	"TestDetails": "$testDetails",
	"StatusDescription": "$TransMsg",
	"TestType": "$testType",
	"TestCategory": "$testCategory",
	"JobId": "$jobid",
	"Tenant": "$tenantCode", 
    "ApplicationID": "$ClientID"
}]
"@
            $outputLogs.add($omsjson)
        }

        # --------- Test Messages -------------- #
        Try {
            $TransMsg =""
            $testDetails = "Testing for service health messages (announcements )"
            $status = "success"
            $testType = "messages"        
            $apiUrl = 'https://graph.microsoft.com/v1.0/admin/serviceAnnouncement/messages?$top=1&$select=id'
            $Data = Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken" } -Uri $apiUrl -Method Get
            Write-Output "Messages: `t Pass"
        }
        Catch {
            $TransMsg = $_
            $status = "failure"

            Write-Output "Messages: `t Fail"
            Write-Output $TransMsg
        }
        finally {
            $omsjson = @"
[{  
	"Status": "$status",
	"TestDetails": "$testDetails",
	"StatusDescription": "$TransMsg",
	"TestType": "$testType",
	"TestCategory": "$testCategory",
	"JobId": "$jobid",
	"Tenant": "$tenantCode", 
    "ApplicationID": "$ClientID"
}]
"@
            $outputLogs.add($omsjson)
        }

        # --------- Test AD -------------- #
        Try {
            $TransMsg =""
            $testDetails = "Testing for AD sync permission"
            $status = "success"
            $testType = "organization"         
            $apiUrl = 'https://graph.microsoft.com/v1.0/organization?$top=1&$select=id'
            $Data = Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken" } -Uri $apiUrl -Method Get
            Write-Output "AD Synch: `t Pass"
        }
        Catch {
            $TransMsg = $_
            $status = "failure"

            Write-Output "AD Synch: `t Fail"
            Write-Output $TransMsg
        }
        finally {
            $omsjson = @"
[{  
	"Status": "$status",
	"TestDetails": "$testDetails",
	"StatusDescription": "$TransMsg",
	"TestType": "$testType",
	"TestCategory": "$testCategory",
	"JobId": "$jobid",
	"Tenant": "$tenantCode", 
    "ApplicationID": "$ClientID"
}]
"@
            $outputLogs.add($omsjson)
        }
       # --------- Test Users API -------------- #
        Try {
            $TransMsg =""
            $testDetails = "Testing for Users Report permission"
            $status = "success"
            $testType = "users"         
            $apiUrl = 'https://graph.microsoft.com/v1.0/users?$top=1&$select=id'
            $Data = Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken" } -Uri $apiUrl -Method Get
            Write-Output "Users Report: `t Pass"
        }
        Catch {
            $TransMsg = $_
            $status = "failure"

            Write-Output "Users Report: `t Fail"
            Write-Output $TransMsg
        }
        finally {
            $omsjson = @"
[{  
	"Status": "$status",
	"TestDetails": "$testDetails",
	"StatusDescription": "$TransMsg",
	"TestType": "$testType",
	"TestCategory": "$testCategory",
	"JobId": "$jobid",
	"Tenant": "$tenantCode", 
    "ApplicationID": "$ClientID"
}]
"@
            $outputLogs.add($omsjson)
        }

    }
    # Send Monitoring Data for email
    foreach ($log in $outputLogs) {
        Send-OMSAPIIngestionFile -customerId $workspaceId -sharedKey $workspaceKey -body $log -logType $logType
    }    

}

