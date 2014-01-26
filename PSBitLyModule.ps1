<#
-------------------------------------------------------------------------------
Name:    Social Media Scripting Framework
Module:  Bitly.com
Version: 0.5 BETA
Date:    2014/01/20
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


function Get-BLClicksFromPage( [ref] $PageSourceCode ) {
  <#
    .SYNOPSIS
      Parses the raw HTML contents of a Bit.ly link information page to get the number of Clicks logged.

    .DESCRIPTION
      Parses the raw HTML contents of a Bit.ly link information page to get the number of Clicks logged.

    .EXAMPLE
      $SourceCode = Get-PageSourceCode https://bitly.com/Vk1V37+
      Get-BLClicksFromPage ([ref] $SourceCode)

    .NOTES
      Low-level function. Depends on Get-PageSourceCode.

    .LINK
      N/A
  #>


  [string] $ClicksContentPattern = '(?s)<li[^>]*clicks orange[^>]*>(?<ClickThroughStats>.*?)</li>.*?'
  [string] $ClicksCountPattern   = '(?s)<span[^>]*global_info[^>]*>(?<ClickCountStats>.*?)</span>.*?'


  $ClickThroughCount             = 0

  if ( $PageSourceCode.Value -match $ClicksContentPattern ) {
    if ( $Matches.ClickThroughStats -match $ClicksCountPattern ) {
      $ClickThroughCount = [int] $Matches.ClickCountStats.Trim()
    }
  }

  $ClickThroughCount
}


function Get-BLOAuthToken ( [string] $UserName, [string] $Password ) {
  <#
    .SYNOPSIS
      Displays the OAuth Access Token for the especified credentials.

    .DESCRIPTION
      Displays the OAuth Access Token for the especified credentials.

    .EXAMPLE
      Get-BLOAuthToken user P4sw0rd

    .NOTES
      High-level function. It is used during initial configuration or whenever there is a need to refresh connection details in the configuration file.

    .LINK
      http://dev.bitly.com/authentication.html
  #>


  & $BinDir\curl.exe -u "$($UserName):$($Password)" -k -X POST https://api-ssl.bitly.com/oauth/access_token
}


