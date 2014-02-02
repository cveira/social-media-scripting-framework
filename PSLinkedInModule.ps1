<#
-------------------------------------------------------------------------------
Name:    Social Media Scripting Framework
Module:  LinkedIn
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

# https://developers.linkedin.com/documents/throttle-limits
# https://developers.linkedin.com/documents/request-and-response-headers
# https://developers.linkedin.com/documents/linkedin-api-resource-map


$LINApiQuotaStatus = @{
  CurrentDate                        = ( Get-Date ).Date

  ApiUserGetOwnProfileDailyLimit     = 0, $connections.LinkedIn.ApiUserGetOwnProfileDailyLimit
  ApiUserSetPostDailyLimit           = 0, $connections.LinkedIn.ApiUserSetPostDailyLimit
  ApiuserSetStatusUpdatesDailyLimit  = 0, $connections.LinkedIn.ApiuserSetStatusUpdatesDailyLimit
  ApiUserSetNetworkUpdatesDailyLimit = 0, $connections.LinkedIn.ApiUserSetNetworkUpdatesDailyLimit
  ApiUserSetMessagingDailyLimit      = 0, $connections.LinkedIn.ApiUserSetMessagingDailyLimit
  ApiUserSetInvitesDailyLimit        = 0, $connections.LinkedIn.ApiUserSetInvitesDailyLimit

  ApiNetworkGetUpdatesDailyLimit     = 0, $connections.LinkedIn.ApiNetworkGetUpdatesDailyLimit
  ApiNetworkGetContactsDailyLimit    = 0, $connections.LinkedIn.ApiNetworkGetContactsDailyLimit
  ApiNetworkGetSearchesDailyLimit    = 0, $connections.LinkedIn.ApiNetworkGetSearchesDailyLimit
  ApiNetworkGetProfilesDailyLimit    = 0, $connections.LinkedIn.ApiNetworkGetProfilesDailyLimit

  ApiGroupGetDetailsDailyLimit       = 0, $connections.LinkedIn.ApiGroupGetDetailsDailyLimit
  ApiGroupGetPostDailyLimit          = 0, $connections.LinkedIn.ApiGroupGetPostDailyLimit
  ApiGroupGetCommentsDailyLimit      = 0, $connections.LinkedIn.ApiGroupGetCommentsDailyLimit
  ApiGroupSetPostDailyLimit          = 0, $connections.LinkedIn.ApiGroupSetPostDailyLimit

  ApiCompanyGetProfilesDailyLimit    = 0, $connections.LinkedIn.ApiCompanyGetProfilesDailyLimit
  ApiCompanyGetPostsDailyLimit       = 0, $connections.LinkedIn.ApiCompanyGetPostsDailyLimit
  ApiCompanyGetSearchesDailyLimit    = 0, $connections.LinkedIn.ApiCompanyGetSearchesDailyLimit
}


function New-LINConnection() {
  <#
    .SYNOPSIS
      Creates a new connection to LinkedIn and displays the Access Token associated to it.

    .DESCRIPTION
      Creates a new connection to LinkedIn and displays the Access Token associated to it.

    .EXAMPLE
      New-LINConnection

    .NOTES
      High-level function. It is used during initial configuration or whenever there is a need to refresh connection details in the configuration file.

    .LINK
      https://developers.linkedin.com/documents/authentication
      https://developers.linkedin.com/documents/authentication#granting
  #>


  # $DebugPreference = "Continue"

  $TimeToWait                     = 10 # $connections.LinkedIn.ApiDelay
  $MaxWaitCount                   = 60
  $WaitCount                      = 0

  # Build the Authentication request URL
  $OAuthNonce             = Set-OAuthNonce
  $OAuthScope             = EscapeDataStringRfc3986 'r_fullprofile r_emailaddress r_network r_contactinfo rw_nus rw_groups w_messages'
  $AuthenticationRequest  = '{0}?client_id={1}&redirect_uri={2}&response_type=code&state={3}&scope={4}' -f $connections.LinkedIn.AuthenticationEndpoint, $connections.LinkedIn.ApiKey, $connections.LinkedIn.RedirectUri, $OAuthNonce, $OAuthScope

  Write-Debug "[INFO] Authentication Request is: $AuthenticationRequest"

  # Place the authentication request. The user might have to enter his user credentials on the presented web page.
  $IE                     = New-Object -ComObject InternetExplorer.Application
  $IE.Visible             = $true
  $IE.Navigate($AuthenticationRequest)

  # Sleep the script for $X seconds until callback URL has been reached
  # NOTE: If user cancels authorization, this condition will not be satisifed
  while ($IE.LocationUrl -notmatch 'code=') {
    Write-Debug "[INFO] Sleeping $TimeToWait seconds for access URL"
    Start-Sleep -Seconds $TimeToWait

    if ( $WaitCount -ge $MaxWaitCount ) {
      return $null
    } else {
      $WaitCount++
    }
  }

  # Build the Authorization request URL
  $AuthenticationCode = $IE.LocationUrl.Split("&")[0].Split("=")[1]
  $IE.Quit()

  $AuthorizationRequest   = '{0}&code={1}&redirect_uri={2}&client_id={3}&client_secret={4}' -f $connections.LinkedIn.AuthorizationEndpoint, $AuthenticationCode, $connections.LinkedIn.RedirectUri, $connections.LinkedIn.ApiKey, $connections.LinkedIn.SecretKey

  Write-Debug "[INFO] Authorization Request is: $AuthorizationRequest"

  $AuthorizationResponse = & $BinDir\curl.exe -s -k -X POST $AuthorizationRequest

  Write-Debug "[INFO] Authorization Response is: $AuthorizationResponse"

  ( $AuthorizationResponse | ConvertFrom-Json ).access_token # This token usually expires in 60 days

  # $DebugPreference = "SilentlyContinue"
}


function Update-RawLINApiQuotaStatus( [string] $ApiLimitName ) {
  <#
    .SYNOPSIS
      Updates the especified entry on API Quota Status Table.

    .DESCRIPTION
      Updates the especified entry on API Quota Status Table. The API Quota Status Table keeps track of the number of API calls issued in order to honor the current rate limits.

    .EXAMPLE
      Update-RawLINApiQuotaStatus ApiUserGetOwnProfileDailyLimit

    .NOTES
      Low-level function (API).

    .LINK
      N/A
  #>


  if ( ( ( Get-Date ).Date - $LINApiQuotaStatus.CurrentDate ).Days -gt 0 ) {
    . Initialize-RawLINApiQuotaStatus
  }

  $LINApiQuotaStatus.$ApiLimitName[0] += 1
}


function Get-RawLINApiQuotaStatus( [string] $ApiLimitName ) {
  <#
    .SYNOPSIS
      Retrieves the especified entry on API Quota Status Table.

    .DESCRIPTION
      Retrieves the especified entry on API Quota Status Table. The API Quota Status Table keeps track of the number of API calls issued in order to honor the current rate limits.

    .EXAMPLE
      Get-RawLINApiQuotaStatus ApiUserGetOwnProfileDailyLimit

    .NOTES
      Low-level function (API).

    .LINK
      N/A
  #>


  New-Object PSObject -Property @{
    CurrentValue = $LINApiQuotaStatus.$ApiLimitName[0]
    MaxValue     = $LINApiQuotaStatus.$ApiLimitName[1]
  }
}


function Initialize-RawLINApiQuotaStatus() {
  <#
    .SYNOPSIS
      Initializes the API Quota Status Table.

    .DESCRIPTION
      Initializes the API Quota Status Table. The API Quota Status Table keeps track of the number of API calls issued in order to honor the current rate limits.

    .EXAMPLE
      Initialize-RawLINApiQuotaStatus

    .NOTES
      Low-level function (API).

    .LINK
      N/A
  #>


  $LINApiQuotaStatus.CurrentDate                        = ( Get-Date ).Date

  $LINApiQuotaStatus.ApiUserGetOwnProfileDailyLimit     = 0, $connections.LinkedIn.ApiUserGetOwnProfileDailyLimit
  $LINApiQuotaStatus.ApiUserSetPostDailyLimit           = 0, $connections.LinkedIn.ApiUserSetPostDailyLimit
  $LINApiQuotaStatus.ApiuserSetStatusUpdatesDailyLimit  = 0, $connections.LinkedIn.ApiuserSetStatusUpdatesDailyLimit
  $LINApiQuotaStatus.ApiUserSetNetworkUpdatesDailyLimit = 0, $connections.LinkedIn.ApiUserSetNetworkUpdatesDailyLimit
  $LINApiQuotaStatus.ApiUserSetMessagingDailyLimit      = 0, $connections.LinkedIn.ApiUserSetMessagingDailyLimit
  $LINApiQuotaStatus.ApiUserSetInvitesDailyLimit        = 0, $connections.LinkedIn.ApiUserSetInvitesDailyLimit

  $LINApiQuotaStatus.ApiNetworkGetUpdatesDailyLimit     = 0, $connections.LinkedIn.ApiNetworkGetUpdatesDailyLimit
  $LINApiQuotaStatus.ApiNetworkGetContactsDailyLimit    = 0, $connections.LinkedIn.ApiNetworkGetContactsDailyLimit
  $LINApiQuotaStatus.ApiNetworkGetSearchesDailyLimit    = 0, $connections.LinkedIn.ApiNetworkGetSearchesDailyLimit
  $LINApiQuotaStatus.ApiNetworkGetProfilesDailyLimit    = 0, $connections.LinkedIn.ApiNetworkGetProfilesDailyLimit

  $LINApiQuotaStatus.ApiGroupGetDetailsDailyLimit       = 0, $connections.LinkedIn.ApiGroupGetDetailsDailyLimit
  $LINApiQuotaStatus.ApiGroupGetPostDailyLimit          = 0, $connections.LinkedIn.ApiGroupGetPostDailyLimit
  $LINApiQuotaStatus.ApiGroupGetCommentsDailyLimit      = 0, $connections.LinkedIn.ApiGroupGetCommentsDailyLimit
  $LINApiQuotaStatus.ApiGroupSetPostDailyLimit          = 0, $connections.LinkedIn.ApiGroupSetPostDailyLimit

  $LINApiQuotaStatus.ApiCompanyGetProfilesDailyLimit    = 0, $connections.LinkedIn.ApiCompanyGetProfilesDailyLimit
  $LINApiQuotaStatus.ApiCompanyGetPostsDailyLimit       = 0, $connections.LinkedIn.ApiCompanyGetPostsDailyLimit
  $LINApiQuotaStatus.ApiCompanyGetSearchesDailyLimit    = 0, $connections.LinkedIn.ApiCompanyGetSearchesDailyLimit
}


