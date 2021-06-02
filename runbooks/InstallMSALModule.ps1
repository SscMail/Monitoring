if (Get-Module -ListAvailable -Name Az.Automation) {
#    Write-Host "Module exists"
} 
else {
#    Write-Host "Module does not exist. Downloading module from https://www.powershellgallery.com/packages/MSAL.PS “
    Install-module -Name Az.Automation
}
