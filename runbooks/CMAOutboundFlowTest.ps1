### CMA connection tests
Write-Output "Testing access to aka.ms on port 443"
Test-NetConnection -InformationLevel Quiet aka.ms -Port 443
Write-Output "Testing access to download.microsoft.com on port 443"
Test-NetConnection -InformationLevel Quiet download.microsoft.com -Port 443
Write-Output "Testing access to packages.microsoft.com on port 443"
Test-NetConnection -InformationLevel Quiet packages.microsoft.com -Port 443
Write-Output "Testing access to login.windows.net on port 443"
Test-NetConnection -InformationLevel Quiet login.windows.net -Port 443
Write-Output "Testing access to login.microsoftonline.com on port 443"
Test-NetConnection -InformationLevel Quiet login.microsoftonline.com -Port 443
Write-Output "Testing access to pas.windows.net on port 443"
Test-NetConnection -InformationLevel Quiet pas.windows.net -Port 443
Write-Output "Testing access to management.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet management.azure.com -Port 443
# Test-NetConnection -InformationLevel Quiet *.his.arc.azure.com -Port 443
Write-Output "Testing access to gbl.his.arc.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet gbl.his.arc.azure.com -Port 443
Write-Output "Testing access to cc.his.arc.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet cc.his.arc.azure.com -Port 443
# Test-NetConnection -InformationLevel Quiet *.guestconfiguration.azure.com -Port 443
Write-Output "Testing access to guestconfiguration.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet guestconfiguration.azure.com -Port 443
Write-Output "Testing access to agentserviceapi.guestconfiguration.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet agentserviceapi.guestconfiguration.azure.com -Port 443
Write-Output "Testing access to cc-gas.guestconfiguration.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet cc-gas.guestconfiguration.azure.com -Port 443
# Test-NetConnection -InformationLevel Quiet privatelink.guestconfiguration.azure.com -Port 443
# Test-NetConnection -InformationLevel Quiet *.guestnotificationservice.azure.com -Port 443
Write-Output "Testing access to guestnotificationservice.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet guestnotificationservice.azure.com -Port 443
Write-Output "Testing access to azgn-canadacentral-public-1p-weuam3-010.servicebus.windows.net on port 443"
Test-NetConnection -InformationLevel Quiet azgn-canadacentral-public-1p-weuam3-010.servicebus.windows.net -Port 443
Write-Output "Testing access to azgn-canadacentral-public-1s-seasg3-007.servicebus.windows.net on port 443"
Test-NetConnection -InformationLevel Quiet azgn-canadacentral-public-1s-seasg3-007.servicebus.windows.net -Port 443
Write-Output "Testing access to g0-prod-am3-010-sb.servicebus.windows.net on port 443"
Test-NetConnection -InformationLevel Quiet g0-prod-am3-010-sb.servicebus.windows.net -Port 443
Write-Output "Testing access to g0-prod-sg3-007-sb.servicebus.windows.net on port 443"
Test-NetConnection -InformationLevel Quiet g0-prod-sg3-007-sb.servicebus.windows.net -Port 443
# Test-NetConnection -InformationLevel Quiet *.waconazure.com -Port 443
Write-Output "Testing access to wac.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet wac.azure.com -Port 443
Write-Output "Testing access to portal-s1.site.wac.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet portal-s1.site.wac.azure.com -Port 443
Write-Output "Testing access to portal-s1.site.waconazure.com on port 443"
Test-NetConnection -InformationLevel Quiet portal-s1.site.waconazure.com -Port 443
Write-Output "Testing access to portal-s2.site.wac.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet portal-s2.site.wac.azure.com -Port 443
Write-Output "Testing access to portal-s2.site.waconazure.com on port 443"
Test-NetConnection -InformationLevel Quiet portal-s2.site.waconazure.com -Port 443
Write-Output "Testing access to portal-s3.site.wac.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet portal-s3.site.wac.azure.com -Port 443
Write-Output "Testing access to portal-s3.site.waconazure.com on port 443"
Test-NetConnection -InformationLevel Quiet portal-s3.site.waconazure.com -Port 443
Write-Output "Testing access to portal-s4.site.wac.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet portal-s4.site.wac.azure.com -Port 443
Write-Output "Testing access to portal-s4.site.waconazure.com on port 443"
Test-NetConnection -InformationLevel Quiet portal-s4.site.waconazure.com -Port 443
Write-Output "Testing access to portal-s5.site.wac.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet portal-s5.site.wac.azure.com -Port 443
Write-Output "Testing access to portal-s5.site.waconazure.com on port 443"
Test-NetConnection -InformationLevel Quiet portal-s5.site.waconazure.com -Port 443
Write-Output "Testing access to canadacentral.waconazure.com on port 443"
Test-NetConnection -InformationLevel Quiet canadacentral.waconazure.com -Port 443
Write-Output "Testing access to cc.waconazure.com on port 443"
Test-NetConnection -InformationLevel Quiet cc.waconazure.com -Port 443
Write-Output "Testing access to scdcdccpcsaterrab5estg.blob.core.windows.net on port 443"
Test-NetConnection -InformationLevel Quiet scdcdccpcsaterrab5estg.blob.core.windows.net -Port 443
Write-Output "Testing access to advisorccan0001068.blob.core.windows.net on port 443"
Test-NetConnection -InformationLevel Quiet advisorccan0001068.blob.core.windows.net -Port 443
Write-Output "Testing access to ccanoioms.blob.core.windows.net on port 443"
Test-NetConnection -InformationLevel Quiet ccanoioms.blob.core.windows.net -Port 443
Write-Output "Testing access to scadvisorcontent.blob.core.windows.net on port 443"
Test-NetConnection -InformationLevel Quiet scadvisorcontent.blob.core.windows.net -Port 443
Write-Output "Testing access to scadvisorcontentpl.blob.core.windows.net on port 443"
Test-NetConnection -InformationLevel Quiet scadvisorcontentpl.blob.core.windows.net -Port 443
Write-Output "Testing access to dc.services.visualstudio.com on port 443"
Test-NetConnection -InformationLevel Quiet dc.services.visualstudio.com -Port 443
Write-Output "Testing access to canadacentral.monitoring.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet canadacentral.monitoring.azure.com -Port 443