function Get-RawLINGroupIdByName( [string] $name ) {
  <#
    .SYNOPSIS
      Retrieves the Group Id that corresponds to a given Group Name.

    .DESCRIPTION
      Retrieves the Group Id that corresponds to a given Group Name.

    .EXAMPLE
      $MyGroupId = Get-RawLINGroupIdByName -name "My Group Name"

    .NOTES
      Low-level function (API).

    .LINK
      http://developer.linkedin.com/documents/groups
      http://developer.linkedin.com/documents/groups-api
  #>


  $LogFileName      = "LinkedInModule"

  $ApiQuota         = Get-RawLINApiQuotaStatus "ApiGroupGetDetailsDailyLimit"

  if ( $ApiQuota.CurrentValue -lt $ApiQuota.MaxValue ) {
    $ApiUrl         = "https://api.linkedin.com/v1/people/~/group-memberships:(group:(id,name),membership-state,contact-email,show-group-logo-in-profile,allow-messages-from-members,email-digest-frequency,email-announcements-from-managers,email-for-every-new-post)?count=50&oauth2_access_token=$($connections.LinkedIn.AccessToken)"
    $ApiResponse    = & $BinDir\curl.exe -s -k -X GET $ApiUrl

    Write-Debug "ApiUrl:      $ApiUrl"
    # Write-Debug "ApiResponse: $ApiResponse"
    # $ApiResponse | Out-File -Encoding UTF8 $CurrentLogsDir\$LogFileName-GroupsByNameApiDump-$CurrentSessionId.log

    Update-RawLINApiQuotaStatus "ApiGroupGetDetailsDailyLimit"

    if ( !( ( $ApiResponse -ilike "*Bad Request*" ) -and ( $ApiResponse -ilike "*error-code*" ) ) ) {
      $TargetGroup  = ( [xml] $ApiResponse )."group-memberships"."group-membership".group | Where-Object { $_.name -eq $name }

      if ( $TargetGroup -ne $null ) {
        New-Object PSObject -Property @{
          GroupId   = $TargetGroup.id
          Name      = $TargetGroup.name
        }
      } else {
        "$(get-date -format u) [Get-RawLINGroupIdByName] - Can't find a Group with name: $name" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) "                                                                >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) $ApiUrl"                                                         >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) $ApiResponse"                                                    >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) "                                                                >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

        Write-Debug "[Get-RawLINGroupIdByName] - Unable to retrieve GroupId for: $name"

        return $null
      }
    } else {
      "$(get-date -format u) [Get-RawLINGroupIdByName] - Unable to retrieve GroupId for: $name" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) "                                                                  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) $ApiUrl"                                                           >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) $ApiResponse"                                                      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) "                                                                  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawLINGroupIdByName] - Unable to retrieve GroupId for: $name"

      return $null
    }
  } else {
    "$(get-date -format u) [Get-RawLINGroupIdByDomain] - The maximum number of daily API Calls has been reached: $($ApiQuota.MaxValue)" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawLINGroupIdByDomain] - Unable to retrieve GroupId for: $name"

    return $null
  }
}


function Get-RawLINCompanyIdByDomain( [string] $domain = "", [string] $NamePattern = "" ) {
  <#
    .SYNOPSIS
      Retrieves the Company Id that corresponds to a given Domain Name and Company Name.

    .DESCRIPTION
      Retrieves the Company Id that corresponds to a given Domain Name and Company Name.

    .EXAMPLE
      $MyCompanyId = Get-RawLINCompanyIdByDomain -domain "domain.com" -NamePattern "Company Name"

    .NOTES
      Low-level function (API).

    .LINK
      http://developer.linkedin.com/documents/companies
      http://developer.linkedin.com/documents/company-lookup-api-and-fields
  #>


  $LogFileName            = "LinkedInModule"

  $ApiQuota               = Get-RawLINApiQuotaStatus "ApiCompanyGetProfilesDailyLimit"

  if ( ( $domain -ne "" ) -and ( $NamePattern -ne "" ) ) {
    if ( $ApiQuota.CurrentValue -lt $ApiQuota.MaxValue ) {
      $ApiUrl             = "https://api.linkedin.com/v1/companies?email-domain=$domain&oauth2_access_token=$($connections.LinkedIn.AccessToken)"
      $ApiResponse        = & $BinDir\curl.exe -s -k -X GET $ApiUrl

      Write-Debug "ApiUrl:      $ApiUrl"
      # Write-Debug "ApiResponse: $ApiResponse"
      # $ApiResponse | Out-File -Encoding UTF8 $CurrentLogsDir\$LogFileName-CompanyByDomainApiDump-$CurrentSessionId.log

      Update-RawLINApiQuotaStatus "ApiCompanyGetProfilesDailyLimit"

      if ( !( ( $ApiResponse -ilike "*Bad Request*" ) -and ( $ApiResponse -ilike "*error-code*" ) ) ) {
        $SelectedCompany  = ( [xml] $ApiResponse ).companies.company | Where-Object { $_.Name -match "^$NamePattern$" }

        if ( $SelectedCompany -ne $null ) {
          $SelectedCompany | ForEach-Object {
            New-Object PSObject -Property @{
              CompanyId   = $_.id
              CompanyName = $_.name
            }
          }
        } else {
          "$(get-date -format u) [Get-RawLINCompanyIdByDomain] - No Companies found." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

          Write-Debug "[Get-RawLINCompanyIdByDomain] - No Companies found."

          return $null
        }
      } else {
        "$(get-date -format u) [Get-RawLINCompanyIdByDomain] - Unable to retrieve CompanyId(s): $name" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) "                                                                       >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) $ApiUrl"                                                                >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) $ApiResponse"                                                           >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) "                                                                       >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

        Write-Debug "[Get-RawLINCompanyIdByDomain] - Unable to retrieve CompanyId(s): $name"

        return $null
      }
    } else {
      "$(get-date -format u) [Get-RawLINCompanyIdByDomain] - The maximum number of daily API Calls has been reached: $($ApiQuota.MaxValue)" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawLINCompanyIdByDomain] - The maximum number of daily API Calls has been reached: $($ApiQuota.MaxValue)"

      return $null
    }
  } else {
    "$(get-date -format u) [Get-RawLINCompanyIdByDomain] - Unable to retrieve Companies. Not enough input data." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawLINCompanyIdByDomain] - Unable to retrieve Companies. Not enough input data."

    return $null
  }
}


function Get-RawLINUserProfileUrl( [string] $UserId ) {
  <#
    .SYNOPSIS
      Retrieves the Profile URL that corresponds to a given User Id.

    .DESCRIPTION
      Retrieves the Profile URL that corresponds to a given User Id.

    .EXAMPLE
      $UserProfileUrl = Get-RawLINUserProfileUrl -UserId AExAEfxq

    .NOTES
      Low-level function (API).

    .LINK
      http://developer.linkedin.com/documents/people
      http://developer.linkedin.com/documents/profile-api
  #>


  $LogFileName                  = "LinkedInModule"
  [PSObject[]] $PeopleEngaged   = @()


  if ( ( $UserId -eq $null ) -or ( $UserId.Length -eq 0 ) ) {
    "$(get-date -format u) [Get-RawLINUserProfileUrl] - Can't retrieve data. UserId is null." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawLINUserProfileUrl] - Can't retrieve data. UserId is null."

    return $null
  }


  $ApiQuota                     = Get-RawLINApiQuotaStatus "ApiNetworkGetProfilesDailyLimit"

  if ( $ApiQuota.CurrentValue -lt $ApiQuota.MaxValue ) {
    $ApiUrl                     = "https://api.linkedin.com/v1/people/$($UserId)?oauth2_access_token=$($connections.LinkedIn.AccessToken)"
    $ApiResponse                = & $BinDir\curl.exe -s -k -X GET $ApiUrl

    Write-Debug "ApiUrl:      $ApiUrl"
    # Write-Debug "ApiResponse: $ApiResponse"
    # $ApiResponse | Out-File -Encoding UTF8 $CurrentLogsDir\$LogFileName-PeopleApiDump-$CurrentSessionId.log

    Update-RawLINApiQuotaStatus "ApiNetworkGetProfilesDailyLimit"

    if ( !( ( $ApiResponse -ilike "*Bad Request*" ) -or ( $ApiResponse -ilike "*error-code*" ) ) ) {
      $UserProfile              = ( [xml] $ApiResponse ).person

      New-Object PSObject -Property @{
        UserId                  = $UserId
        UserDisplayName         = $UserProfile."first-name" + " " + $UserProfile."last-name"
        UserDescription         = $UserProfile.headline
        UserProfileUrl          = $UserProfile."site-standard-profile-request".url -replace "http:","https:"
      }
    } else {
      "$(get-date -format u) [Get-RawLINUserProfileUrl] - Unable to retrieve profile information form user"             >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawLINUserProfileUrl] -   ApiUrl:      $ApiUrl"                                       >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawLINUserProfileUrl] -   ApiResponse: `r`n $ApiResponse"                             >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawLINUserProfileUrl] - Unable to retrieve profile information form user"

      return $null
    }
  } else {
    "$(get-date -format u) [Get-RawLINUserProfileUrl] - The maximum number of daily API Calls has been reached: $($ApiQuota.MaxValue)" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawLINUserProfileUrl] - Unable to retrieve profile information form user"

    return $null
  }
}


