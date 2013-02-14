<#
-------------------------------------------------------------------------------
Name:    Social Media Scripting Framework
Module:  Web browsing
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


function Get-PageSourceCode( [string] $QueryURL ) {
  # Get-PageSourceCode https://twitter.com/cveira/status/275929500183830529

  Add-Type -Assembly System.Web

  $WebClient          = New-Object System.Net.WebClient
  $WebClient.Encoding = [System.Text.Encoding]::UTF8
  $PageSourceCode     = $WebClient.DownloadString($QueryURL)

  $PageSourceCode
}


function Get-PageSourceCodeFromIE( [string] $QueryURL ) {
  # This function takes advantage of your existing browser cookies.
  # Get-PageSourceCodeFromIE https://twitter.com/cveira/status/275929500183830529

  # WARNING: execution pre-condicion: no concurrency! No other IE instances should be running. They could be killed without saving!


  $IE_READYSTATE_COMPLETE = 4
  $TimeToWait             = 3

  $IE = New-Object -ComObject InternetExplorer.Application
  $IE.Navigate($QueryURL)

  while ($IE.ReadyState -ne $IE_READYSTATE_COMPLETE) {
    Start-Sleep -Seconds $TimeToWait
  }

  $PageSourceCode = $IE.Document.body.innerHTML
  $IE.Quit()

  $IEClosedOk = ( [System.Runtime.Interopservices.Marshal]::ReleaseComObject( [System.__ComObject] $IE ) -eq 0 )

  if ( !$IEClosedOk ) {
    $IEProcess = Get-Process iexplore
    $IEProcess | ForEach-Object { Stop-Process ( $_.id ) }
  }

  [System.GC]::Collect()
  [System.GC]::WaitForPendingFinalizers()

  $PageSourceCode
}