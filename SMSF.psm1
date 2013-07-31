$InstallDir = split-path -parent $MyInvocation.MyCommand.Definition

. $InstallDir\SMSF-security.ps1
. $InstallDir\SMSF-settings.ps1
. $InstallDir\SMSF-functions.ps1

. $InstallDir\PSBrowsingModule.ps1

. $InstallDir\PSTwitterModule.ps1
. $InstallDir\PSFacebookModule.ps1
. $InstallDir\PSLinkedInModule.ps1
. $InstallDir\PSBitLyModule.ps1

. $InstallDir\PSDataSetModule.ps1
. $InstallDir\PSExcelModule.ps1