function Get-RawLINCompanyLikes( [string] $UpdateId ) {
  <#
    .SYNOPSIS
      Retrieves information about Likes performed on a given Post published on the Company Page.

    .DESCRIPTION
      Retrieves information about Likes performed on a given Post published on the Company Page.

    .EXAMPLE
      $PostLikes = Get-RawLINCompanyLikes -UpdateId AExAEfxq

    .NOTES
      Low-level function (API).

    .LINK
      http://developer.linkedin.com/documents/companies
      http://developer.linkedin.com/documents/commenting-and-liking-company-share
  #>


  $LogFileName                    = "LinkedInModule"
  [PSObject[]] $PeopleEngaged     = @()
  [string[]]   $UserIdBlackList   = @()


  if ( ( $UpdateId -eq $null ) -or ( $UpdateId.Length -eq 0 ) ) {
    "$(get-date -format u) [Get-RawLINCompanyLikes] - Can't retrieve data. UpdateId is null." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawLINCompanyLikes] - Can't retrieve data. UpdateId is null."

    return $null
  }

  $ApiQuota                       = Get-RawLINApiQuotaStatus "ApiCompanyGetPostsDailyLimit"

  if ( $ApiQuota.CurrentValue -lt $ApiQuota.MaxValue ) {
    $ApiUrl                       = "https://api.linkedin.com/v1/companies/$($connections.LinkedIn.DefaultCompanyId)/updates/$($UpdateId):(num-likes,update-key,likes)?&oauth2_access_token=$($connections.LinkedIn.AccessToken)"
    $ApiResponse                  = & $BinDir\curl.exe -s -k -X GET $ApiUrl

    Write-Debug "[Get-RawLINCompanyLikes] - Getting Company Likes"
    Write-Debug "[Get-RawLINCompanyLikes] -   ApiUrl:      $ApiUrl"
    # Write-Debug "[Get-RawLINCompanyLikes] -   ApiResponse: `n`n$ApiResponse"
    # $ApiResponse | Out-File -Encoding UTF8 $CurrentLogsDir\$LogFileName-CompanyLikesApiDump-$CurrentSessionId.log

    Update-RawLINApiQuotaStatus "ApiCompanyGetPostsDailyLimit"

    if ( !( ( $ApiResponse -ilike "*Bad Request*" ) -or ( $ApiResponse -ilike "*error-code*" ) ) ) {
      $LikesCount                 = [int] ( [xml] $ApiResponse ).update."num-likes"

      ( [xml] $ApiResponse ).update.likes.like.person  | ForEach-Object {
        if ( $_.id -ne $null ) {
          if ( !( $_.id -in $UserIdBlackList ) ) {
            $UserProfile          = Get-RawLINUserProfileUrl $_.id

            if ( $UserProfile -eq $null ) { $UserProfileUrl = $VALUE_NA } else { $UserProfileUrl = $UserProfile.UserProfileUrl }

            $PeopleEngaged += New-Object PSObject -Property @{
              UserId              = $_.id
              UserDisplayName     = $_."first-name" + " " + $_."last-name"
              UserDescription     = $_.headline
              UserProfileUrl      = $UserProfileUrl
              UserProfileApiUrl   = "https://api.linkedin.com/v1/people/" + $_.id
              EngagementType      = $ENGAGEMENT_TYPE_INTEREST
            }

            $UserIdBlackList     += $_.id
          } else {
            $ExistingUserProfile  = $PeopleEngaged | Where-Object { ( $_.UserId -eq $person.id ) -and ( $_.UserProfileUrl -ne $VALUE_NA ) }

            $PeopleEngaged       += New-Object PSObject -Property @{
              UserId              = $ExistingUserProfile.UserId
              UserDisplayName     = $ExistingUserProfile.UserDisplayName
              UserDescription     = $ExistingUserProfile.UserDescription
              UserProfileUrl      = $ExistingUserProfile.UserProfileUrl
              UserProfileApiUrl   = $ExistingUserProfile.UserProfileApiUrl
              EngagementType      = $ExistingUserProfile.EngagementType
            }
          }
        }
      }

      if ( $LikesCount -ne $PeopleEngaged.count ) {
        "$(get-date -format u) [Get-RawLINCompanyLikes] - Data mismatch: LikeCounts don't match the number of users retrieved" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) [Get-RawLINCompanyLikes] -   ApiUrl:      $ApiUrl"                                              >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) [Get-RawLINCompanyLikes] -   ApiResponse: `r`n$ApiResponse"                                     >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

        Write-Debug "[Get-RawLINCompanyLikes] - Data mismatch: LikeCounts don't match the number of users retrieved"
      }

      New-Object PSObject -Property @{
        LikesCount              = $LikesCount
        PeopleEngaged           = $PeopleEngaged
      }
    } else {
      "$(get-date -format u) [Get-RawLINCompanyLikes] - Unable to retrieve Likes from post"                                    >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawLINCompanyLikes] -   ApiUrl:      $ApiUrl"                                                >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawLINCompanyLikes] -   ApiResponse: `r`n$ApiResponse"                                       >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawLINCompanyLikes] - Unable to retrieve Likes from post"

      return $null
    }
  } else {
    "$(get-date -format u) [Get-RawLINCompanyLikes] - The maximum number of daily API Calls has been reached: $($ApiQuota.MaxValue)" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawLINCompanyLikes] - Unable to retrieve Likes from post"

    return $null
  }
}


function Get-RawLINCompanyComments( [string] $UpdateId ) {
  <#
    .SYNOPSIS
      Retrieves information about Comments performed on a given Post published on the Company Page.

    .DESCRIPTION
      Retrieves information about Comments performed on a given Post published on the Company Page.

    .EXAMPLE
      $PostLikes = Get-RawLINCompanyComments -UpdateId AExAEfxq

    .NOTES
      Low-level function (API).

    .LINK
      http://developer.linkedin.com/documents/companies
      http://developer.linkedin.com/documents/commenting-and-liking-company-share

  #>

  $LogFileName                    = "LinkedInModule"
  [PSObject[]] $PeopleEngaged     = @()


  if ( ( $UpdateId -eq $null ) -or ( $UpdateId.Length -eq 0 ) ) {
    "$(get-date -format u) [Get-RawLINCompanyComments] - Can't retrieve data. UpdateId is null." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawLINCompanyComments] - Can't retrieve data. UpdateId is null."

    return $null
  }

  $ApiQuota                       = Get-RawLINApiQuotaStatus "ApiCompanyGetPostsDailyLimit"

  if ( $ApiQuota.CurrentValue -lt $ApiQuota.MaxValue ) {
    $ApiUrl                       = "https://api.linkedin.com/v1/companies/$($connections.LinkedIn.DefaultCompanyId)/updates/$($UpdateId):(updateComments)?&oauth2_access_token=$($connections.LinkedIn.AccessToken)"
    $ApiResponse                  = & $BinDir\curl.exe -s -k -X GET $ApiUrl

    Write-Debug "[Get-RawLINCompanyComments] - Getting Company Comments"
    Write-Debug "[Get-RawLINCompanyComments] -   ApiUrl:      $ApiUrl"
    # Write-Debug "[Get-RawLINCompanyComments] -   ApiResponse: `n`n$ApiResponse"
    # $ApiResponse | Out-File -Encoding UTF8 $CurrentLogsDir\$LogFileName-CompanyCommentsApiDump-$CurrentSessionId.log

    Update-RawLINApiQuotaStatus "ApiCompanyGetPostsDailyLimit"

    if ( !( ( $ApiResponse -ilike "*Bad Request*" ) -or ( $ApiResponse -ilike "*error-code*" ) ) ) {
      $CommentsCount              = [int] ( [xml] $ApiResponse ).update."update-comments".total

      ( [xml] $ApiResponse ).update."update-comments"."update-comment".person  | ForEach-Object {
        if ( $_.id -ne $null ) {
          $PeopleEngaged += New-Object PSObject -Property @{
            UserId                = $_.id
            UserDisplayName       = $_."first-name" + " " + $_."last-name"
            UserDescription       = $_.headline
            UserProfileUrl        = $_."site-standard-profile-request".url -replace "http:","https:"
            UserProfileApiUrl     = $_."api-standard-profile-request".url  -replace "http:","https:"
            EngagementType        = $ENGAGEMENT_TYPE_INTERACTION
          }
        }
      }

      if ( $CommentsCount -ne $PeopleEngaged.count ) {
        "$(get-date -format u) [Get-RawLINCompanyComments] - Data mismatch: CommentCounts don't match the number of users retrieved" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) [Get-RawLINCompanyComments] -   ApiUrl:      $ApiUrl"                                                 >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) [Get-RawLINCompanyComments] -   ApiResponse: `r`n$ApiResponse"                                        >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

        Write-Debug "[Get-RawLINCompanyComments] - Data mismatch: CommentCounts don't match the number of users retrieved"
      }

      New-Object PSObject -Property @{
        CommentsCount             = $CommentsCount
        PeopleEngaged             = $PeopleEngaged
      }
    } else {
      "$(get-date -format u) [Get-RawLINCompanyComments] - Unable to retrieve Comments from post"                                    >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawLINCompanyComments] -   ApiUrl:      $ApiUrl"                                                   >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawLINCompanyComments] -   ApiResponse: `r`n$ApiResponse"                                          >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawLINCompanyComments] - Unable to retrieve Comments from post"

      return $null
    }
  } else {
    "$(get-date -format u) [Get-RawLINCompanyComments] - The maximum number of daily API Calls has been reached: $($ApiQuota.MaxValue)" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawLINCompanyComments] - Unable to retrieve Comments from post"

    return $null
  }
}


