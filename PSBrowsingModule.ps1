<#
-------------------------------------------------------------------------------
Name:    Social Media Scripting Framework
Module:  Web browsing
Version: 0.5.1 BETA
Date:    2014/02/20
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
  <#
    .SYNOPSIS
      Gets the HTML Source Code for the especified URL.

    .DESCRIPTION
      Gets the HTML Source Code for the especified URL.

    .EXAMPLE
      $WebPage = Get-PageSourceCode https://twitter.com/cveira/status/275929500183830529

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>

  $LogFileName = "BrowsingModule"

  Add-Type -Assembly System.Web

  $WebClient          = New-Object System.Net.WebClient
  $WebClient.Encoding = [System.Text.Encoding]::UTF8

  try {
    $PageSourceCode   = $WebClient.DownloadString($QueryURL)
  } catch {
    "$(get-date -format u) [Get-PageSourceCode] - Unable to retrieve web page: $QueryURL" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    Write-Debug "[Get-PageSourceCode] - Unable to retrieve web page: $QueryURL"

    return $null
  }

  $PageSourceCode
}


function Get-PageSourceCodeFromIE( [string] $QueryURL ) {
  <#
    .SYNOPSIS
      Gets the HTML Source Code for the especified URL.

    .DESCRIPTION
      Gets the HTML Source Code for the especified URL. This function leverages your existing browser session cookies.

    .EXAMPLE
      $WebPage = Get-PageSourceCodeFromIE https://twitter.com/cveira/status/275929500183830529

    .NOTES
      Low-level function.

      WARNING: This function doesn't support concurrency. No other IE instances should be running at the same time. They could be killed without saving the state of existing web application sessions!

    .LINK
      N/A
  #>


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


function Open-WebPage( [string] $QueryURL ) {
  <#
    .SYNOPSIS
      Opens a new instance of Internet Explorer with the especified URL.

    .DESCRIPTION
      Opens a new instance of Internet Explorer with the especified URL. This function leverages your existing browser session cookies.

    .EXAMPLE
      Open-WebPage https://twitter.com/cveira/status/275929500183830529

    .NOTES
      Low-level function.

      WARNING: This function doesn't support concurrency. No other IE instances should be running at the same time. They could be killed without saving the state of existing web application sessions!

    .LINK
      N/A
  #>


  $IE         = New-Object -ComObject InternetExplorer.Application
  $IE.Visible = $true
  $IE.Navigate($QueryURL)
}