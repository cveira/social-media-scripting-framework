<#
-------------------------------------------------------------------------------
Name:    Social Media Scripting Framework
Module:  Social Media Scripting Console
Version: 0.5.1 BETA
Date:    2014/02/02
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
  ----------------------------------------------------------------------------------------------
  Social Media Scripting Framework v0.5.1 BETA
  Copyright (C) 2014 Carlos Veira Lorenzo.
  This software come with ABSOLUTELY NO WARRANTY. This is free software under a GPL 2.0 license.
  ----------------------------------------------------------------------------------------------
"@

Write-Host
Write-Host -foregroundcolor $COLOR_BRIGHT $ConsoleHeader
Write-Host

$InstallDir                 = Split-Path -parent $MyInvocation.MyCommand.Definition
$BinDir                     = $InstallDir  + "\bin"
$LogsDir                    = $InstallDir  + "\logs"
$ProfilesDir                = $InstallDir  + "\profiles"
$MasterProfileDir           = $ProfilesDir + "\master"

Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "  + Loading Core Components... "

. $InstallDir\CoreDataStructures.ps1
. $InstallDir\CoreModule.ps1
. $InstallDir\HelperModule.ps1

( Get-ChildItem $InstallDir\PS*.ps1 ).Name | ForEach-Object { . $InstallDir\$_ }

Write-Host -foregroundcolor $COLOR_BRIGHT "done"

Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "  + Loading Core Settings... "

. $InstallDir\settings.ps1

Write-Host -foregroundcolor $COLOR_BRIGHT "done"


. Set-SMProfile -name $DefaultProfileName

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