function Get-RawLINCompanyPosts( [string] $from = "", [string] $domain = "", [int] $results = 0 ) {
  <#
    .SYNOPSIS
      Retrieves Posts published on the Company Page.

    .DESCRIPTION
      Retrieves Posts published on the Company Page.

    .EXAMPLE
      $Posts = Get-RawLINCompanyPosts -from "Company Name" -domain "domain.com"

    .NOTES
      Low-level function (API).

    .LINK
      http://developer.linkedin.com/documents/companies
      http://developer.linkedin.com/reading-company-shares
  #>


  $LogFileName                    = "LinkedInModule"
  [datetime] $UnixEpoch           = '1970-01-01 00:00:00'
  [PSObject[]] $PeopleEngaged     = @()
  $ConnectionAllowed              = $false

  if ( $results -eq 0 ) {
    $results                      = $connections.LinkedIn.DefaultResultsToReturn
  }


  if ( ( $from -eq "" ) -and ( $domain -eq "" ) ) {
    $from                         = $connections.LinkedIn.DefaultCompanyName
    $FromCompanyName              = $connections.LinkedIn.DefaultCompanyName
    $FromCompanyId                = $connections.LinkedIn.DefaultCompanyId
    $FromCompanyDomain            = $VALUE_NA

    $ConnectionAllowed            = $true
  } else {
    if ( $from   -eq "" ) {
      $from                       = $connections.LinkedIn.DefaultCompanyName
      $FromCompanyName            = $connections.LinkedIn.DefaultCompanyName
      $FromCompanyId              = $connections.LinkedIn.DefaultCompanyId
      $FromCompanyDomain          = $VALUE_NA

      $ConnectionAllowed          = $true
    } else {
      $FromCompanyName            = $from
      $FromCompanyId              = $connections.LinkedIn.DefaultCompanyId
      $FromCompanyDomain          = $VALUE_NA

      $ConnectionAllowed          = $true
    }

    if ( $domain -ne "" ) {
      $FromCompanyDomain          = $domain

      $CurrentCompany             = Get-RawLINCompanyIdByDomain -domain $FromCompanyDomain -NamePattern $FromCompanyName

      if ( $CurrentCompany -ne $null ) {
        $FromCompanyName          = $CurrentCompany.CompanyName
        $FromCompanyId            = $CurrentCompany.CompanyId

        $ConnectionAllowed        = $true
      } else {
        $ConnectionAllowed        = $false
      }
    }
  }

  if ( $ConnectionAllowed ) {
    $ApiQuota                     = Get-RawLINApiQuotaStatus "ApiCompanyGetPostsDailyLimit"

    if ( $ApiQuota.CurrentValue -lt $ApiQuota.MaxValue ) {
      # $ApiUrl                     = "https://api.linkedin.com/v1/companies/$FromCompanyId/updates?start=0&count=$results&oauth2_access_token=$($connections.LinkedIn.AccessToken)"
      $ApiUrl                     = "https://api.linkedin.com/v1/companies/$FromCompanyId/updates?event-type=status-update&start=0&count=$results&oauth2_access_token=$($connections.LinkedIn.AccessToken)"
      $ApiResponse                = & $BinDir\curl.exe -s -k -X GET $ApiUrl

      Write-Debug "[Get-RawLINCompanyPosts] - Getting Company Posts"
      Write-Debug "[Get-RawLINCompanyPosts] -   ApiUrl:      $ApiUrl"
      # Write-Debug "[Get-RawLINCompanyPosts] -   ApiResponse:`n`n$ApiResponse"
      # $ApiResponse | Out-File -Encoding UTF8 $CurrentLogsDir\$LogFileName-CompanyApiDump-$CurrentSessionId.log

      Update-RawLINApiQuotaStatus "ApiCompanyGetPostsDailyLimit"

      if ( !( ( $ApiResponse -ilike "*Bad Request*" ) -and ( $ApiResponse -ilike "*error-code*" ) ) ) {
        Write-Debug "[Get-RawLINCompanyPosts] - Company posts retrieved: $( ( [xml] $ApiResponse ).updates.update.Count )"

        ( [xml] $ApiResponse ).updates.update  | ForEach-Object {
          $CurrentLikes           = Get-RawLINCompanyLikes $_."update-key"
          $CurrentComments        = Get-RawLINCompanyComments $_."update-key"

          if ( $CurrentLikes    -eq $null ) { $CurrentLikesCount    = 0 } else { $CurrentLikesCount    = $CurrentLikes.LikesCount       ; $PeopleEngaged += $CurrentLikes.PeopleEngaged    }
          if ( $CurrentComments -eq $null ) { $CurrentCommentsCount = 0 } else { $CurrentCommentsCount = $CurrentComments.CommentsCount ; $PeopleEngaged += $CurrentComments.PeopleEngaged }

          New-Object PSObject -Property @{
            UpdateKey             = $_."update-key"
            UpdateType            = $_."update-type"
            PostId                = $_."update-content"."company-status-update".share.id
            Title                 = $_."update-content"."company-status-update".share.comment
            PostContent           = $_."update-content"."company-status-update".share.comment
            PermaLink             = $VALUE_NA
            AuthorName            = $VALUE_NA
            TimeStamp             = $UnixEpoch.AddSeconds( [double] $_."update-content"."company-status-update".share.timestamp / 1000 )
            SharedContentTitle    = $_."update-content"."company-status-update".share.content.title
            SharedContentExcerpt  = $_."update-content"."company-status-update".share.content.description
            ShortLink             = $_."update-content"."company-status-update".share.content."shortened-url"
            SharedLink            = $_."update-content"."company-status-update".share.content."submitted-url"
            LikesCount            = $CurrentLikesCount
            CommentsCount         = $CurrentCommentsCount
            PeopleEngaged         = $PeopleEngaged
            SubChannelName        = $FromCompanyName + "(Company)"
          }

          [PSObject[]] $PeopleEngaged = @()
        }
      } else {
        "$(get-date -format u) [Get-RawLINCompanyPosts] - Unable to retrieve Company Posts" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) [Get-RawLINCompanyPosts] -   ApiUrl: $ApiUrl"                >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) [Get-RawLINCompanyPosts] -   ApiResponse: `n`n$ApiResponse"  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

        Write-Debug "[Get-RawLINCompanyPosts] - Unable to retrieve Company Posts"

        return $null
      }
    } else {
      "$(get-date -format u) [Get-RawLINCompanyPosts] - The maximum number of daily API Calls has been reached: $($ApiQuota.MaxValue)" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawLINCompanyPosts] - Unable to retrieve Company Posts"

      return $null
    }
  } else {
    "$(get-date -format u) [Get-RawLINCompanyPosts] - Unable to resolve CompanyId for Domain:" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawLINCompanyPosts] -   FromCompanyName:   $FromCompanyName"   >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawLINCompanyPosts] -   FromCompanyId:     $FromCompanyId"     >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawLINCompanyPosts] -   FromCompanyDomain: $FromCompanyDomain" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawLINCompanyPosts] - Unable to resolve CompanyId for Domain"

    return $null
  }
}


function Get-LINGroupPostPermaLink( [string] $id, [string] $title ) {
  <#
    .SYNOPSIS
      Composes the LinkedIn PermaLink for a given Group Post using the Post Id and the Post Title.

    .DESCRIPTION
      Composes the LinkedIn PermaLink for a given Group Post using the Post Id and the Post Title.

    .EXAMPLE
      $Posts = Get-LINGroupPostPermaLink -id 09870609880987060988 -title "Post Title"

    .NOTES
      Low-level function (API).

    .LINK
      N/A
  #>

  $LogFileName  = "LinkedInModule"

  try {
    $UriPostId  = $id.Substring(2) -replace "-","."

    $UriTitle1  = ( ( ( ( ( (  $title -replace '[^a-zA-Z0-9 ]','').Split(' ') -ne "" ) -ne "a" ) -ne "the" )[0..4] | ForEach-Object { "$_-" } | Out-String ) -replace "[\r\n]","" ).Trim()
    $UriTitle2  = ( ( ( ( ( (  $title -replace '[^a-zA-Z0-9 ]','').Split(' ') -ne "" ) -ne "a" ) -ne "the" )[0..3] | ForEach-Object { "$_-" } | Out-String ) -replace "[\r\n]","" ).Trim()

    $URL1       = "https://www.linkedin.com/groups/$UriTitle1$UriPostId"
    $URL2       = "https://www.linkedin.com/groups/$UriTitle2$UriPostId"

    Write-Debug "URL1: $URL1"
    Write-Debug "URL2: $URL2"

    $HttpCode   = & $BinDir\curl.exe -s -k -X GET -o /dev/null -w "%{http_code}" --user-agent "Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)" "$URL1"

    if ( $HttpCode -eq "200" ) {
      return $URL1
    } else {
      Write-Debug "HttpCode: $HttpCode"

      $HttpCode = & $BinDir\curl.exe -s -k -X GET -o /dev/null -w "%{http_code}" --user-agent "Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)" "$URL2"

      if ( $HttpCode -eq "200" ) {
        return $URL2
      } else {
        Write-Debug "HttpCode: $HttpCode"

        return $VALUE_NA
      }
    }
  } catch {
    "$(get-date -format u) [Get-LINGroupPostPermaLink] - Unable to compose a PermaLink for this Group Post:" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-LINGroupPostPermaLink] -   id:    $id"                                       >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-LINGroupPostPermaLink] -   title: $title"                                    >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-LINGroupPostPermaLink] - Unable to compose a PermaLink for this Group Post"

    return $VALUE_NA
  }
}


