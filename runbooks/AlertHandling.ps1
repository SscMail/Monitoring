####################################################################################################
#- Name: AlertHandling.ps1                                                                  -#
#- Date: August 05, 2022                                                                          -#
#- Description: This runbook is called when an alert gets generated. It queries alert data        -#     
#- and triggers an email with alert datarage Graph API to send an email then validate the email   -# 
#- Dependencies:                                                                                  -#
#- 	- MSAL.PS PowerShell Module Library (Available from PowerShell Gallery)                       -#
#-  - OMSIngestionAPI Module Library (Available from PowerShell Gallery)                          -#  
#- 	- User credentials for Sender and Receiver                                                    -#
#- 	- Log analytics workspace and key                                                             -#
#- 	  -  Mail.Read                                                                                -#
#- 	  -  Mail.ReadBasic                                                                           -#
#- 	  -  Mail.ReadWrite                                                                           -#
#- 	  -  Mail.Send                                                                                -#
#- 	  -  Mail.Send.Shared                                                                         -#
####################################################################################################

param
(
    [Parameter (Mandatory=$false)]
    [object] $WebhookData
)

Import-Module MSAL.PS
Import-Module OMSIngestionAPI
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Users.Actions
Import-Module ExchangeOnlineManagement


$FAILED ="Failed"
$SUCCESS = "Success"

$jobid = $PSPrivateMetadata.JobId.Guid
$tenant ='SSCDev'
#--- Get AD Application info from variables ---#
$clientId = Get-AutomationVariable -Name 'SSCDevClientIDMailflow'
$tenantId = Get-AutomationVariable -Name 'SSCDevTenantID'
$redirectUri = Get-AutomationVariable -Name 'SSCDevURIRedirect'

#--- Get Log Analytics authentication info from variables ---#
$workspaceId = Get-AutomationVariable -Name 'OMSWorkSpaceID'
$workspaceKey = Get-AutomationVariable -Name 'OMSPrimaryKey'

$LogType = "AlertHandlingStatus"

$SenderCredential = Get-AutomationPSCredential -Name 'SSCDevCloudMailFlowSender'
$ReceiverCredential = Get-AutomationPSCredential -Name 'SSCDevCloudMailFlowReceiver'

$htmlContent = "{'Status' : 'Not Set'}"

