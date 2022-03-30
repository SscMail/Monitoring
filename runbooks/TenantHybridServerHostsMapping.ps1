####################################################################################################
#- Name: TenantHybridServerHostingMapping.ps1                                                      -#
#- Date: March 15, 2022                                                                            -#
#- Description: Keeps a log table up to date with mapping between tenants and hybrid servers       -# 
#- Dependencies:                                                                                  -#
#-  - OMSIngestionAPI Module Library (Available from PowerShell Gallery)                          -#  
####################################################################################################


Import-Module OMSIngestionAPI



#--- Get Log Analytics authentication info from variables ---#
$workspaceId = Get-AutomationVariable -Name 'OMSWorkSpaceID'
$workspaceKey = Get-AutomationVariable -Name 'OMSPrimaryKey'

$LogType = "TenantHybridServerHostingMapping"

$tenantsjson = @"
[
		{
		"Tenant":	"SSCDev",
		"Stream":	0,  
		"Server":	"LAB-PSPC-EX.LAB-PSPC-SSO.GC.CA",
		"supportTeam":	"Team 0" 
	},

	{
		"Tenant":	"AADNC ",
		"Stream":	2,
		"Server":	"NCEMINA0914.intra.pri",
		"supportTeam":	"Team 6" 
	},
	{
		"Tenant":	"AAFC", 		
		"Stream":	2,	
		"Server":	"AGONK1AWVMSP011.AGR.GC.CA",
		"supportTeam":	"Team 5" 
	},
	{
		"Tenant":	"ACOA", 		
		"Stream":	1,	
		"Server":	"SSC-ACOA-EXCH1.ACOA-APECA.GC.CA",
		"supportTeam":	"Team 4" 
	},
		{
		"Tenant":	"CSC", 		
		"Stream":	3,	
		"Server":	"",
		"supportTeam":	"Team 4" 
	},
	{
		"Tenant":	"CBSA", 		
		"Stream":	3,	
		"Server":	"",
		"supportTeam":	"Team 4" 
	},
	{
		"Tenant":	"CED", 		    
		"Stream":	2,	
		"Server":	"EX01.DEC-CED.HQ",
		"supportTeam":	"Team 1" 
	},
	{
		"Tenant":	"CFIA", 		
		"Stream":	2,	
		"Server":	"CFONK1AWVMSP001.CFIA-ACIA.inspection.gc.ca",
		"supportTeam":	"Team 5" 
	},
	{
		"Tenant":	"CNSC", 		
		"Stream":	2,	
		"Server":	"CNONK1PwvEXP001.prod.cnsc-ccsn.gc.ca",
		"supportTeam":	"Team 5" 
	},
	{
		"Tenant":	"CRA", 		   
		"Stream":	 3,	
		"Server":	"",
		"supportTeam":	"Team 4" 
	},
	{
		"Tenant":	"FINTRACC", 		   
		"Stream":	 3,	
		"Server":	"",
		"supportTeam":	"Team 4" 
	},	
	{
		"Tenant":	"CSA", 		    
		"Stream":	2,	
		"Server":	"SAQCJ3YWVEXP001.csa.space.gc.ca",
		"supportTeam":	"Team 7" 
	},
	{
		"Tenant":	"CSPS", 		
		"Stream":	2,	
		"Server":	"VKEW-STAFFS.csps-efpc.com",
		"supportTeam":	"Team 8" 
	},
	{
		"Tenant":	"DFO", 		   
		"Stream":	 3,	
		"Server":	"",
		"supportTeam":	"Team 5" 
	},
	{
		"Tenant":	"ECCC", 		
		"Stream":	2,	
		"Server":	"ECQCJ8YwvEXP006.ncr.int.ec.gc.ca",
		"supportTeam":	"Team 5" 
	},
	{
		"Tenant":	"ECCC", 		
		"Stream":	2,	
		"Server":	"ECQCJ8YwvEXP005.ncr.int.ec.gc.ca",
		"supportTeam":	"Team 5" 
	},
	{
		"Tenant":	"FIN", 		    
		"Stream":	2,	
		"Server":	"FINB-SSC-DAG01.finb.gc.ca",
		"supportTeam":	"Team 5" 
	},
	{
		"Tenant":	"GAC", 		    
		"Stream":	3,	
		"Server":	"",
		"supportTeam":	"Team 1" 
	},
	{
		"Tenant":	"HC", 		    
		"Stream":	2,	
		"Server":	"HCONK1VWVEXP001.ad.hc-sc.gc.ca",
		"supportTeam":	"Team 5" 
	},
	{
		"Tenant":	"IAAC", 		
		"Stream":	2,	
		"Server":	"ECQCJ8YwvEXP003.ncr.int.ec.gc.ca",
		"supportTeam":	"Team 5" 
	},
	{
		"Tenant":	"IAAC", 		
		"Stream":	2,	
		"Server":	"ECQCJ8YwvEXP004.ncr.int.ec.gc.ca",
		"supportTeam":	"Team 5" 
	},
	{
		"Tenant":	"INFC", 		
		"Stream":	2,	
		"Server":	"vbaw-clawed.ad.infrastructure.gc.ca",
		"supportTeam":	"Team 3" 
	},
	{
		"Tenant":	"IRB", 		    
		"Stream":	1,	
		"Server":	"NCEMIRB0037.IRB-CISR.IRBNET.GC.CA",
		"supportTeam":	"Team 6" 
	},
	{
		"Tenant":	"IRB",        
		"Stream":	1,  
		"Server":	"NCEMIRB0038.IRB-CISR.IRBNET.GC.CA",
		"supportTeam":	"Team 6" 
	},
	{
		"Tenant":	"IRCC", 		
		"Stream":	3,	
		"Server":	"",
		"supportTeam":	"Team 6" 
	},
	{
		"Tenant":	"ISED", 		
		"Stream":	2,	
		"Server":	"OTT235QEXG01.prod.prv",
		"supportTeam":	"Team 4" 
	},
	{
		"Tenant":	"LAC", 		    
		"Stream":	2,	
		"Server":	"v41exchdag01.lac-bac.int",
		"supportTeam":	"Team 3" 
	},
	{
		"Tenant":	"NRCAN", 		
		"Stream":	2,	
		"Server":	"NRONK1AwvEXP001.nrn.nrcan.gc.ca",
		"supportTeam":	"Team 5" 
	},
	{
		"Tenant":	"NRC", 		
		"Stream":	3,	
		"Server":	"",
		"supportTeam":	"Team 5" 
	},	{
		"Tenant":	"PC", 		    
		"Stream":	2,	
		"Server":	"EDC-EXCHANGE1.APCA2.GC.CA",
		"supportTeam":	"Team 6" 
	},
	{
		"Tenant":	"PC", 		    
		"Stream":	2,
			"Server":	"EDC-EXCHANGE2.APCA2.GC.CA",
		"supportTeam":	"Team 6" 
	},
	{
		"Tenant":	"PCH", 		    
		"Stream":	2,	
		"Server":	"ONEGPCH0193.in.pch.gc.ca",
		"supportTeam":	"Team 6" 
	},
	{
		"Tenant":	"PCH",        
		"Stream":	2, 
		 "Server":	"ONEGPCH0194.in.pch.gc.ca",
		"supportTeam":	"Team 6" 
	},
	{
		"Tenant":	"PCO", 		    
		"Stream":	3,	
		"Server":	"",
		"supportTeam":	"Team 3" 
	},
	{
		"Tenant":	"PSC", 		
		"Stream":	2,	
		"Server":	"WHQSSC02.ad.psc-cfp.gc.ca",
		"supportTeam":	"Team 6" 
	},
	{
		"Tenant":	"PSPC", 		
		"Stream":	3,	
		"Server":	"PSPC-HYB-01.ad.pwgsc-tpsgc.gc.ca",
		"supportTeam":	"Team 8" 
	},
	{
		"Tenant":	"PSPC", 		
		"Stream":	3,
		"Server":	"PSPC-HYB-02.ad.pwgsc-tpsgc.gc.ca",
		"supportTeam":	"Team 8" 
	},
	{
		"Tenant":	"PS", 		
		"Stream":	2,
		"Server":	"V3005R0004.PSEPC-SPPCC.NET",
		"supportTeam":	"Team 4" 
	},
	{
		"Tenant":	"SSC", 		   
		"Stream":	 1,	
		"Server":	"SSC-HYB-01.ad.pwgsc-tpsgc.gc.ca",
		"supportTeam":	"Team 8" 
	},
	{
		"Tenant":	"SSC", 		
		"Stream":	1,	
		"Server":	"SSC-HYB-02.ad.pwgsc-tpsgc.gc.ca",
		"supportTeam":	"Team 8" 
	},
	{
		"Tenant":	"STATCAN", 		
		"Stream":	2,	"Server":	"",
		"supportTeam":	"Team 1" 
	},
	{
		"Tenant":	"TC", 		    
		"Stream":	1,	
		"Server":	"NCRMXMB02A.tc.gc.ca",
		"supportTeam":	"Team 4" 
	},
	{
		"Tenant":	"VAC", 		   
		"Stream":	 1,	
		"Server":	"MNEGVAC0331.vac-acc.gc.ca",
		"supportTeam":	"Team 6" 
	},
	{
		"Tenant":	"VAC", 		    
		"Stream":	1,	
		"Server":	"MNEGVAC0332.vac-acc.gc.ca",
		"supportTeam":	"Team 6" 
	},
	{
		"Tenant":	"JUS", 		    
		"Stream":	3,	
		"Server":	"",
		"supportTeam":	"Team 3" 
	},
	{
		"Tenant":	"WD", 		    
		"Stream":	2,	
		"Server":	"CorpWDExg01.wd.gc.ca",
		"supportTeam":	"Team 1"
	}

]
"@

try {
	# Send Monitoring Data for email
	Send-OMSAPIIngestionFile -customerId $workspaceId -sharedKey $workspaceKey -body $tenantsjson -logType $logType


} 
catch {
	write-output "Unable to update mapping table"
  	write-output $_
}