function Get-RawLINGroupPosts( [string] $from = "", [int] $results = 0 ) {
  <#
    .SYNOPSIS
      Retrieves Posts published on a given Group.

    .DESCRIPTION
      Retrieves Posts published on a given Group.

    .EXAMPLE
      $Posts = Get-RawLINGroupPosts
      $Posts = Get-RawLINGroupPosts -from "Group Name"

    .NOTES
      Low-level function (API).

    .LINK
      http://developer.linkedin.com/documents/groups
      http://developer.linkedin.com/documents/groups-api
  #>


  $LogFileName                           = "LinkedInModule"
  [datetime]   $UnixEpoch                = '1970-01-01 00:00:00'
  [PSObject[]] $PeopleWhoLiked           = @()
  [PSObject[]] $PeopleWhoCommented       = @()
  [PSObject[]] $PeopleEngaged            = @()
  [string[]]   $UserIdBlackList          = @()

  if ( $results -eq 0 ) {
    $results                             = $connections.LinkedIn.DefaultResultsToReturn
  }


  if ( $from -eq "" ) {
    $FromGroupName                       = $connections.LinkedIn.DefaultGroupName
    $FromGroupId                         = $connections.LinkedIn.DefaultGroupId
  } else {
    $FromGroupName                       = $from
    $FromGroupId                         = ( Get-RawLINGroupIdByName $FromGroupName ).GroupId
  }

  if ( $FromGroupId -ne $null ) {
    $ApiQuota                            = Get-RawLINApiQuotaStatus "ApiGroupGetPostDailyLimit"

    if ( $ApiQuota.CurrentValue -lt $ApiQuota.MaxValue ) {
      $ApiUrl                            = "https://api.linkedin.com/v1/groups/$FromGroupId/posts:(id,creation-timestamp,title,summary,creator:(first-name,last-name,picture-url,headline),likes,comments,attachment:(image-url,content-domain,content-url,title,summary),relation-to-viewer)?category=discussion&order=recency&count=$results&oauth2_access_token=$($connections.LinkedIn.AccessToken)"
      $ApiResponse                       = & $BinDir\curl.exe -s -k -X GET $ApiUrl

      Write-Debug "[Get-RawLINGroupPosts] - Getting Group Posts"
      Write-Debug "[Get-RawLINGroupPosts] -   ApiUrl:      $ApiUrl"
      # Write-Debug "[Get-RawLINGroupPosts] -   ApiResponse:`n`n$ApiResponse"

      # $ApiResponse | Out-File -Encoding UTF8 $CurrentLogsDir\$LogFileName-GroupsApiDump-$CurrentSessionId.log

      Update-RawLINApiQuotaStatus "ApiGroupGetPostDailyLimit"

      if ( !( ( $ApiResponse -ilike "*Bad Request*" ) -and ( $ApiResponse -ilike "*error-code*" ) ) ) {
        Write-Debug "[Get-RawLINGroupPosts] - Group posts retrieved: $( ( [xml] $ApiResponse ).posts.post.Count )"

        ( [xml] $ApiResponse ).posts.post  | ForEach-Object {
          $CurrentLikes                  = $_.likes.total
          $CurrentComments               = $_.comments.total

          if ( $CurrentLikes -eq $null ) {
            $CurrentLikesCount           = 0
            $PeopleWhoLiked              = @()
          } else {
            $CurrentLikesCount           = $CurrentLikes

            foreach ( $person in $_.likes.like.person ) {
              if ( $person.id -ne $null ) {
                if ( !( $person.id -in $UserIdBlackList ) ) {
                  $UserProfile           = Get-RawLINUserProfileUrl $person.id

                  if ( $UserProfile -eq $null ) { $UserProfileUrl = $VALUE_NA } else { $UserProfileUrl = $UserProfile.UserProfileUrl }

                  $PeopleWhoLiked       += New-Object PSObject -Property @{
                    UserId               = $person.id
                    UserDisplayName      = $person."first-name" + " " + $person."last-name"
                    UserDescription      = $person.headline
                    UserProfileUrl       = $UserProfileUrl
                    UserProfileApiUrl    = "https://api.linkedin.com/v1/people/" + $_.id
                    EngagementType       = $ENGAGEMENT_TYPE_INTEREST
                  }

                  $UserIdBlackList      += $person.id
                } else {
                  $ExistingUserProfile   = $PeopleWhoLiked | Where-Object { ( $_.UserId -eq $person.id ) -and ( $_.UserProfileUrl -ne $VALUE_NA ) }

                  $PeopleWhoLiked       += New-Object PSObject -Property @{
                    UserId               = $ExistingUserProfile.UserId
                    UserDisplayName      = $ExistingUserProfile.UserDisplayName
                    UserDescription      = $ExistingUserProfile.UserDescription
                    UserProfileUrl       = $ExistingUserProfile.UserProfileUrl
                    UserProfileApiUrl    = $ExistingUserProfile.UserProfileApiUrl
                    EngagementType       = $ExistingUserProfile.EngagementType
                  }
                }
              }
            }
          }

          if ( $CurrentComments -eq $null ) {
            $CurrentCommentsCount        = 0
            $PeopleWhoCommented          = @()
          } else {
            $CurrentCommentsCount        = $CurrentComments

            foreach ( $person in $_.comments.comment.creator ) {
              if ( $person.id -ne $null ) {
                if ( !( $person.id -in $UserIdBlackList ) ) {
                  $UserProfile           = Get-RawLINUserProfileUrl $person.id

                  if ( $UserProfile -eq $null ) { $UserProfileUrl = $VALUE_NA } else { $UserProfileUrl = $UserProfile.UserProfileUrl }

                  $PeopleWhoCommented   += New-Object PSObject -Property @{
                    UserId               = $person.id
                    UserDisplayName      = $person."first-name" + " " + $person."last-name"
                    UserDescription      = $person.headline
                    UserProfileUrl       = $UserProfileUrl
                    UserProfileApiUrl    = "https://api.linkedin.com/v1/people/" + $_.id
                    EngagementType       = $ENGAGEMENT_TYPE_INTERACTION
                  }

                  $UserIdBlackList      += $person.id
                } else {
                  $ExistingUserProfile   = $PeopleWhoCommented | Where-Object { ( $_.UserId -eq $person.id ) -and ( $_.UserProfileUrl -ne $VALUE_NA ) }

                  if ( $ExistingUserProfile -eq $null ) {
                    $ExistingUserProfile = $PeopleWhoLiked | Where-Object { ( $_.UserId -eq $person.id ) -and ( $_.UserProfileUrl -ne $VALUE_NA ) }
                  }

                  $PeopleWhoCommented   += New-Object PSObject -Property @{
                    UserId               = $ExistingUserProfile.UserId
                    UserDisplayName      = $ExistingUserProfile.UserDisplayName
                    UserDescription      = $ExistingUserProfile.UserDescription
                    UserProfileUrl       = $ExistingUserProfile.UserProfileUrl
                    UserProfileApiUrl    = $ExistingUserProfile.UserProfileApiUrl
                    EngagementType       = $ExistingUserProfile.EngagementType
                  }
                }
              }
            }
          }

          $PeopleEngaged                += $PeopleWhoLiked
          $PeopleEngaged                += $PeopleWhoCommented

          New-Object PSObject -Property @{
            PostId                       = $_.id
            Title                        = $_.title
            PostContent                  = $_.summary
            PermaLink                    = Get-LINGroupPostPermaLink -id $_.id -title $_.title
            TimeStamp                    = $UnixEpoch.AddSeconds( [double] $_."creation-timestamp" / 1000 )
            AuthorName                   = $_.creator."first-name" + " " + $_.creator."last-name"
            SharedContentTitle           = $_.attachment.title
            SharedContentExcerpt         = $_.attachment.summary
            ShortLink                    = $_.attachment."content-url"
            SharedLink                   = $_.attachment."content-url"
            LikesCount                   = $CurrentLikesCount
            CommentsCount                = $CurrentCommentsCount
            PeopleEngaged                = $PeopleEngaged
            SubChannelName               = $FromGroupName
          }

          [PSObject[]] $PeopleWhoLiked     = @()
          [PSObject[]] $PeopleWhoCommented = @()
          [PSObject[]] $PeopleEngaged      = @()
        }
      } else {
        "$(get-date -format u) [Get-RawLINGroupPosts] - Unable to retrieve Group Posts"  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) [Get-RawLINGroupPosts] -   ApiUrl: $ApiUrl"               >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) [Get-RawLINGroupPosts] -   ApiResponse: `n`n$ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

        Write-Debug "[Get-RawLINGroupPosts] - Unable to retrieve Group Posts"

        return $null
      }
    } else {
      "$(get-date -format u) [Get-RawLINGroupPosts] - The maximum number of daily API Calls has been reached: $($ApiQuota.MaxValue)" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawLINGroupPosts] - Unable to retrieve Group Posts"

      return $null
    }
  } else {
    "$(get-date -format u) [Get-RawLINGroupPosts] - Unable to resolve GroupId for name: $from" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawLINGroupPosts] - Unable to resolve GroupId for name: $from"

    return $null
  }
}


function Search-RawLINPost( [string] $text, [ref] $on, [string] $by = "digest" ) {
  <#
    .SYNOPSIS
      Retrieves the first post in the Time Line that matches the provided text.

    .DESCRIPTION
      Retrieves the first post in the Time Line that matches the provided text. Search is performed over key post properties only like Digest or PermaLink.

    .EXAMPLE
      $PostFromLinkedIn = Search-RawLINPost -text $post.NormalizedPost.PermaLink  -on ([ref] $NormalizedTimeLine) -by permalink
      $PostFromLinkedIn = Search-RawLINPost -text $post.NormalizedPost.PostDigest -on ([ref] $NormalizedTimeLine) -by digest
      $PostFromLinkedIn = Search-RawLINPost -text $post.NormalizedPost.PostDigest -on ([ref] $NormalizedTimeLine)

    .NOTES
      Low-level function (API).

    .LINK
      N/A
  #>


  $post = $null

  switch ( $by.ToLower() ) {
    "permalink" {
      $on.Value | ForEach-Object {
        if ( $text -eq $_.NormalizedPost.PermaLink ) {
          Write-Debug "[Search-RawLINPost] - Post found by PermaLink."
          Write-Debug "[Search-RawLINPost] -   Target post: $text."

          $post = $_

          break
        }
      }
    }

    default {
      $on.Value | ForEach-Object {
        if ( $text -eq $_.NormalizedPost.PostDigest ) {
          Write-Debug "[Search-RawLINPost] - Post found by Digest."
          Write-Debug "[Search-RawLINPost] -   Target post: $text."

          $post = $_

          break
        }
      }
    }
  }

  $post
}


function Get-RawLINTimeLineCache( [string] $type = "group", [string] $name = "" ) {
  <#
    .SYNOPSIS
      Retrieves raw contents of LinkedIn Time Line from the local cache.

    .DESCRIPTION
      Retrieves raw contents of LinkedIn Time Line from the local cache.

    .EXAMPLE
      $RawLINTimeLine  = Get-RawLINTimeLineCache -type group   -name "My Target Group Name"
      $RawLINTimeLine += Get-RawLINTimeLineCache -type company -name "My Target Company Name"

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  [string] $SubChannelName = Get-RawNormalizedPropertyName $name
  [string] $CacheFile      = "$CurrentCacheDir\LINTimeLineCache-$type-$SubChannelName.xml"

  if ( Test-Path $CacheFile ) {
    [int] $CacheAge        = -( Get-ChildItem $CacheFile ).LastWriteTime.Subtract( $( Get-Date ) ).TotalHours

    Write-Debug "[Get-RawLINTimeLineCache] - Current Cache Age: $CacheAge"

    if ( $CacheAge -lt $connections.LinkedIn.PostsCacheExpiration ) {
      $CachedTimeLine      = Import-CliXml $CacheFile

      Write-Debug "[Get-RawLINTimeLineCache] - Cache content loaded"
    } else {
      return $null
    }
  } else {
    return $null
  }

  $CachedTimeLine
}


function Set-RawLINTimeLineCache( [PSObject[]] $using, [string] $type = "group", [string] $name = "" ) {
  <#
    .SYNOPSIS
      Updates contents of LinkedIn Subchannel Time Line local cache.

    .DESCRIPTION
      Updates contents of LinkedIn Subchannel Time Line local cache. Each Subchannel gets its own cache file.

    .EXAMPLE
      $RawLINTimeLine | Where-Object { $_.NormalizedPost.SubChannelName -eq "My Target Group Name"   } | Set-RawLINTimeLineCache -type group   -name "My Target Group Name"
      $RawLINTimeLine | Where-Object { $_.NormalizedPost.SubChannelName -eq "My Target Company Name" } | Set-RawLINTimeLineCache -type company -name "My Target Company Name"

      Set-RawLINTimeLineCache -type group   -name "My Target Group Name"   -using $( $RawLINTimeLine | Where-Object { $_.NormalizedPost.SubChannelName -eq "My Target Group Name"   } )
      Set-RawLINTimeLineCache -type company -name "My Target Company Name" -using $( $RawLINTimeLine | Where-Object { $_.NormalizedPost.SubChannelName -eq "My Target Company Name" } )

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  begin {
    $CacheFile                                      = "$CurrentCacheDir\LINTimeLineCache-$type-$( Get-RawNormalizedPropertyName $name ).xml"
    [System.Collections.ArrayList] $TimeLineToCache = @()
  }

  process {
    if ( $_ -ne $null ) {
      $TimeLineToCache.Add( $( $_ | ConvertTo-JSON ) ) | Out-Null
    } else {
      if ( $using -ne $null ) {
        if ( $using.NormalizedPost -ne $null ) {
          $using | ForEach-Object {
            $TimeLineToCache.Add( $( $_ | ConvertTo-JSON ) ) | Out-Null
          }
        } else {
          return $false
        }
      } else {
        return $false
      }
    }
  }

  end {
    ( $TimeLineToCache | ForEach-Object { if ( $_ -ne $null ) { ConvertFrom-JSON $_ } else { $_ } } ) -ne $null | Export-CliXml $CacheFile

    return $true
  }
}


# --------------------------------------------------------------------------------------------------


