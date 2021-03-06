####################################################################################################
#- Name: O36MailFlowGraphApiTest.ps1                                                              -#
#- Date: Mar 14, 2022                                                                            -#
#- Description: This script leverages Graph API to send an email then validate the email         -# 
#-              was recieved and feed results into Log Analytics                                  -#
#-              It is shared and called by individual partner runbooks                            -#
#- Dependencies:                                                                                  -#
#- 	- MSAL.PS PowerShell Module Library (Available from PowerShell Gallery)                       -#
#-  - OMSIngestionAPI Module Library (Available from PowerShell Gallery)                          -#  
#- 	- User credentials for Sender and Receiver                                                    -#
#- 	- Log analytics workspace and key                                                             -#
#-  - AAD App Registration with the following API Permissions                                     -#
#- 	  -  Mail.Read                                                                                -#
#- 	  -  Mail.ReadBasic                                                                           -#
#- 	  -  Mail.ReadWrite                                                                           -#
#- 	  -  Mail.Send                                                                                -#
#- 	  -  Mail.Send.Shared                                                                         -#
#- 	                                                                                              -#
####################################################################################################
param(
		[Parameter(Mandatory=$true)]
		[string] $partnername
)

#$partnername

Import-Module MSAL.PS
Import-Module OMSIngestionAPI

$jobid = $PSPrivateMetadata.JobId.Guid
$tenant  =$partnername
#--- Get AD Application info from variables ---#
$clientId = Get-AutomationVariable -Name ($tenant+'ClientIDMailflow')
$tenantId = Get-AutomationVariable -Name ($tenant+'TenantID')
$redirectUri = Get-AutomationVariable -Name ($tenant+'URIRedirect')

#--- Get Log Analytics authentication info from variables ---#
$workspaceId = Get-AutomationVariable -Name 'OMSWorkSpaceID'
$workspaceKey = Get-AutomationVariable -Name 'OMSPrimaryKey'

$LogType = "O365SyntheticGraphAPI"
$TestID = (get-date -format MMddyyyyhhmmss) + "-" + (get-random)

$SenderCredential = Get-AutomationPSCredential -Name ($tenant+'MailFlowSender')
$ReceiverCredential = Get-AutomationPSCredential -Name ($tenant+'MailFlowReceiver')
$ReceiverEmail = $ReceiverCredential.UserName


# Send email to receiver
$senderAuthenticated = ""
$sendMailMessageUrl = "https://graph.microsoft.com/v1.0/me/sendMail"
try{
	$token = Get-MsalToken -ClientId $clientId -TenantId $tenantId -RedirectUri $redirectUri -UserCredential $SenderCredential
	$accessToken = $token.AccessToken
	$header = @{"Authorization" = "Bearer $accessToken"; "Content-Type" = "application/json" };
	$senderAuthenticated = 'true'
}
Catch{
	$SendStatus = "failure"
    $TransMsg = "Send Mail Authentication Failed: $_"
}

# Create Message body
$JSON = @"
{
    "message": {
      "subject": "Test Email $TestID",
      "body": {
        "contentType": "Text",
        "content": "Testing sending of Emails."
      },
      "toRecipients": [
        {
          "emailAddress": {
            "address": "$ReceiverEmail"
          }
        }
      ]
    },
    "saveToSentItems": "true"
  }
"@

# Capture Call Metrics
$sw = New-Object Diagnostics.Stopwatch

$sw.Start()
if ($senderAuthenticated){
	Try {
		Invoke-RestMethod -Method POST -Headers $header -Uri $sendMailMessageUrl -Body $JSON
		$SendTime = $sw.ElapsedMilliseconds
		$SendStatus = "success"
		$TransMsg = ""
	} 
	Catch {
		$sw.Stop()
		$SendTime = $sw.ElapsedMilliseconds
		$SendStatus = "failure"
		$TransMsg = "Send Mail Failed: $_"
	}
}

$omsjson = @"
[{  "Computer": "$ENV:COMPUTERNAME",
    "TestType": "mailflow",
    "TestID": "$TestID",
    "Tenant": "$tenant",
    "TransactionType": "sendmessage",
    "TransactionResult": "$SendStatus",
    "TransactionTime": $SendTime,
    "TransactionMessage": "$TransMsg",
    "JobId": "$jobid"
}]
"@

# Send Monitoring Data for email
Send-OMSAPIIngestionFile -customerId $workspaceId -sharedKey $workspaceKey -body $omsjson -logType $logType
write-output $omsjson

if ($SendStatus -eq "failure") {
  Exit
}

# reply to email 
$receiverAuthenticated =''
try{
	$replyToken = Get-MsalToken -ClientId $clientId -TenantId $tenantId -RedirectUri $redirectUri -UserCredential $ReceiverCredential
	$replyAccessToken = $replyToken.AccessToken

	# Obtain latest message from Graph API
	$getMessageHeader = @{"Authorization" = "Bearer $replyAccessToken"; "Content-Type" = "application/json" };
	$getMessageMessageUrl = "https://graph.microsoft.com/v1.0/me/messages?`$search=`"Subject:Test Email $TestID`""
	$receiverAuthenticated = 'true'
}
Catch{
	
	$ReceiveStatus = "failure"
    $TransMsg = "Receive Mail Authentication Failed: $_"
}
$sw = New-Object Diagnostics.Stopwatch

$retry = 0
if($receiverAuthenticated){
	do {
		Start-Sleep $retry

		$sw.Start()
		try{
			$getMessageReply = Invoke-RestMethod -Method GET -Headers $getMessageHeader -Uri $getMessageMessageUrl
			$sw.Stop()
		}
		Catch{
			$TransMsg = "Receive Email Failed: $_"	
			$ReceiveStatus = "failure"
			$sw.Stop()
			break
		}
		$ReceiveTime = $sw.ElapsedMilliseconds
		$messageCount = $getMessageReply.value.Count

		if ($messageCount -gt 0) {
			$ReceiveStatus = "success"
			$TransMsg = ""
		}
		else {
			$ReceiveStatus = "failure"
			$TransMsg = "Message with Subject 'Test Email $TestID' not found"
		}
		$retry++
	} until (($messageCount -gt 0) -or ($retry -gt 10))
}

$omsjson = @"
[{   "Computer": "$ENV:COMPUTERNAME",
    "TestType": "mailflow",
    "TestID": "$TestID",
    "Tenant": "$tenant",
    "TransactionType": "searchformessage",
    "TransactionResult": "$ReceiveStatus",
    "TransactionTime": $ReceiveTime,
    "TransactionMessage": "$TransMsg",
    "JobId": "$jobid"
}]
"@

Send-OMSAPIIngestionFile -customerId $workspaceId -sharedKey $workspaceKey -body $omsjson -logType $logType
write-output $omsjson

if ($ReceiveStatus -eq "failure") {
  Exit
}

$messageId = $getMessageReply.value.id

try {
  $deleteMessage = @{"Authorization" = "Bearer $replyAccessToken" };

  $deleteMessageUrl = "https://graph.microsoft.com/v1.0/me/messages/$messageId"

  $getMessageReply = Invoke-RestMethod -Method Delete -Headers $deleteMessage -Uri $deleteMessageUrl

  write-output "Message Test Email $TestID Deleted Successfully"
}
catch {
  write-output "Error Deleting Message with subject Test Email $TestID"
  write-output $_
}

