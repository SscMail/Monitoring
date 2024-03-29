Import-Module MSAL.PS
Import-Module OMSIngestionAPI

$jobid = $PSPrivateMetadata.JobId.Guid
$tenant ='SSCDev'
#--- Get AD Application info from variables ---#
$clientId = Get-AutomationVariable -Name 'SSCDevClientIDMailflow'
$tenantId = Get-AutomationVariable -Name 'SSCDevTenantID'
$redirectUri = Get-AutomationVariable -Name 'SSCDevURIRedirect'

#--- Get Log Analytics authentication info from variables ---#
$workspaceId = Get-AutomationVariable -Name 'OMSWorkSpaceID'
$workspaceKey = Get-AutomationVariable -Name 'OMSPrimaryKey'

$LogType = "O365SyntheticGraphAPI"
$TestID = (get-date -format MMddyyyyhhmmss) + "-" + (get-random)

$SenderCredential = Get-AutomationPSCredential -Name 'SSCDevCloudMailFlowSender'
$ReceiverCredential = Get-AutomationPSCredential -Name 'SSCDevCloudMailFlowReceiver'
$ReceiverEmail = $ReceiverCredential.UserName


# Send email to receiver
$token = Get-MsalToken -ClientId $clientId -TenantId $tenantId -RedirectUri $redirectUri -UserCredential $SenderCredential
$accessToken = $token.AccessToken

$header = @{"Authorization" = "Bearer $accessToken"; "Content-Type" = "application/json" };
$sendMailMessageUrl = "https://graph.microsoft.com/v1.0/me/sendMail"

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
  $TransMsg = "$_"
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
$replyToken = Get-MsalToken -ClientId $clientId -TenantId $tenantId -RedirectUri $redirectUri -UserCredential $ReceiverCredential
$replyAccessToken = $replyToken.AccessToken

# Obtain latest message from Graph API
$getMessageHeader = @{"Authorization" = "Bearer $replyAccessToken"; "Content-Type" = "application/json" };
$getMessageMessageUrl = "https://graph.microsoft.com/v1.0/me/messages?`$search=`"Subject:Test Email $TestID`""

$sw = New-Object Diagnostics.Stopwatch

$retry = 0

do {
  Start-Sleep $retry

  $sw.Start()
  $getMessageReply = Invoke-RestMethod -Method GET -Headers $getMessageHeader -Uri $getMessageMessageUrl
  $sw.Stop()

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