function Get-LINTimeLine( [string] $company = "", [string] $domain = "", [string] $group = "", [int] $results = $connections.LinkedIn.DefaultResultsToReturn, [switch] $quick, [switch] $UseFullCache ) {
  <#
    .SYNOPSIS
      Retrieves and composes the LinkedIn Time Line from the specified Post sources.

    .DESCRIPTION
      Retrieves and composes the LinkedIn Time Line from the specified Post sources.

    .EXAMPLE
      $FBTimeLine = Get-LINTimeLine -quick
      $FBTimeLine = Get-LINTimeLine -company "Company Name" -domain "domain.com" -group "Group Name" -quick

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  # $DebugPreference = "Continue"

  [PSObject[]] $RawTimeLine                = @()
  [PSObject[]] $CachedTimeLine             = @()
  [System.Collections.ArrayList] $TimeLine = @()
  [string] $FullCacheFile                  = "$CurrentCacheDir\LINTimeLineCache-FullCache.xml"


  if ( $UseFullCache ) {
    if ( Test-Path $FullCacheFile ) {
      [int] $CacheAge         = -( Get-ChildItem $FullCacheFile ).LastWriteTime.Subtract( $( Get-Date ) ).TotalHours

      Write-Debug "[Get-LINTimeLine] - Current Full Cache Age: $CacheAge"

      if ( $CacheAge -lt $connections.LinkedIn.PostsCacheExpiration ) {
        $CachedTimeLine       = Import-CliXml $FullCacheFile

        Write-Debug "[Get-LINTimeLine] - Full Cache content loaded"

        return $CachedTimeLine
      }
    }
  }


  if ( ( $compay -eq "" ) -and ( $group -eq "" ) -and ( $domain -eq "" ) ) {
    Write-Debug "[Get-LINTimeLine] - Reading company content from Local Cache."

    $CachedTimeLine         = Get-RawLINTimeLineCache -type company -name $connections.LinkedIn.DefaultCompanyName

    if ( $CachedTimeLine -ne $null ) {
      Write-Debug "[Get-LINTimeLine] - Cached company content loaded."

      $RawTimeLine         += $CachedTimeLine
    } else {
      Write-Debug "[Get-LINTimeLine] - Reading company content from API."

      $CachedTimeLine       = Get-RawLINCompanyPosts -results $results

      if ( $CachedTimeLine | Set-RawLINTimeLineCache -type company -name $connections.LinkedIn.DefaultCompanyName ) {
        Write-Debug "[Get-LINTimeLine] - new company content cached."

        $RawTimeLine       += $CachedTimeLine
      } else {
        "$(get-date -format u) [Get-LINTimeLine] - Unable to properly cache Company Posts."                       >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) [Get-LINTimeLine] -   Company Name: $( $connections.LinkedIn.DefaultCompanyName )" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

        Write-Debug "[Get-LINTimeLine] - Unable to properly cache Company Posts."

        return $null
      }
    }

    Write-Debug "[Get-LINTimeLine] - Reading group content from Local Cache."

    $CachedTimeLine         = Get-RawLINTimeLineCache -type group -name $connections.LinkedIn.DefaultGroupName

    if ( $CachedTimeLine -ne $null ) {
      Write-Debug "[Get-LINTimeLine] - Cached group content loaded."

      $RawTimeLine         += $CachedTimeLine
    } else {
      Write-Debug "[Get-LINTimeLine] - Reading group content from API."

      $CachedTimeLine       = Get-RawLINGroupPosts -results $results

      if ( $CachedTimeLine | Set-RawLINTimeLineCache -type group -name $connections.LinkedIn.DefaultGroupName ) {
        Write-Debug "[Get-LINTimeLine] - new group content cached."

        $RawTimeLine       += $CachedTimeLine
      } else {
        "$(get-date -format u) [Get-LINTimeLine] - Unable to properly cache Group Posts."                      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) [Get-LINTimeLine] -   Group Name: $( $connections.LinkedIn.DefaultGroupName )" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

        Write-Debug "[Get-LINTimeLine] - Unable to properly cache Group Posts."

        return $null
      }
    }
  } else {
    if ( ( $compay -ne "" ) -and ( $domain -ne "" ) ) {
      Write-Debug "[Get-LINTimeLine] - Reading company content from Local Cache."

      $CachedTimeLine       = Get-RawLINTimeLineCache -type company -name $company

      if ( $CachedTimeLine -ne $null ) {
        Write-Debug "[Get-LINTimeLine] - Cached company content loaded."

        $RawTimeLine       += $CachedTimeLine
      } else {
        Write-Debug "[Get-LINTimeLine] - Reading company content from API."

        $CachedTimeLine     = Get-RawLINCompanyPosts -from $company -domain $domain -results $results

        if ( $CachedTimeLine | Set-RawLINTimeLineCache -type company -name $company ) {
          Write-Debug "[Get-LINTimeLine] - new company content cached."

          $RawTimeLine     += $CachedTimeLine
        } else {
          "$(get-date -format u) [Get-LINTimeLine] - Unable to properly cache Company Posts." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
          "$(get-date -format u) [Get-LINTimeLine] -   Company Name: $company"                >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
          "$(get-date -format u) [Get-LINTimeLine] -   Domain Name:  $domain"                 >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

          Write-Debug "[Get-LINTimeLine] - Unable to properly cache Company Posts."

          return $null
        }
      }
    } else {
      Write-Debug "[Get-LINTimeLine] - Reading company content from Local Cache."

      $CachedTimeLine       = Get-RawLINTimeLineCache -type company -name $connections.LinkedIn.DefaultCompanyName

      if ( $CachedTimeLine -ne $null ) {
        Write-Debug "[Get-LINTimeLine] - Cached company content loaded."

        $RawTimeLine       += $CachedTimeLine
      } else {
        Write-Debug "[Get-LINTimeLine] - Reading company content from API."

        $CachedTimeLine     = Get-RawLINCompanyPosts -results $results

        if ( $CachedTimeLine | Set-RawLINTimeLineCache -type company -name $connections.LinkedIn.DefaultCompanyName ) {
          Write-Debug "[Get-LINTimeLine] - new company content cached."

          $RawTimeLine     += $CachedTimeLine
        } else {
          "$(get-date -format u) [Get-LINTimeLine] - Unable to properly cache Company Posts."                         >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
          "$(get-date -format u) [Get-LINTimeLine] -   Company Name: $( $connections.LinkedIn.DefaultCompanyName )" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

          Write-Debug "[Get-LINTimeLine] - Unable to properly cache Company Posts."

          return $null
        }
      }
    }

    if ( $group -ne "" ) {
      Write-Debug "[Get-LINTimeLine] - Reading group content from Local Cache."

      $CachedTimeLine       = Get-RawLINTimeLineCache -type group -name $group

      if ( $CachedTimeLine -ne $null ) {
        Write-Debug "[Get-LINTimeLine] - Cached group content loaded."

        $RawTimeLine       += $CachedTimeLine
      } else {
        Write-Debug "[Get-LINTimeLine] - Reading group content from API."

        $CachedTimeLine     = Get-RawLINGroupPosts -from $group -results $results

        if ( $CachedTimeLine | Set-RawLINTimeLineCache -type group -name $group ) {
          Write-Debug "[Get-LINTimeLine] - new group content cached."

          $RawTimeLine     += $CachedTimeLine
        } else {
          "$(get-date -format u) [Get-LINTimeLine] - Unable to properly cache Group Posts." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
          "$(get-date -format u) [Get-LINTimeLine] -   Group Name: $group"                  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

          Write-Debug "[Get-LINTimeLine] - Unable to properly cache Group Posts."

          return $null
        }
      }
    } else {
      Write-Debug "[Get-LINTimeLine] - Reading group content from Local Cache."

      $CachedTimeLine       = Get-RawLINTimeLineCache -type group -name $connections.LinkedIn.DefaultGroupName

      if ( $CachedTimeLine -ne $null ) {
        Write-Debug "[Get-LINTimeLine] - Cached group content loaded."

        $RawTimeLine       += $CachedTimeLine
      } else {
        Write-Debug "[Get-LINTimeLine] - Reading group content from API."

        $CachedTimeLine     = Get-RawLINGroupPosts -results $results

        if ( $CachedTimeLine | Set-RawLINTimeLineCache -type group -name $connections.LinkedIn.DefaultGroupName ) {
          Write-Debug "[Get-LINTimeLine] - new group content cached."

          $RawTimeLine     += $CachedTimeLine
        } else {
          "$(get-date -format u) [Get-LINTimeLine] - Unable to properly cache Group Posts."                      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
          "$(get-date -format u) [Get-LINTimeLine] -   Group Name: $( $connections.LinkedIn.DefaultGroupName )" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

          Write-Debug "[Get-LINTimeLine] - Unable to properly cache Group Posts."

          return $null
        }
      }
    }
  }


  if ( $RawTimeLine -eq $null ) {
    "$(get-date -format u) [Get-LINTimeLine] - Unable to retrieve posts from the API or from local cache." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-LINTimeLine] - Unable to retrieve posts from the API or from local cache."

    return $null
  } else {
    $results           = $RawTimeLine.Count
  }


  if ( $quick ) {
    $i                 = 1
    $ExecutionTime     = [Diagnostics.Stopwatch]::StartNew()
    $ExecutionTime.Stop()

    foreach ( $post in $RawTimeLine ) {
      Write-Progress -Activity "Normalizing Information (QuickMode) ..." -Status "Progress: $i / $results - ETC: $( '{0:#0.00}' -f (( $results - $i ) * $ExecutionTime.Elapsed.TotalMinutes ) ) minutes - Time Elapsed: $( '{0:#0.00}' -f (( $i - 1 ) * $ExecutionTime.Elapsed.TotalMinutes ) ) minutes" -PercentComplete ( ( $i / $results ) * 100 )

      $ExecutionTime   = [Diagnostics.Stopwatch]::StartNew()

      $NormalizedPost  = $post | ConvertTo-LINNormalizedPost

      $TimeLine.Add( $( $NormalizedPost | ConvertTo-JSON -Compress ) ) | Out-Null

      $ExecutionTime.Stop()

      $i++
    }
  } else {
    $i                 = 1
    $ExecutionTime     = [Diagnostics.Stopwatch]::StartNew()
    $ExecutionTime.Stop()

    foreach ( $post in $RawTimeLine ) {
      Write-Progress -Activity "Normalizing Information ..." -Status "Progress: $i / $results - ETC: $( '{0:#0.00}' -f (( $results - $i ) * $ExecutionTime.Elapsed.TotalMinutes ) ) minutes - Time Elapsed: $( '{0:#0.00}' -f (( $i - 1 ) * $ExecutionTime.Elapsed.TotalMinutes ) ) minutes" -PercentComplete ( ( $i / $results ) * 100 )

      $ExecutionTime   = [Diagnostics.Stopwatch]::StartNew()

      $NormalizedPost  = $post | ConvertTo-LINNormalizedPost -IncludeAll

      $TimeLine.Add( $( $NormalizedPost | ConvertTo-JSON -Compress ) ) | Out-Null

      $ExecutionTime.Stop()

      $i++
    }
  }

  $TimeLine = ( $TimeLine | ForEach-Object { if ( $_ -ne $null ) { ConvertFrom-JSON $_ } else { $_ } } ) -ne $null

  $TimeLine | Export-CliXml $FullCacheFile

  $TimeLine

  # $DebugPreference = "SilentlyContinue"
}


