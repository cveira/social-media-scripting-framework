$InstallDir   = $( Get-ChildItem $MyInvocation.InvocationName | Select-Object Directory |
                   Format-Table -AutoSize -HideTableHeaders | Out-String ).Trim()

if ( $InstallDir.Split(":").Length -gt 2 ) {
  $InstallDir = $( Get-Location | Select-Object Path |
                   Format-Table -AutoSize -HideTableHeaders | Out-String ).Trim()
}


# . $InstallDir\SMSF-settings.ps1
. $InstallDir\SMSF-functions.ps1

. $InstallDir\PSBrowsingModule.ps1

. $InstallDir\PSTwitterModule.ps1
. $InstallDir\PSFacebookModule.ps1
. $InstallDir\PSLinkedInModule.ps1
. $InstallDir\PSBitLyModule.ps1

. $InstallDir\PSDataSetModule.ps1
. $InstallDir\PSExcelModule.ps1