function Get-BLLinkMetrics ( [string] $link, [switch] $IncludeAll) {
  <#
    .SYNOPSIS
      Retrieves all the Track & Trace information associated to a given Bit.ly link.

    .DESCRIPTION
      Retrieves all the Track & Trace information associated to a given Bit.ly link.

    .EXAMPLE
      $LinkMetrics = Get-BLLinkMetrics https://bitly.com/Yl1zGu

    .NOTES
      High-level function.

    .LINK
      http://dev.bitly.com/authentication.html
      http://dev.bitly.com/rate_limiting.html
      http://dev.bitly.com/best_practices.html
      http://dev.bitly.com/link_metrics.html
  #>

  $link = $link -replace "\+/global",""
  $link = $link -replace "\+",""
  $link = $link -replace "http://","https://"

  Write-Debug "[Get-BLLinkMetrics] Getting Metrics for Clicks"
  Write-Debug "[Get-BLLinkMetrics]   API Call: https://api-ssl.bitly.com/v3/link/clicks?access_token=$( $connections.BitLy.AccessToken )&link=$( EscapeDataStringRfc3986 $link )"

  $clicks                = ( & $BinDir\curl.exe -s -k -X GET $("https://api-ssl.bitly.com/v3/link/clicks?access_token=" + $connections.BitLy.AccessToken + "&link=" + $( EscapeDataStringRfc3986 $link )) | ConvertFrom-JSON ).data

  Start-Sleep -Seconds $connections.BitLy.ApiDelay

  Write-Debug "[Get-BLLinkMetrics] Getting Metrics for Countries"
  Write-Debug "[Get-BLLinkMetrics]   API Call: https://api-ssl.bitly.com/v3/link/countries?access_token=$( $connections.BitLy.AccessToken )&link=$( EscapeDataStringRfc3986 $link )"

  $countries             = ( & $BinDir\curl.exe -s -k -X GET $("https://api-ssl.bitly.com/v3/link/countries?access_token=" + $connections.BitLy.AccessToken + "&link=" + $( EscapeDataStringRfc3986 $link )) | ConvertFrom-JSON ).data

  Start-Sleep -Seconds $connections.BitLy.ApiDelay

  Write-Debug "[Get-BLLinkMetrics] Getting Metrics for Referring Domains"
  Write-Debug "[Get-BLLinkMetrics]   API Call: https://api-ssl.bitly.com/v3/link/referring_domains?access_token=$( $connections.BitLy.AccessToken )&link=$( EscapeDataStringRfc3986 $link )"

  $referring_domains     = ( & $BinDir\curl.exe -s -k -X GET $("https://api-ssl.bitly.com/v3/link/referring_domains?access_token=" + $connections.BitLy.AccessToken + "&link=" + $( EscapeDataStringRfc3986 $link )) | ConvertFrom-JSON ).data

  Start-Sleep -Seconds $connections.BitLy.ApiDelay

  Write-Debug "[Get-BLLinkMetrics] Getting related ShortLinks"
  Write-Debug "[Get-BLLinkMetrics]   API Call: https://api-ssl.bitly.com/v3/link/encoders?access_token=$( $connections.BitLy.AccessToken )&link=$( EscapeDataStringRfc3986 $link )"

  $encoders              = ( & $BinDir\curl.exe -s -k -X GET $("https://api-ssl.bitly.com/v3/link/encoders?access_token=" + $connections.BitLy.AccessToken + "&link=" + $( EscapeDataStringRfc3986 $link )) | ConvertFrom-JSON ).data

  Start-Sleep -Seconds $connections.BitLy.ApiDelay

  Write-Debug "[Get-BLLinkMetrics] Getting Metrics for Shares"
  Write-Debug "[Get-BLLinkMetrics]   API Call: https://api-ssl.bitly.com/v3/link/shares?access_token=$( $connections.BitLy.AccessToken )&link=$( EscapeDataStringRfc3986 $link )"

  $shares                = ( & $BinDir\curl.exe -s -k -X GET $("https://api-ssl.bitly.com/v3/link/shares?access_token=" + $connections.BitLy.AccessToken + "&link=" + $( EscapeDataStringRfc3986 $link )) | ConvertFrom-JSON ).data


  if ( $IncludeAll ) {
    Write-Debug "[Get-BLLinkMetrics] Getting Metrics for Referrers"
    Write-Debug "[Get-BLLinkMetrics]   API Call: https://api-ssl.bitly.com/v3/link/referrers?access_token=$( $connections.BitLy.AccessToken )&link=$( EscapeDataStringRfc3986 $link )"

    $referrers           = ( & $BinDir\curl.exe -s -k -X GET $("https://api-ssl.bitly.com/v3/link/referrers?access_token=" + $connections.BitLy.AccessToken + "&link=" + $( EscapeDataStringRfc3986 $link )) | ConvertFrom-JSON ).data

    Start-Sleep -Seconds $connections.BitLy.ApiDelay

    Write-Debug "[Get-BLLinkMetrics] Getting Metrics for Referrers by Domain"
    Write-Debug "[Get-BLLinkMetrics]   API Call: https://api-ssl.bitly.com/v3/link/referrers_by_domain?access_token=$( $connections.BitLy.AccessToken )&link=$( EscapeDataStringRfc3986 $link )"

    $referrers_by_domain = ( & $BinDir\curl.exe -s -k -X GET $("https://api-ssl.bitly.com/v3/link/referrers_by_domain?access_token=" + $connections.BitLy.AccessToken + "&link=" + $( EscapeDataStringRfc3986 $link )) | ConvertFrom-JSON ).data

    Start-Sleep -Seconds $connections.BitLy.ApiDelay

    Write-Debug "[Get-BLLinkMetrics] Getting Metrics for related ShortLinks"
    Write-Debug "[Get-BLLinkMetrics]   API Call: https://api-ssl.bitly.com/v3/link/encoders_count?access_token=$( $connections.BitLy.AccessToken )&link=$( EscapeDataStringRfc3986 $link )"

    $encoders_count      = ( & $BinDir\curl.exe -s -k -X GET $("https://api-ssl.bitly.com/v3/link/encoders_count?access_token=" + $connections.BitLy.AccessToken + "&link=" + $( EscapeDataStringRfc3986 $link )) | ConvertFrom-JSON ).data
  }


  New-Object PSObject -Property @{
    Clicks            = $clicks
    Countries         = $countries
    Referrers         = $referrers
    ReferrersByDomain = $referrers_by_domain
    ReferringDomains  = $referring_domains
    Encoders          = $encoders
    EncodersCount     = $encoders_count
    Shares            = $shares
  }
}