function ConvertTo-LINNormalizedPost( [switch] $IncludeAll, [string] $schema = $SCHEMA_DEFAULT ) {
  <#
    .SYNOPSIS
      Normalizes post information by mapping LinkedIn API data structures into a normalized one. Additionally, it also gathers additional relevant information about that post.

    .DESCRIPTION
      Normalizes post information by mapping LinkedIn API data structures into a normalized one. Additionally, it also gathers additional relevant information about that post.

    .EXAMPLE
      $NormalizedLINPosts = $LINPosts | ConvertTo-LINNormalizedPost -IncludeAll

    .NOTES
      High-level function. However, under normal circumstances, an end user shouldn't feel the need to use this function: other high-level functions use of it in order to make this details transparent to the end user.

    .LINK
      N/A
  #>


  begin {
    # $DebugPreference = "Continue"

    $LogFileName              = "LinkedInModule"

    [PSObject[]] $NewTimeLine = @()
    $TimeToWait               = $connections.LinkedIn.ApiDelay

    if ( $IncludeAll ) {
      $IncludeLinkMetrics     = $true
    }
  }

  process {
    $post                                               = $_
    $NewPost                                            = New-SMPost -schema $schema
    $NewPost.RetainUntilDate                            = "{0:$DefaultDateFormat}" -f [datetime] ( ( [datetime] $NewPost.RetainUntilDate ).AddDays( $connections.LinkedIn.DataRetention ) )

    $NewPost.NormalizedPost.PostId                      = if ( $connections.LinkedIn.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.PostId     } else { Get-SMPostDigest $post.PostId     }
    $NewPost.NormalizedPost.PostDigest                  = Get-SMPostDigest $post.Title

    $NewPost.NormalizedPost.PermaLink                   = if ( $connections.LinkedIn.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.PermaLink  } else { Get-SMPostDigest $post.PermaLink  }

    $NewPost.NormalizedPost.ChannelName                 = $CHANNEL_NAME_LINKEDIN
    $NewPost.NormalizedPost.SubChannelName              = if ( $connections.LinkedIn.PrivacyLevel -eq $PRIVACY_LEVEL_HIGH   ) { Get-SMPostDigest $post.SubChannelName } else { $post.SubChannelName }
    $NewPost.NormalizedPost.SourceDomain                = $VALUE_NA
    $NewPost.NormalizedPost.PostType                    = $POST_TYPE_MESSAGE
    $NewPost.NormalizedPost.ChannelType                 = $CHANNEL_TYPE_SN
    $NewPost.NormalizedPost.ChannelDataEngine           = $CHANNEL_DATA_ENGINE_RESTAPI
    $NewPost.NormalizedPost.SourceFormat                = $DATA_FORMAT_JSON
    $NewPost.NormalizedPost.Language                    = $VALUE_NA

    $NewPost.NormalizedPost.AuthorDisplayName           = if ( $connections.LinkedIn.PrivacyLevel -le $PRIVACY_LEVEL_LOW    ) { $post.AuthorName } else { Get-SMPostDigest $post.AuthorName }

    $NewPost.NormalizedPost.PublishingDate              = "{0:$DefaultDateFormat}" -f $post.TimeStamp

    $NewPost.NormalizedPost.Title                       = $post.Title
    $NewPost.NormalizedPost.PostContent                 = $post.PostContent

    $NewPost.NormalizedPost.SourceApplication           = $VALUE_NA

    $NewPost.NormalizedPost.SharedLinks                 = @()
    $NewPost.NormalizedPost.SharedTargetURLs            = @()
    $NewPost.NormalizedPost.Tags                        = @()

    $NewPost.NormalizedPost.SharedLinks                += Get-ShortLinks -from $post.Title       -protocol -ForceSSL

    Write-Debug "[ConvertTo-LINNormalizedPost]"
    Write-Debug "[ConvertTo-LINNormalizedPost] - SharedLinks from Title:            $( [string] $NewPost.NormalizedPost.SharedLinks )"
    Write-Debug "[ConvertTo-LINNormalizedPost] -   SharedLinks Count:               $( $NewPost.NormalizedPost.SharedLinks.Count )"

    $NewPost.NormalizedPost.SharedLinks                += Get-ShortLinks -from $post.PostContent -protocol -ForceSSL

    Write-Debug "[ConvertTo-LINNormalizedPost] - SharedLinks from PostContent:      $( [string] $NewPost.NormalizedPost.SharedLinks )"
    Write-Debug "[ConvertTo-LINNormalizedPost] -   SharedLinks Count:               $( $NewPost.NormalizedPost.SharedLinks.Count )"

    $NewPost.NormalizedPost.SharedLinks                 = ( $NewPost.NormalizedPost.SharedLinks | ForEach-Object { if ( $_ -ne $null ) { $_ } } ) -replace "[\.]+$", "" | Select-Object -unique

    Write-Debug "[ConvertTo-LINNormalizedPost] - SharedLinks after post processing: $( [string] $NewPost.NormalizedPost.SharedLinks )"
    Write-Debug "[ConvertTo-LINNormalizedPost] -   SharedLinks Count:               $( $NewPost.NormalizedPost.SharedLinks.Count )"

    $NewPost.NormalizedPost.SharedTargetURLs           += if ( $NewPost.NormalizedPost.SharedLinks -match $LinkShorteners ) { ( $NewPost.NormalizedPost.SharedLinks | Expand-ShortLink ).ExpandedUrl } else { $NewPost.NormalizedPost.SharedLinks }

    Write-Debug "[ConvertTo-LINNormalizedPost] - SharedTargetURLs:                  $( [string] $NewPost.NormalizedPost.SharedTargetURLs )"
    Write-Debug "[ConvertTo-LINNormalizedPost]"

    if ( $post.message -ne $null ) {
      $post.message.Split("#")[1..$($post.message.Split("#").Count)] | ForEach-Object {
        $NewPost.NormalizedPost.Tags += $_.Split(" ")[0]
      }
    }


    if ( $IncludeLinkMetrics ) {
      if ( $NewPost.NormalizedPost.SharedLinks -gt 0 ) {
        $NewPost.NormalizedPost.SharedLinks | ForEach-Object {
          if ( $_ -like "*bit*" ) {
            $LinkGlobalMetrics                          = Get-BLLinkGlobalMetrics $_

            $NewPost.NormalizedPost.ClickThroughsCount += $LinkGlobalMetrics.clicks.link_clicks
            $NewPost.NormalizedPost.InteractionsCount  += $LinkGlobalMetrics.shares.total_shares

            Start-Sleep -Seconds $connections.BitLy.ApiDelay
          }
        }
      }
    }

    $NewPost.NormalizedPost.InterestCount               = $post.LikesCount
    $NewPost.NormalizedPost.InteractionsCount           = $post.CommentsCount

    $ExistingConnections                                = $NewPost.PostConnections.count
    $i                                                  = $ExistingConnections

    if ( $post.PeopleEngaged.count -gt 0 ) {
      $NewPost.PostConnections                         += New-Object PSObject -Property $UserConnectionsTemplate

      $post.PeopleEngaged | ForEach-Object {
        $NewPost.PostConnections[$i].UserId             = if ( $connections.LinkedIn.PrivacyLevel -eq $PRIVACY_LEVEL_NONE ) { $_.UserId            } else { Get-SMPostDigest $_.UserId            }
        $NewPost.PostConnections[$i].UserDisplayName    = if ( $connections.LinkedIn.PrivacyLevel -eq $PRIVACY_LEVEL_NONE ) { $_.UserDisplayName   } else { Get-SMPostDigest $_.UserDisplayName   }
        $NewPost.PostConnections[$i].UserDescription    = $_.UserDescription
        $NewPost.PostConnections[$i].UserProfileUrl     = if ( $connections.LinkedIn.PrivacyLevel -le $PRIVACY_LEVEL_NONE ) { $_.UserProfileUrl    } else { Get-SMPostDigest $_.UserProfileUrl    }
        $NewPost.PostConnections[$i].UserProfileApiUrl  = if ( $connections.LinkedIn.PrivacyLevel -le $PRIVACY_LEVEL_NONE ) { $_.UserProfileApiUrl } else { Get-SMPostDigest $_.UserProfileApiUrl }
        $NewPost.PostConnections[$i].EngagementType     = $_.EngagementType

        if ( ( $ExistingConnections + $post.PeopleEngaged.count ) -gt ( $i + 1 ) ) {
          $NewPost.PostConnections                     += New-Object PSObject -Property $UserConnectionsTemplate
        }

        $i++
      }
    }

    Start-Sleep -Seconds $TimeToWait

    $NewPost.RawObject                                  = $post

    $NewPost

    # $DebugPreference = "SilentlyContinue"
  }
}


function Update-LINPosts( [PSObject[]] $from ) {
  <#
    .SYNOPSIS
      Updates information about a collection of posts. Unlike Update-LINPost, this function doesn't accept data from the pipeline. Howerver, it does provide feedback about the progress of the update process.

    .DESCRIPTION
      Updates information about a collection of posts. Unlike Update-LINPost, this function doesn't accept data from the pipeline. Howerver, it does provide feedback about the progress of the update process.

    .EXAMPLE
      $UpdatedFacebookTimeLine = Update-LINPosts -from $NormalizedTimeLine
      $UpdatedFacebookTimeLine = Update-LINPosts -from $PermaLinksList

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  [System.Collections.ArrayList] $UpdatedPosts = @()

  $i               = 1
  $ExecutionTime   = [Diagnostics.Stopwatch]::StartNew()
  $ExecutionTime.Stop()

  foreach ( $post in $from ) {
    Write-Progress -Activity "Updating Posts ..." -Status "Progress: $i / $($from.Count) - ETC: $( '{0:#0.00}' -f $( $($from.Count) - $i ) * $ExecutionTime.Elapsed.TotalMinutes ) minutes - Time Elapsed: $( '{0:#0.00}' -f $( $i *  $ExecutionTime.Elapsed.TotalMinutes ) ) minutes" -PercentComplete ( ( $i / $($from.Count) ) * 100 )

    Write-Debug "[Update-LINPosts] - CurrentElement:      $i"
    Write-Debug "[Update-LINPosts] - TotalElements:       $($from.Count)"
    Write-Debug "[Update-LINPosts] - ElapsedMinutes:      $($ExecutionTime.Elapsed.TotalMinutes)"

    $ExecutionTime = [Diagnostics.Stopwatch]::StartNew()

    $UpdatedPosts.Add( $( $post | Update-LINPost -IncludeAll | ConvertTo-JSON ) ) | Out-Null

    $ExecutionTime.Stop()

    $i++
  }

  Write-Debug "[Update-LINPosts] Updated Elements:   $($UpdatedPosts.Count)"

  $UpdatedPosts | ForEach-Object { if ( $_ -ne $null ) { ConvertFrom-JSON $_ } }
}


