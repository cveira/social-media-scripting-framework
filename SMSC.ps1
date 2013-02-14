<#
-------------------------------------------------------------------------------
Name:    Social Media Scripting Framework
Module:  Social Media Scripting Console
Version: 0.2 BETA
Date:    2013/02/03
Author:  Carlos Veira Lorenzo
         e-mail:   cveira [at] thinkinbig [dot] org
         blog:     thinkinbig.org
         twitter:  @cveira
         facebook: www.facebook.com/cveira
         Google+:  gplus.to/cveira
         LinkedIn: es.linkedin.com/in/cveira/
-------------------------------------------------------------------------------
Support:
  http://thinkinbig.org/oms/

Forums & Communities:
  facebook.com/ThinkInBig
  gplus.to/ThinkInBig
  http://bit.ly/SMSF-Forum
-------------------------------------------------------------------------------
Code Mirror Sites:
  https://smsf.codeplex.com/
  https://github.com/cveira/social-media-scripting-framework
  https://code.google.com/p/social-media-scripting-framework/
  http://sourceforge.net/projects/smsf/
-------------------------------------------------------------------------------
Social Media Scripting Framework.
Copyright (C) 2013 Carlos Veira Lorenzo.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
-------------------------------------------------------------------------------
#>


$COLOR_PROMPT               = 'Magenta'
$COLOR_BRIGHT               = 'Yellow'
$COLOR_DARK                 = 'DarkGray'
$COLOR_RESULT               = 'Green' # 'DarkCyan'
$COLOR_NORMAL               = 'White'
$COLOR_ERROR                = 'Red'
$COLOR_ENPHASIZE            = 'Magenta'

$ConsoleHeader = @"
  Social Media Scripting Console
  Carlos Veira Lorenzo - [http://thinkinbig.org]
  -------------------------------------------------------------------------------------------
  Social Media Scripting Framework v0.2b, Copyright (C) 2013 Carlos Veira Lorenzo.
  This software come with ABSOLUTELY NO WARRANTY. This is free
  software under GPL 2.0 license terms and conditions.
  -------------------------------------------------------------------------------------------
"@

Write-Host
Write-Host -foregroundcolor $COLOR_BRIGHT $ConsoleHeader
Write-Host


$InstallDir                 = $( Get-ChildItem $MyInvocation.InvocationName | Select-Object Directory |
                                 Format-Table -AutoSize -HideTableHeaders | Out-String ).Trim()

if ( $InstallDir.Split(":").Length -gt 2 ) {
  $InstallDir               = $( Get-Location | Select-Object Path |
                                 Format-Table -AutoSize -HideTableHeaders | Out-String ).Trim()
}


if ( Test-Path $InstallDir\SMSF.psm1 ) {
  Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "  + Loading Social Media commands and functions... "

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

  # Import-Module $InstallDir\SMSF.psm1 -DisableNameChecking -force

  Write-Host -foregroundcolor $COLOR_BRIGHT "done"


  Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "  + Checking environment configuration... "

  Test-SMSFSettings

  Write-Host -foregroundcolor $COLOR_BRIGHT "done"

  Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "  + Connecting to Social Networks... "

  $FBConnection = New-FBConnection -AccessToken $FBAccessToken

  Write-Host -foregroundcolor $COLOR_BRIGHT "done"
} else {
  Write-Host -foregroundcolor $COLOR_ERROR  "  + ERROR: can't find/load module's files:             $InstallDir"
  Write-Host -foregroundcolor $COLOR_NORMAL "    + INFO: you will be left on a regular PowerShell Session..."
}


Write-Host
Write-Host -foregroundcolor $COLOR_BRIGHT '  -------------------------------------------------------------------------------------------'
Write-Host


$OriginalPrompt = Get-Content function:prompt

function prompt() {
  $(
    Write-Host -foregroundcolor $COLOR_DARK "  >> $( Get-Location )"
    Write-Host -foregroundcolor $COLOR_PROMPT -noNewLine "  >> SMSC [$NestedPromptLevel]"
  ) + " > "
}

$host.EnterNestedPrompt()

. Invoke-Expression "function prompt() { $OriginalPrompt }"