function Get-BLLinkGlobalMetrics ( [string] $link ) {
  <#
    .SYNOPSIS
      Retrieves all the Global Track & Trace information associated to a given Bit.ly link.

    .DESCRIPTION
      Retrieves all the Global Track & Trace information associated to a given Bit.ly link.

    .EXAMPLE
      $LinkGlobalMetrics = Get-BLLinkGlobalMetrics https://bitly.com/Yl1zGu

    .NOTES
      High-level function.

    .LINK
      N/A
  #>

  $link = $link -replace "\+/global",""
  $link = $link -replace "\+",""
  $link = $link -replace "http://","https://"

  Write-Debug "[Get-BLLinkGlobalMetrics] Resolving the GlobalLink"

  $GlobalLink = & $BinDir\curl.exe -s -k -X GET $("https://api-ssl.bitly.com/v3/link/encoders?access_token=" + $connections.BitLy.AccessToken + "&link=" + $( EscapeDataStringRfc3986 $link ) ) | ConvertFrom-JSON

  if ( $GlobalLink.status_code -eq "200" ) {
    Write-Debug "[Get-BLLinkGlobalMetrics]   GlobalLink: $( $GlobalLink.data.aggregate_link )"

    Get-BLLinkMetrics $GlobalLink.data.aggregate_link
  } else {
    Write-Debug "[Get-BLLinkGlobalMetrics] Link metrics couldn't be retrieved."

    return $null
  }

  # Get-BLLinkMetrics ( ( & $BinDir\curl.exe -s -k -X GET $("https://api-ssl.bitly.com/v3/link/encoders?access_token=" + $connections.BitLy.AccessToken + "&link=" + $( EscapeDataStringRfc3986 $link )) | ConvertFrom-Json ).data.aggregate_link )
}