function Update-LINPost( [switch] $IncludeAll, [int] $results = $connnections.LinkedIn.DefaultResultsToReturn, [string] $schema = $SCHEMA_DEFAULT ) {
  <#
    .SYNOPSIS
      Updates information about a collection of posts. Unlike Update-LINPosts, this function accepts data from the pipeline. Howerver, it doesn't provide feedback about the progress of the update process.

    .DESCRIPTION
      Updates information about a collection of posts. Unlike Update-LINPosts, this function accepts data from the pipeline. Howerver, it doesn't provide feedback about the progress of the update process.

    .EXAMPLE
      $UpdatedLINPost     = $NormalizedLinkedInPost     | Update-LINPost -IncludeAll
      $UpdatedLINTimeLine = $NormalizedLinkedInTimeLine | Update-LINPost -IncludeAll

      $UpdatedLINPost     = $PermaLink        | Update-LINPost -IncludeAll
      $UpdatedLINTimeLine = $PermaLinksList   | Update-LINPost -IncludeAll

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  begin {
    $LogFileName = "LinkedInModule"
    $TimeToWait  = $connections.LinkedIn.ApiDelay
  }

  process {
    $UpdatedPost                         = [PSCustomObject] @{}
    $SearchByPermalink                   = $false

    if ( $_ -is [string] ) {
      $post                              = New-SMPost -schema $schema
      $post.NormalizedPost.PermaLink     = $_.Split("?")[0]

      if ( $_ -ilike "*$CHANNEL_NAME_LINKEDIN*" ) {
        $post.NormalizedPost.ChannelName = $CHANNEL_NAME_LINKEDIN
        $SearchByPermalink               = $true
      } else {
        $post.NormalizedPost.ChannelName = $CHANNEL_NAME_UNKNOWN
      }
    } else {
      if ( $_.NormalizedPost -ne $null ) {
        $post                            = $_
      } else {
        Write-Debug "[Update-LINPost] - Skipping non-Normalized post."

        return $null
      }
    }


    if ( $post.NormalizedPost.ChannelName -eq $CHANNEL_NAME_LINKEDIN ) {
      if ( $IncludeAll ) {
        $UpdatedTimeLine                 = Get-LINTimeLine -results $results -UseFullCache
      } else {
        $UpdatedTimeLine                 = Get-LINTimeLine -results $results -quick -UseFullCache
      }

      if ( $SearchByPermalink ) {
        Write-Debug "[Update-LINPost] - Searching by PermaLink."

        $PostFromLinkedIn                = Search-RawLINPost -text $post.NormalizedPost.PermaLink  -on ([ref] $UpdatedTimeLine) -by permalink
      } else {
        Write-Debug "[Update-LINPost] - Searching by Digest."

        $PostFromLinkedIn                = Search-RawLINPost -text $post.NormalizedPost.PostDigest -on ([ref] $UpdatedTimeLine)
      }

      if ( $PostFromLinkedIn  -eq $null ) {
        "$(get-date -format u) [Update-LINPost] - Unable to retrieve post: $( $post.NormalizedPost.PermaLink )" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "[Update-LINPost] - Unable to retrieve post: $( $post.NormalizedPost.PermaLink )"

        return $null
      } else {
        # $PostFromLinkedIn                = $PostFromLinkedIn | ConvertTo-LINNormalizedPost -IncludeAll
      }
    } else {
      Write-Debug "[Update-LINPost] - Skipping non-LinkedIn post: $($_.ChannelName)"

      return $null
    }

    $ChangeLog                   = New-Object PSObject -Property $ChangeLogTemplate

    $ChangeLog.TimeStamp         = Get-Date -format $DefaultDateFormat
    $ChangeLog.PropertyName      = "LastUpdateDate"
    $ChangeLog.OriginalValue     = $post.LastUpdateDate
    $ChangeLog.NewValue          = $ChangeLog.TimeStamp

    $UpdatedPost                 = $post
    $UpdatedPost.LastUpdateDate  = $ChangeLog.TimeStamp
    [PSObject[]] $UpdatedPost.ChangeLog += $ChangeLog

    ( $UpdatedPost.NormalizedPost | Get-Member -MemberType NoteProperty ).Name | ForEach-Object {
      Write-Debug "[Update-LINPost] - Current Property Name: $_"

      if ( $post.NormalizedPost.$_ -ne $null ) {
        $CurrentChanges            = Compare-Object $post.NormalizedPost.$_ $PostFromLinkedIn.NormalizedPost.$_

        if ( $CurrentChanges.Count -ne 0 ) {
          $ChangeLog.TimeStamp     = $UpdatedPost.LastUpdateDate
          $ChangeLog.PropertyName  = $_
          $ChangeLog.OriginalValue = $post.NormalizedPost.$_
          $ChangeLog.NewValue      = $PostFromLinkedIn.NormalizedPost.$_

          [PSObject[]] $UpdatedPost.ChangeLog += $ChangeLog
        }
      }
    }

    $UpdatedPost.NormalizedPost  = $PostFromLinkedIn.NormalizedPost
    [PSObject[]] $UpdatedPost.RawObject += $PostFromLinkedIn.RawObject

    $UpdatedPost
  }
}


function Update-LINEngagedProfiles( [PSObject[]] $from ) {
  <#
    .SYNOPSIS
      Updates information about a collection of User Profiles. Unlike Update-LINUserProfileData, this function doesn't accept data from the pipeline. Howerver, it does provide feedback about the progress of the update process.

    .DESCRIPTION
      Updates information about a collection of User Profiles. Unlike Update-LINUserProfileData, this function doesn't accept data from the pipeline. Howerver, it does provide feedback about the progress of the update process.

    .EXAMPLE
      $UpdatedFacebookTimeLine = Update-LINEngagedProfiles -from $NormalizedTimeLine

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  [System.Collections.ArrayList] $UpdatedProfiles = @()

  $i               = 1
  $ExecutionTime   = [Diagnostics.Stopwatch]::StartNew()
  $ExecutionTime.Stop()

  foreach ( $profile in $from ) {
    Write-Progress -Activity "Updating Profiles ..." -Status "Progress: $i / $($from.Count) - ETC: $( '{0:#0.00}' -f $( $($from.Count) - $i ) * $ExecutionTime.Elapsed.TotalMinutes ) minutes - Time Elapsed: $( '{0:#0.00}' -f $( $i *  $ExecutionTime.Elapsed.TotalMinutes ) ) minutes" -PercentComplete ( ( $i / $($from.Count) ) * 100 )

    Write-Debug "[INFO] CurrentElement:      $i"
    Write-Debug "[INFO] TotalElements:       $($from.Count)"
    Write-Debug "[INFO] ElapsedMinutes:      $($ExecutionTime.Elapsed.TotalMinutes)"

    $ExecutionTime = [Diagnostics.Stopwatch]::StartNew()

    $UpdatedProfiles.Add( $( $profile | Update-LINUserProfileData | ConvertTo-JSON ) ) | Out-Null

    $ExecutionTime.Stop()

    $i++
  }

  $UpdatedProfiles | ForEach-Object { if ( $_ -ne $null ) { ConvertFrom-JSON $_ } }
}


function Update-LINUserProfileData() {
  <#
    .SYNOPSIS
      Updates information about a collection of User Profiles. Unlike Update-LINEngagedProfiles, this function accepts data from the pipeline. Howerver, it doesn't provide feedback about the progress of the update process.

    .DESCRIPTION
      Updates information about a collection of User Profiles. Unlike Update-LINEngagedProfiles, this function accepts data from the pipeline. Howerver, it doesn't provide feedback about the progress of the update process.

    .EXAMPLE
      $UpdatedLINPost     = $NormalizedLinkedInPost     | Update-LINUserProfileData
      $UpdatedLINTimeLine = $NormalizedLinkedInTimeLine | Update-LINUserProfileData

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  begin {
    $LogFileName = "LinkedInModule"
    $TimeToWait  = $connections.LinkedIn.ApiDelay
  }

  process {
    $UpdatedPost                 = [PSCustomObject] @{}
    $SearchByPermalink           = $false

    $post                        = $_
    $OriginalPost                = $post

    if ( $post.NormalizedPost.ChannelName -eq $CHANNEL_NAME_LINKEDIN ) {
      $post.PostConnections | Where-Object { $_.UserProfileUrl -eq $VALUE_NA } | ForEach-Object {
        $UserProfile             = Get-RawLINUserProfileUrl $_.UserId

        if ( $UserProfile -eq $null ) {
          $_.UserProfileUrl      = $VALUE_NA
        } else {
          if ( $connections.LinkedIn.PrivacyLevel -le $PRIVACY_LEVEL_LOW ) {
            $_.UserProfileUrl    = $UserProfile.UserProfileUrl
          } else {
            $_.UserProfileUrl    = Get-SMPostDigest $UserProfile.UserProfileUrl
          }
        }
      }
    } else {
      Write-Debug "[Update-LINUserProfileData] Skipping non-LinkedIn post: $($_.ChannelName)"

      return $null
    }

    $ChangeLog                   = New-Object PSObject -Property $ChangeLogTemplate

    $ChangeLog.TimeStamp         = Get-Date -format $DefaultDateFormat
    $ChangeLog.PropertyName      = "LastUpdateDate"
    $ChangeLog.OriginalValue     = $post.LastUpdateDate
    $ChangeLog.NewValue          = $ChangeLog.TimeStamp

    $UpdatedPost                 = $post
    $UpdatedPost.LastUpdateDate  = $ChangeLog.TimeStamp
    [PSObject[]] $UpdatedPost.ChangeLog += $ChangeLog

    ( $UpdatedPost.PostConnections | Get-Member -MemberType NoteProperty ).Name | ForEach-Object {
      Write-Debug "[Update-LINUserProfileData] - Current Property Name: $_"

      if ( $OriginalPost.PostConnections.$_ -ne $null ) {
        $CurrentChanges            = Compare-Object $OriginalPost.PostConnections.$_ $post.PostConnections.$_

        if ( $CurrentChanges.Count -ne 0 ) {
          $ChangeLog.TimeStamp     = $UpdatedPost.LastUpdateDate
          $ChangeLog.PropertyName  = $_
          $ChangeLog.OriginalValue = $OriginalPost.PostConnections.$_
          $ChangeLog.NewValue      = $post.PostConnections.$_

          [PSObject[]] $UpdatedPost.ChangeLog += $ChangeLog
        }
      }
    }

    $UpdatedPost
  }
}