if ($WebhookData)
{
    # Get the data object from WebhookData
    $WebhookBody = (ConvertFrom-Json -InputObject $WebhookData.RequestBody)
    # Get the info needed to identify the VM (depends on the payload schema)
    $schemaId = $WebhookBody.schemaId
    write-output "schemaId: $schemaId" 
    if ($schemaId -eq "azureMonitorCommonAlertSchema") {
        # This is the common Metric Alert schema (released March 2019)
        
		$Essentials = [object] ($WebhookBody.data).essentials
		$firedDateTimeStr = $Essentials.firedDateTime
		$firedDateTime = [Datetime] $firedDateTimeStr
		$firedDateTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( $firedDateTime , 'Eastern Standard Time')
		


		$alertName = $Essentials.alertRule
		$severity = $Essentials.severity
		$alertDescription =$Essentials.description
		$implactedTenants = $Essentials.configurationItems

		$alertContext = [object] ($WebhookBody.data).alertContext
		# Prepare jason object as parameter for email sending 
		# emails are taken from the costum properties configured under each alert rule. 
		# expected property name: alertEmail, value is set of emails with ; as delimeter. 
		$emailsString = $alertContext.properties.alertEmails
		$emails = $emailsString -split ";"
		$emailsArray = @()
 		Foreach ($email in $emails) {
			$emailsArray+= @{
				EmailAddress = @{
					Address = "$email"
				}
			}
		}

		if ($emailsArray.Length -lt 1){
			$SendStatus = $FAILED
			$TransMsg = "$_"
			$statusDescription ="Unable to find an alert email for notification. Please make sure there is a property 'alertEmail' with email value  added to the alert. "
			$emailsArray+= @{
				EmailAddress = @{
					Address = "arton.sallahi@ssc-spc.gc.ca"
				}
			}

		}else{
																			   
			$linkToFilteredSearchResultsAPI = $alertContext.condition.allOf[0].linkToFilteredSearchResultsAPI
			$linkToSearchResultsUI = $alertContext.condition.allOf[0].linkToSearchResultsUI
			$dimensions = $alertContext.condition.allOf[0].dimensions
			$dimensionLabel =""
			Foreach ($dimension in $dimensions) {
				$dimensionLabel = "$dimensionLabel <br> "+$dimension.name +" : "+$dimension.value

			}
			$implactedTenants = $dimensionLabel

			########################################################################################
			#       This section is used to authenticate against 
			#      Log Analytics and query alert data to be included in the email 
			########################################################################################

			# Get Access Token for Log Analytics to allow KQL Queries to get last ingested events in Custom Logs
			$logsClientId = Get-AutomationVariable -Name 'LogAnalyticsAPIClientID'
			$logsClientSecret = Get-AutomationVariable -Name 'LogAnalyticsAPIClientSecret'

			$loginURL = "https://login.microsoftonline.com/$TenantId/oauth2/token"
			$resource = "https://api.loganalytics.io"
			$authbody = @{grant_type = "client_credentials"; resource = $resource; client_id = $logsClientId; client_secret = $logsClientSecret }

			try{
				$oauth = Invoke-RestMethod -Method Post -Uri $loginURL -Body $authbody
				write-output "authenticated to Log Analytics API . Response:  $_"
				}
			catch {
				$SendStatus = $FAILED
				$statusDescription = "Failed to authenticate to Log Analytics API. Response: Reason: $_"
			}

			try{
				write-output "Trying to query search results using url: $linkToFilteredSearchResultsAPI"
				Write-Verbose "Trying to query search results using url: $linkToFilteredSearchResultsAPI"
				$headerParams = @{'Authorization' = "$($oauth.token_type) $($oauth.access_token)" }
				$result = invoke-RestMethod -method Get -uri $linkToFilteredSearchResultsAPI  -Headers $headerParams
				$table  = $result.tables[0]
				$tableColumns = $result.tables[0].columns
				$tableRows = $result.tables[0].rows			
			} catch{
				$SendStatus = $FAILED
				$statusDescription= "Failed to query to Log Analytics data. Response:  $_"
				Write-Verbose $statusDescription
				write-output $statusDescription
			}

			# mesage title 
			$messageTitle = "M365 Monitoring Alert Triggered: $alertName"

			# Main Body 
			$alertDetailsHTML = "
			<table>
				<tr>
					<td>Alert Name</td>
					<td>$alertName</td>
				</tr>
				<tr>
					<td>Alert Description</td>
					<td>$alertDescription</td>
				</tr>
				<tr>
					<td>Fired Date and Time in EST</td>
					<td>$firedDateTime</td>
				</tr>
				<tr>
					<td>Severity</td>
					<td>$severity</td>
				</tr>
				<tr>
					<td>Portal Link</td>
					<td><a>$linkToSearchResultsUI</a></td>
				</tr>
			</table>
			" 

			#  Process search results 
			$columns  = $table.columns
			$rows  = $table.rows
			$columnsHTML= " `n		<tr>" 

			Foreach ($item in $columns) {
				$title = $item.name
				$columnsHTML = $columnsHTML + " `r`n			<th> $title </th>"
			}
			$columnsHTML = $columnsHTML + " `r`n		</tr>"
			$rowsHTML= ""

			Foreach ($item in $rows) {
				$rowsHTML = $rowsHTML + " `r`n	<tr>"
				Foreach ($entry in $item){
					$encodedEntry = [System.Net.WebUtility]::HtmlEncode($entry)
					$rowsHTML = $rowsHTML + " `r`n			<td> $encodedEntry  </td>"
				}    
				$rowsHTML = $rowsHTML + " `r`n		</tr>"
			}
			$tableHTML = 
			"`r`n	<h2>Alert Query Results</h2>
			`r`n		<table>$columnsHTML  $rowsHTML  `r`n		</table>"

			$mainContent = $alertDetailsHTML
			$searchResuts = $tableHTML 
			#Prepare HTML BOdy 
			$htmlPage ="<!DOCTYPE html>
			<html>
				<head>
					<style>
						body {
							font-family: Arial, Helvetica, sans-serif;
							border-collapse: collapse;
							width: 100%;
						}
						table {
							border-collapse: collapse;
							width: 100%;
						}
						table td, table th {
							border: 1px solid #ddd;
							padding: 8px;
						}
						table tr:nth-child(even){background-color: #f2f2f2;}
						table tr:hover {background-color: #ddd;}
						table th {
							padding-top: 12px;
							padding-bottom: 12px;
							text-align: left;
							background-color: gray;
							color: white;
						}
					</style>
				</head>
				<body>
					$mainContent
					<br/>  
					$searchResuts 
				</body>
			</html>"
			Add-Type -AssemblyName System.Web
			# $encodedContent = [System.Web.HttpUtility]::HtmlEncode($htmlPage)

			$params = @{
				Message = @{
					Subject = "$messageTitle"
					Body = @{
						ContentType = "HTML"
						Content = "$htmlPage"
					}
					ToRecipients = @(
						@{
							EmailAddress = @{
								Address = "arton.sallahi@ssc-spc.gc.ca"
							}
						}
					)
				}
			}
			$params.Message.ToRecipients = $emailsArray

			Try {
				$SenderCredential = Get-AutomationPSCredential -Name 'SSCDevCloudMailFlowSender'
				$ReceiverEmail = "arton.sallahi@ssc-spc.gc.ca"
				$mailClientId = Get-AutomationVariable -Name 'SSCDevClientIDMailflow'
				$mailTenantId = Get-AutomationVariable -Name 'SSCDevTenantID'
				$mailRedirectUri = Get-AutomationVariable -Name 'SSCDevURIRedirect'
				$token = Get-MsalToken -ClientId $mailClientId -TenantId $mailTenantId -RedirectUri $mailRedirectUri -UserCredential $SenderCredential
				$accessToken = $token.AccessToken
				Connect-MgGraph -AccessToken $accessToken

				Send-MgUserMail -UserId $SenderCredential.UserName  -BodyParameter $params
				Disconnect-MgGraph
				$SendStatus = $SUCCESS
				$statusDescription ="Email Sent"
				$TransMsg = ""
				write-output "Email Sent."
			} 
			Catch {

				$SendStatus = $FAILED
				$TransMsg = "$_"
				$statusDescription ="Send Mail Failed: $TransMsg"
				write-output "Failed to Send email. Response: $Response .  Reason: $_"
			}
		}
    }
    else {
        # Schema not supported
        write-output "The alert data schema - $schemaId - is not supported."
		$sendStatus = $FAILED
		$statusDescription ="Schema not supported"
		
    }
}
else {
	$sendStatus = $FAILED
	$statusDescription ="WebhookData is emepty"
    # Error
    write-output "This runbook is meant to be started from an Azure alert webhook only."
}

$omsjson = @"
[{  
	"Status": "$sendStatus",
	"StatusDescription": "$statusDescription",
    "FireDateTime": "$firedDateTimeStr" ,
    "AlertName": "$alertName",
    "Severity": "$severity",
    "AlertDescription": "$alertDescription",
	"LinkToSearchResultsUI": "$linkToSearchResultsUI",
	"EmailContent": "",
	"SentTo": "$emailsString",
    "JobId": "$jobid"
}]
"@

# Send Monitoring Data for email
Send-OMSAPIIngestionFile -customerId $workspaceId -sharedKey $workspaceKey -body $omsjson -logType $logType
write-output $omsjson