function Measure-BLImpact( [string[]] $from = @(), [string] $by = "link" ) {
  <#
    .SYNOPSIS
      Computes and displays the aggregated impact of a number of Bit.ly links either by Link (default), Country or by Referrring Domain.

    .DESCRIPTION
      Computes and displays the aggregated impact of a number of Bit.ly links either by Link (default), Country or by Referrring Domain.

    .EXAMPLE
      $LinkImpact = Measure-BLImpact -from $links
      $LinkImpact = Measure-BLImpact -from $links -by link
      $LinkImpact = Measure-BLImpact -from $links -by country
      $LinkImpact = Measure-BLImpact -from $links -by domains

      $LinkImpact = $links | Measure-BLImpact
      $LinkImpact = $links | Measure-BLImpact -by link
      $LinkImpact = $links | Measure-BLImpact -by country
      $LinkImpact = $links | Measure-BLImpact -by domains

    .NOTES
      High-level function.

    .LINK
      N/A
  #>

  begin {
    $LogFileName          = "BitlyModule"

    $countries            = @{}
    $referrers            = @{}

    [string[]] $links     = @()
    [PSObject[]] $ranking = @()

    if ( $from.count -ne 0 ) {
      $links              = $from
    }
  }

  process {
    if ( $from.count -eq 0 ) {
      if ( $_ -ne $null ) { $links += $_ }
    }
  }

  end {
    $i                    = 1
    $ExecutionTime        = [Diagnostics.Stopwatch]::StartNew()
    $ExecutionTime.Stop()


    switch ( $by ) {
      "link" {
        foreach ( $CurrentLink in $links ) {
          $ExecutionTime  = [Diagnostics.Stopwatch]::StartNew()

          Write-Progress -Activity "Processing Links ..." -Status "Progress: $i / $($links.Count) - ETC: $( '{0:#0.00}' -f (( $links.Count - $i ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes - Time Elapsed: $( '{0:#0.00}' -f (( $i - 1 ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes" -PercentComplete ( ( $i / $links.Count ) * 100 )

          $CurrentMetrics = New-Object PSObject -Property @{
            Link          = $CurrentLink.Trim()
            ClickThroughs = ( Get-BLLinkGlobalMetrics $CurrentLink.Trim() ).clicks.link_clicks
          }

          if ( $CurrentMetrics -ne $null ) {
            Write-Debug "[Measure-BLImpact] Link metrics obtained."
            # Write-Debug "[Measure-BLImpact]   Link:           $( $CurrentMetrics.Link )"
            # Write-Debug "[Measure-BLImpact]   ClickThroughts: $( $CurrentMetrics.ClickThroughs )"

            if ( $CurrentMetrics.ClickThroughs -eq $null ) { $CurrentMetrics.ClickThroughs = 0 }

            $CurrentMetrics
          } else {
            "$(get-date -format u) [Measure-BLImpact] Skipping Link: metrics couldn't be obtained." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
            "$(get-date -format u) [Measure-BLImpact]   Link:           $( $CurrentLink.Trim() )"   >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

            Write-Debug "[Measure-BLImpact] Skipping Link: metrics couldn't be obtained."
            Write-Debug "[Measure-BLImpact]   Link:           $( $CurrentLink.Trim() )"
          }

          $ExecutionTime.Stop()

          $i++
        }
      }

      "country" {
        foreach ( $CurrentLink in $links ) {
          $ExecutionTime.Stop()

          Write-Progress -Activity "Processing Links ..." -Status "Progress: $i / $($links.Count) - ETC: $( '{0:#0.00}' -f (( $links.Count - $i ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes - Time Elapsed: $( '{0:#0.00}' -f (( $i - 1 ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes" -PercentComplete ( ( $i / $links.Count ) * 100 )

          $ExecutionTime      = [Diagnostics.Stopwatch]::StartNew()

          $CurrentMetrics     = Get-BLLinkGlobalMetrics $CurrentLink

          if ( $CurrentMetrics -ne $null ) {
            Write-Debug "[Measure-BLImpact] Link metrics obtained."
            # Write-Debug "[Measure-BLImpact]   Countries:      $( $CurrentMetrics.Countries.countries.Count )"

            $CurrentMetrics.Countries.countries | ForEach-Object {
              if ( $countries.ContainsKey("$($_.country)") ) {
                $countries["$($_.country)"] = $countries["$($_.country)"] + $_.clicks
              } else {
                $countries.Add("$($_.country)", $_.clicks)
              }
            }
          } else {
            "$(get-date -format u) [Measure-BLImpact] Skipping Link: metrics couldn't be obtained." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
            "$(get-date -format u) [Measure-BLImpact]   Link:           $( $CurrentLink.Trim() )"   >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

            Write-Debug "[Measure-BLImpact] Skipping Link: metrics couldn't be obtained."
            Write-Debug "[Measure-BLImpact]   Link:           $( $CurrentLink.Trim() )"
          }

          $i++
        }

        $countries.keys | ForEach-Object {
          $ranking += New-Object PSObject -Property @{
            Country = $_
            Clicks  = $countries.$_
          }
        }

        $ranking
      }

      "domains" {
        foreach ( $CurrentLink in $links ) {
          $ExecutionTime.Stop()

          Write-Progress -Activity "Processing Links ..." -Status "Progress: $i / $($links.Count) - ETC: $( '{0:#0.00}' -f (( $links.Count - $i ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes - Time Elapsed: $( '{0:#0.00}' -f (( $i - 1 ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes" -PercentComplete ( ( $i / $links.Count ) * 100 )

          $ExecutionTime      = [Diagnostics.Stopwatch]::StartNew()

          $CurrentMetrics     = Get-BLLinkGlobalMetrics $CurrentLink

          if ( $CurrentMetrics -ne $null ) {
            Write-Debug "[Measure-BLImpact] Link metrics obtained."
            # Write-Debug "[Measure-BLImpact]   Countries:      $( $CurrentMetrics.ReferringDomains.referring_domains.Count )"

            $CurrentMetrics.ReferringDomains.referring_domains | ForEach-Object {
              if ( $referrers.ContainsKey("$($_.domain)") ) {
                $referrers["$($_.domain)"] = $referrers["$($_.domain)"] + $_.clicks
              } else {
                $referrers.Add("$($_.domain)", $_.clicks)
              }
            }
          } else {
            "$(get-date -format u) [Measure-BLImpact] Skipping Link: metrics couldn't be obtained." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
            "$(get-date -format u) [Measure-BLImpact]   Link:           $( $CurrentLink.Trim() )"   >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

            Write-Debug "[Measure-BLImpact] Skipping Link: metrics couldn't be obtained."
            Write-Debug "[Measure-BLImpact]   Link:           $( $CurrentLink.Trim() )"
          }

          $i++
        }

        $referrers.keys | ForEach-Object {
          $ranking += New-Object PSObject -Property @{
            Domain  = $_
            Clicks  = $referrers.$_
          }
        }

        $ranking
      }
    }
  }
}