### AMA connection tests
Write-Output "Testing access to global.handler.control.monitor.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet global.handler.control.monitor.azure.com -Port 443
Write-Output "Testing access to canadacentral.handler.control.monitor.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet canadacentral.handler.control.monitor.azure.com -Port 443
Write-Output "Testing access to a8a32f55-d428-440a-b6b9-1fe00009caa3.ods.opinsights.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet a8a32f55-d428-440a-b6b9-1fe00009caa3.ods.opinsights.azure.com -Port 443

### MMA connection tests
Write-Output "Testing access to a8a32f55-d428-440a-b6b9-1fe00009caa3.ods.opinsights.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet a8a32f55-d428-440a-b6b9-1fe00009caa3.ods.opinsights.azure.com -Port 443
Write-Output "Testing access to a8a32f55-d428-440a-b6b9-1fe00009caa3.oms.opinsights.azure.com on port 443"
Test-NetConnection -InformationLevel Quiet a8a32f55-d428-440a-b6b9-1fe00009caa3.oms.opinsights.azure.com -Port 443
Write-Output "Testing access to a8a32f55-d428-440a-b6b9-1fe00009caa3.agentsvc.azure-automation.net on port 443"
Test-NetConnection -InformationLevel Quiet a8a32f55-d428-440a-b6b9-1fe00009caa3.agentsvc.azure-automation.net -Port 443
Write-Output "Testing access to a8a32f55-d428-440a-b6b9-1fe00009caa3.webhook.cc.azure-automation.net on port 443"
Test-NetConnection -InformationLevel Quiet a8a32f55-d428-440a-b6b9-1fe00009caa3.webhook.cc.azure-automation.net -Port 443
Write-Output "Testing access to a8a32f55-d428-440a-b6b9-1fe00009caa3.jrds.cc.azure-automation.net on port 443"
Test-NetConnection -InformationLevel Quiet a8a32f55-d428-440a-b6b9-1fe00009caa3.jrds.cc.azure-automation.net -Port 443

### Other connection tests
Write-Output "Testing access to www.office.com on port 443"
Test-NetConnection -InformationLevel Quiet www.office.com -Port 443
Write-Output "Testing access to canadacentral.login.microsoft.com on port 443"
Test-NetConnection -InformationLevel Quiet canadacentral.login.microsoft.com -Port 443
# Test-NetConnection -InformationLevel Quiet *.data.mcr.microsoft.com -Port 443
Write-Output "Testing access to mcr.microsoft.com on port 443"
Test-NetConnection -InformationLevel Quiet mcr.microsoft.com -Port 443
Write-Output "Testing access to scdcdccpcsaterrab5estg.data.mcr.microsoft.com on port 443"
Test-NetConnection -InformationLevel Quiet scdcdccpcsaterrab5estg.data.mcr.microsoft.com -Port 443
Write-Output "Testing access to cc.data.mcr.microsoft.com on port 443"
Test-NetConnection -InformationLevel Quiet cc.data.mcr.microsoft.com -Port 443
Write-Output "Testing access to sts.windows.net on port 443"
Test-NetConnection -InformationLevel Quiet sts.windows.net -Port 443
