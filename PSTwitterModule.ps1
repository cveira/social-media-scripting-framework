<#
-------------------------------------------------------------------------------
Name:    Social Media Scripting Framework
Module:  Twitter
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


[string] $TweetContentPattern = '((?s)<p[^>]*js-tweet-text tweet-text[^>]*>(?<TweetContent>.*?)</p>.*?'  + `
                                '<li[^>]*js-stat-count js-stat-retweets stat-count[^>]*>(?<ReTweetStats>.*?)</li>.*?' + `
                                '<li[^>]*js-stat-count js-stat-favorites stat-count[^>]*>(?<FavoritesStats>.*?)</li>)|' + `

                                '((?s)<p[^>]*js-tweet-text tweet-text[^>]*>(?<TweetContent>.*?)</p>.*?'  + `
                                '<li[^>]*js-stat-count js-stat-retweets stat-count[^>]*>(?<ReTweetStats>.*?)</li>)|' + `

                                '((?s)<p[^>]*js-tweet-text tweet-text[^>]*>(?<TweetContent>.*?)</p>.*?'  + `
                                '<li[^>]*js-stat-count js-stat-favorites stat-count[^>]*>(?<FavoritesStats>.*?)</li>)|' + `

                                '((?s)<p[^>]*js-tweet-text tweet-text[^>]*>(?<TweetContent>.*?)</p>)'


# --------------------------------------------------------------------------------------------------

function Get-RawRetweetsFromPage( [ref] $PageSourceCode ) {
  <#
    .SYNOPSIS
      Parses the raw HTML contents of a web-based tweet to get the number of retweets.

    .DESCRIPTION
      Parses the raw HTML contents of a web-based tweet to get the number of retweets.

    .EXAMPLE
      $SourceCode = Get-PageSourceCode https://twitter.com/cveira/status/275929500183830529
      Get-RawRetweetsFromPage ([ref] $SourceCode)

    .NOTES
      Low-level function. Depends on Get-PageSourceCode.

    .LINK
      N/A
  #>


  [string] $RetweetsCountPattern = '<strong[^>]*[^>]*>(?<RetweetsCount>.*?)</strong>'

  if ( $PageSourceCode.Value -match $TweetContentPattern ) {
    if ( $Matches.ReTweetStats -match $RetweetsCountPattern ) {
      $Matches.RetweetsCount
    } else {
      0
    }
  } else {
    0
  }
}


function Get-RawTweetFavoritesFromPage( [ref] $PageSourceCode ) {
  <#
    .SYNOPSIS
      Parses the raw HTML contents of a web-based tweet to get the number of favorites.

    .DESCRIPTION
      Parses the raw HTML contents of a web-based tweet to get the number of favorites.

    .EXAMPLE
      $SourceCode = Get-PageSourceCode https://twitter.com/cveira/status/275929500183830529
      Get-RawTweetFavoritesFromPage ([ref] $SourceCode)

    .NOTES
      Low-level function. Depends on Get-PageSourceCode.

    .LINK
      N/A
  #>


  [string] $FavoritesCountPattern = '<strong[^>]*[^>]*>(?<FavoritesCount>.*?)</strong>'

  if ( $PageSourceCode.Value -match $TweetContentPattern ) {
    if ( $Matches.FavoritesStats -match $FavoritesCountPattern ) {
      $Matches.FavoritesCount
    } else {
      0
    }
  } else {
    0
  }
}


function Get-RawTweetContentFromPage( [ref] $PageSourceCode ) {
  <#
    .SYNOPSIS
      Parses the raw HTML contents of a web-based tweet to get the tweet content itself.

    .DESCRIPTION
      Parses the raw HTML contents of a web-based tweet to get the tweet content itself.

    .EXAMPLE
      $SourceCode = Get-PageSourceCode https://twitter.com/cveira/status/275929500183830529
      Get-RawTweetContentFromPage ([ref] $SourceCode)

    .NOTES
      Low-level function. Depends on Get-PageSourceCode.

    .LINK
      N/A
  #>


  if ( $PageSourceCode.Value -match $TweetContentPattern ) {
    $Matches.TweetContent
  } else {
    "N/D"
  }
}


function Get-RawTweetLinksFromPage( [ref] $PageSourceCode ) {
  <#
    .SYNOPSIS
      Parses the raw HTML contents of a web-based tweet to get the links shared in a tweet.

    .DESCRIPTION
      Parses the raw HTML contents of a web-based tweet to get the links shared in a tweet.

    .EXAMPLE
      $SourceCode = Get-PageSourceCode https://twitter.com/cveira/status/275929500183830529
      Get-RawTweetLinksFromPage ([ref] $SourceCode)

    .NOTES
      Low-level function. Depends on Get-PageSourceCode.

    .LINK
      N/A
  #>


  [RegEx]    $LinksPattern = '(data-expanded-url="(.*?)")+'
  [string[]] $TweetLinks   = @()


  if ( $PageSourceCode.Value -match $TweetContentPattern ) {
    $CurrentMatch = $LinksPattern.match($Matches.TweetContent)

    if (!$CurrentMatch.Success) {
      $TweetLinks +=  "N/D"
    }

    while ($CurrentMatch.Success) {
      $TweetLinks   += $CurrentMatch.Value.Split('"')[1]
      $CurrentMatch =  $CurrentMatch.NextMatch()
    }
  } else {
    $TweetLinks +=  "N/D"
  }

  $TweetLinks
}


function Get-RawTweetHashTagsFromPage( [ref] $PageSourceCode ) {
  <#
    .SYNOPSIS
      Parses the raw HTML contents of a web-based tweet to get the HashTags shared in a tweet.

    .DESCRIPTION
      Parses the raw HTML contents of a web-based tweet to get the HashTags shared in a tweet.

    .EXAMPLE
      $SourceCode = Get-PageSourceCode https://twitter.com/cveira/status/275929500183830529
      Get-RawTweetHashTagsFromPage ([ref] $SourceCode)

    .NOTES
      Low-level function. Depends on Get-PageSourceCode.

    .LINK
      N/A
  #>


  [string]   $HashTagNamePattern = "%23(?<HashTag>.*?)&amp"
  [RegEx]    $LinksPattern       = '(href="(.*?)")+'
  [string[]] $TweetLinks         = @()


  if ( $PageSourceCode.Value -match $TweetContentPattern ) {
    $CurrentMatch = $LinksPattern.match($Matches.TweetContent)

    if (!$CurrentMatch.Success) {
      $TweetLinks +=  "N/D"
    }

    while ($CurrentMatch.Success) {
      if ( $CurrentMatch.Value -match $HashTagNamePattern ) { $TweetLinks   += $Matches.HashTag }

      $CurrentMatch =  $CurrentMatch.NextMatch()
    }
  } else {
    $TweetLinks +=  "N/D"
  }

  $TweetLinks
}


# --------------------------------------------------------------------------------------------------


function Set-OAuthSignature( [string] $HttpRequestType, [string] $HttpEndpoint, [string] $HttpQueryString, [string] $OAuthNonce, [string] $OAuthTimeStamp, [string] $OAuthConsumerKey, [string] $OAuthConsumerSecret, [string] $OAuthToken, [string] $OAuthTokenSecret ) {
  <#
    .SYNOPSIS
      Builds the OAuth 1.0A signature for the HTTP Authentication Header.

    .DESCRIPTION
      Builds the OAuth 1.0A signature for the HTTP Authentication Header.

    .EXAMPLE
      N/A

    .NOTES
      Low-level function (API).

    .LINK
      N/A
  #>


  [string[]] $HttpQueryStringParameters
  $ParameterString = @{}

  if ( $HttpQueryString.Length -gt 0 ) {
    $HttpQueryStringParameters = $HttpQueryString.Split("&")
    $HttpQueryStringParameters | ForEach-Object { $ParameterString.Add( $_.Split("=")[0], $_.Split("=")[1] ) }
  }

  $ParameterString.Add( "oauth_consumer_key",     $OAuthConsumerKey )
  $ParameterString.Add( "oauth_nonce",            $OAuthNonce )
  $ParameterString.Add( "oauth_signature_method", "HMAC-SHA1" )
  $ParameterString.Add( "oauth_timestamp",        $OAuthTimeStamp )
  $ParameterString.Add( "oauth_token",            $OAuthToken )
  $ParameterString.Add( "oauth_version",          "1.0" )

  $signature             =  $HttpRequestType + "&"

  # 1. The URL in the signature string HAS NO QUERY_STRING PARAMETERS

  $signature             += [System.Uri]::EscapeDataString($HttpEndpoint) + "&"

  # 2. All the parameters included in the QUERY_STRING {when calling [System.Net.WebRequest]::Create()} have to be included in the signature
  # 3. When building the signature string, parameters must be in alphabetical order.

  $ParameterString.Keys | Sort-Object | ForEach-Object {
    # [System.Uri]::EscapeDataString($_ + "=" + $ParameterString.$_ + "&") is not RFC3986 compliant in .NET < 4.x!
    # RFC3986 compliancy is documented in OAuth 1.0A, not in Twitter documentation!

    $signature    += EscapeDataStringRfc3986 $($_ + "=" + $ParameterString.$_ + "&")
  }

  $signature      = $signature.Substring(0, $signature.Length - 3)

  $SignatureKey   = [System.Uri]::EscapeDataString($OAuthConsumerSecret) + "&" + [System.Uri]::EscapeDataString($OAuthTokenSecret)

  $Hasher         = New-Object System.Security.Cryptography.HMACSHA1
  $Hasher.Key     = [System.Text.Encoding]::ASCII.GetBytes($SignatureKey)

  $OAuthSignature = [System.Convert]::ToBase64String($Hasher.ComputeHash([System.Text.Encoding]::ASCII.GetBytes($signature)))

  $OAuthSignature
}


function Set-OAuthHeader( [string] $OAuthConsumerKey, [string] $OAuthNonce, [string] $OAuthSignature, [string] $OAuthTimeStamp, [string] $OAuthToken ) {
  <#
    .SYNOPSIS
      Builds the OAuth 1.0A HTTP Authentication Header.

    .DESCRIPTION
      Builds the OAuth 1.0A HTTP Authentication Header.

    .EXAMPLE
      N/A

    .NOTES
      Low-level function (API).

    .LINK
      N/A
  #>


  $OAuthHeader   =  'OAuth '
  $OAuthHeader   += 'oauth_consumer_key="' + [System.Uri]::EscapeDataString($OAuthConsumerKey) + '", '
  $OAuthHeader   += 'oauth_nonce="' + [System.Uri]::EscapeDataString($OAuthNonce) + '", '
  $OAuthHeader   += 'oauth_signature="' + [System.Uri]::EscapeDataString($OAuthSignature) + '", '
  $OAuthHeader   += 'oauth_signature_method="HMAC-SHA1", '
  $OAuthHeader   += 'oauth_timestamp="' + [System.Uri]::EscapeDataString($OAuthTimeStamp) + '", '
  $OAuthHeader   += 'oauth_token="' + [System.Uri]::EscapeDataString($OAuthToken) + '", '
  $OAuthHeader   += 'oauth_version="1.0"'

  $OAuthHeader
}


function Get-RawTwitterMentionsAsJson {
  <#
    .SYNOPSIS
      Returns most recent mentions (tweets containing a users's @screen_name) for the authenticating user.

    .DESCRIPTION
      Returns most recent mentions (tweets containing a users's @screen_name) for the authenticating user.

      The timeline returned is the equivalent of the one seen when you view your mentions on twitter.com.

      This method can only return up to 800 tweets

    .EXAMPLE
      Get-RawTwitterMentionsAsJson | ConvertFrom-Json

    .NOTES
      Low-level function (API).

    .LINK
      https://dev.twitter.com/docs/api/1.1/get/statuses/mentions_timeline
  #>


  $LogFileName                 = "TwitterModule"

  [string] $HttpRequestType    = "GET"
  [string] $HttpEndpoint       = ""
  [string] $HttpQueryString    = ""

  [string] $ApiURL             = "https://api.twitter.com/1.1/statuses/mentions_timeline.json?count=20&include_entities=true&include_rts=true"

  if ( $ApiURL.IndexOf("?") -ne -1 ) {
    $HttpEndpoint              = $ApiURL.Split("?")[0]
    $HttpQueryString           = $ApiURL.Split("?")[1]
  } else {
    $HttpEndpoint              = $ApiURL
    $HttpQueryString           = ""
  }

  $OAuthConsumerKey            = $connections.Twitter.ConsumerKey
  $OAuthConsumerSecret         = $connections.Twitter.ConsumerSecret
  $OAuthToken                  = $connections.Twitter.AccessToken
  $OAuthTokenSecret            = $connections.Twitter.AccessTokenSecret

  $OAuthNonce                  = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes([System.DateTime]::Now.Ticks.ToString()))
  $TimeStamp                   = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact("01/01/1970", "dd/MM/yyyy", $null).ToUniversalTime()
  $OAuthTimeStamp              = [System.Convert]::ToInt64($TimeStamp.TotalSeconds).ToString()

  $OAuthSignature              = Set-OAuthSignature $HttpRequestType $HttpEndpoint $HttpQueryString $OAuthNonce $OAuthTimeStamp $OAuthConsumerKey $OAuthConsumerSecret $OAuthToken $OAuthTokenSecret
  $OAuthHeader                 = Set-OAuthHeader    $OAuthConsumerKey $OAuthNonce $OAuthSignature $OAuthTimeStamp $OAuthToken

  try {
    $ApiResponse = & $BinDir\curl.exe -s -k -X GET -H "Accept: application/x-www-form-urlencoded" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: $OAuthHeader" --user-agent $DefaultUserAgent $ApiURL

    Write-Debug "[Get-RawTwitterMentionsAsJson] - ApiURL:        $ApiURL"
    Write-Debug "[Get-RawTwitterMentionsAsJson] -   OAuthHeader: $OAuthHeader"

    if ( ( $ApiResponse -ilike "*errors*" ) -and ( $ApiResponse -ilike "*message*" ) -and ( $ApiResponse -ilike "*code*" ) ) {
      "$(get-date -format u) [Get-RawTwitterMentionsAsJson] - Unable to retrieve mentions for logged in user."  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterMentionsAsJson] -   ApiURL:      $ApiURL"                           >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterMentionsAsJson] -   OAuthHeader: $OAuthHeader"                      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterMentionsAsJson] -   ApiResponse: $ApiResponse"                      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawTwitterMentionsAsJson] -   Unable to retrieve mentions for logged in user."
      Write-Debug "[Get-RawTwitterMentionsAsJson] -     ApiResponse: $ApiResponse"

      $ApiResponse = "Exception"
    }

    $ApiResponse
  } catch {
    "$(get-date -format u) [Get-RawTwitterMentionsAsJson] - Unable to retrieve mentions for logged in user." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterMentionsAsJson] -   ApiURL:      $ApiURL"                          >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterMentionsAsJson] -   OAuthHeader: $OAuthHeader"                     >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterMentionsAsJson] -   ApiResponse: $ApiResponse"                     >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawTwitterMentionsAsJson] - Unable to retrieve mentions for logged in user."
    Write-Debug "[Get-RawTwitterMentionsAsJson] -   ApiURL:      $ApiURL"
    Write-Debug "[Get-RawTwitterMentionsAsJson] -   OAuthHeader: $OAuthHeader"
    Write-Debug "[Get-RawTwitterMentionsAsJson] -   ApiResponse: $ApiResponse"

    $_.Exception.Message
  }
}


function Get-RawTweetRetweetsAsJson( [string] $TweetPermaLink ) {
  <#
    .SYNOPSIS
      Returns a collection of the 100 most recent retweets of the tweet specified by the id parameter.

    .DESCRIPTION
      Returns a collection of the 100 most recent retweets of the tweet specified by the id parameter.

    .EXAMPLE
      Get-RawTweetRetweetsAsJson https://twitter.com/cveira/status/275929500183830529    | ConvertFrom-Json
      Get-RawTweetRetweetsAsJson http://twitter.com/TechCrunch/status/282712924752060417 | ConvertFrom-Json

    .NOTES
      Low-level function (API).

    .LINK
      https://dev.twitter.com/docs/api/1.1/get/statuses/retweets/%3Aid
  #>


  $LogFileName                 = "TwitterModule"

  [string] $HttpRequestType    = "GET"
  [string] $HttpEndpoint       = ""
  [string] $HttpQueryString    = ""

  [string] $ApiURL             = "https://api.twitter.com/1.1/statuses/retweets/" + $TweetPermaLink.Split("/")[5] + ".json?count=$($connections.Twitter.DefaultResultsToReturn)"

  if ( $ApiURL.IndexOf("?") -ne -1 ) {
    $HttpEndpoint              = $ApiURL.Split("?")[0]
    $HttpQueryString           = $ApiURL.Split("?")[1]
  } else {
    $HttpEndpoint              = $ApiURL
    $HttpQueryString           = ""
  }

  $OAuthConsumerKey            = $connections.Twitter.ConsumerKey
  $OAuthConsumerSecret         = $connections.Twitter.ConsumerSecret
  $OAuthToken                  = $connections.Twitter.AccessToken
  $OAuthTokenSecret            = $connections.Twitter.AccessTokenSecret

  $OAuthNonce                  = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes([System.DateTime]::Now.Ticks.ToString()))
  $TimeStamp                   = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact("01/01/1970", "dd/MM/yyyy", $null).ToUniversalTime()
  $OAuthTimeStamp              = [System.Convert]::ToInt64($TimeStamp.TotalSeconds).ToString()

  $OAuthSignature              = Set-OAuthSignature $HttpRequestType $HttpEndpoint $HttpQueryString $OAuthNonce $OAuthTimeStamp $OAuthConsumerKey $OAuthConsumerSecret $OAuthToken $OAuthTokenSecret
  $OAuthHeader                 = Set-OAuthHeader    $OAuthConsumerKey $OAuthNonce $OAuthSignature $OAuthTimeStamp $OAuthToken

  try {
    $ApiResponse = & $BinDir\curl.exe -s -k -X GET -H "Accept: application/x-www-form-urlencoded" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: $OAuthHeader" --user-agent $DefaultUserAgent $ApiURL

    Write-Debug "[Get-RawTweetRetweetsAsJson] - ApiURL:        $ApiURL"
    Write-Debug "[Get-RawTweetRetweetsAsJson] -   OAuthHeader: $OAuthHeader"

    if ( ( $ApiResponse -ilike "*errors*" ) -and ( $ApiResponse -ilike "*message*" ) -and ( $ApiResponse -ilike "*code*" ) ) {
      "$(get-date -format u) [Get-RawTweetRetweetsAsJson] - Unable to retrieve retweets."  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTweetRetweetsAsJson] -   ApiURL:      $ApiURL"        >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTweetRetweetsAsJson] -   OAuthHeader: $OAuthHeader"   >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTweetRetweetsAsJson] -   ApiResponse: $ApiResponse"   >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawTweetRetweetsAsJson] -   Unable to retrieve retweets."
      Write-Debug "[Get-RawTweetRetweetsAsJson] -     ApiResponse: $ApiResponse"

      $ApiResponse = "Exception"
    }

    $ApiResponse
  } catch {
    "$(get-date -format u) [Get-RawTweetRetweetsAsJson] - Unable to retrieve retweets." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTweetRetweetsAsJson] -   ApiURL:      $ApiURL"       >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTweetRetweetsAsJson] -   OAuthHeader: $OAuthHeader"  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTweetRetweetsAsJson] -   ApiResponse: $ApiResponse"  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawTweetRetweetsAsJson] - Unable to retrieve retweets."
    Write-Debug "[Get-RawTweetRetweetsAsJson] -   ApiURL:      $ApiURL"
    Write-Debug "[Get-RawTweetRetweetsAsJson] -   OAuthHeader: $OAuthHeader"
    Write-Debug "[Get-RawTweetRetweetsAsJson] -   ApiResponse: $ApiResponse"

    $_.Exception.Message
  }
}


function Get-RawTweetAsJson( [string] $TweetPermaLink ) {
  <#
    .SYNOPSIS
      Returns a single Tweet, specified by the id parameter. The Tweet's author will also be embedded within the tweet.

    .DESCRIPTION
      Returns a single Tweet, specified by the id parameter. The Tweet's author will also be embedded within the tweet.

    .EXAMPLE
      Get-RawTweetAsJson https://twitter.com/cveira/status/275929500183830529 | ConvertFrom-Json

    .NOTES
      Low-level function (API).

    .LINK
      https://dev.twitter.com/docs/api/1.1/get/statuses/show/%3Aid
  #>


  $LogFileName                 = "TwitterModule"

  [string] $HttpRequestType    = "GET"
  [string] $HttpEndpoint       = ""
  [string] $HttpQueryString    = ""

  [string] $ApiURL             = "https://api.twitter.com/1.1/statuses/show.json?id=" + $TweetPermaLink.Split("/")[5] + "&include_entities=true"

  if ( $ApiURL.IndexOf("?") -ne -1 ) {
    $HttpEndpoint              = $ApiURL.Split("?")[0]
    $HttpQueryString           = $ApiURL.Split("?")[1]
  } else {
    $HttpEndpoint              = $ApiURL
    $HttpQueryString           = ""
  }

  $OAuthConsumerKey            = $connections.Twitter.ConsumerKey
  $OAuthConsumerSecret         = $connections.Twitter.ConsumerSecret
  $OAuthToken                  = $connections.Twitter.AccessToken
  $OAuthTokenSecret            = $connections.Twitter.AccessTokenSecret

  $OAuthNonce                  = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes([System.DateTime]::Now.Ticks.ToString()))
  $TimeStamp                   = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact("01/01/1970", "dd/MM/yyyy", $null).ToUniversalTime()
  $OAuthTimeStamp              = [System.Convert]::ToInt64($TimeStamp.TotalSeconds).ToString()

  $OAuthSignature              = Set-OAuthSignature $HttpRequestType $HttpEndpoint $HttpQueryString $OAuthNonce $OAuthTimeStamp $OAuthConsumerKey $OAuthConsumerSecret $OAuthToken $OAuthTokenSecret
  $OAuthHeader                 = Set-OAuthHeader    $OAuthConsumerKey $OAuthNonce $OAuthSignature $OAuthTimeStamp $OAuthToken

  try {
    $ApiResponse = & $BinDir\curl.exe -s -k -X GET -H "Accept: application/x-www-form-urlencoded" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: $OAuthHeader" --user-agent $DefaultUserAgent $ApiURL

    Write-Debug "[Get-RawTweetAsJson] - ApiURL:        $ApiURL"
    Write-Debug "[Get-RawTweetAsJson] -   OAuthHeader: $OAuthHeader"

    if ( ( $ApiResponse -ilike "*errors*" ) -and ( $ApiResponse -ilike "*message*" ) -and ( $ApiResponse -ilike "*code*" ) ) {
      "$(get-date -format u) [Get-RawTweetAsJson] - Unable to retrieve post."    >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTweetAsJson] -   ApiURL:      $ApiURL"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTweetAsJson] -   OAuthHeader: $OAuthHeader" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTweetAsJson] -   ApiResponse: $ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawTweetAsJson] -   Unable to retrieve post."
      Write-Debug "[Get-RawTweetAsJson] -     ApiResponse: $ApiResponse"

      $ApiResponse = "Exception"
    }

    $ApiResponse
  } catch {
    "$(get-date -format u) [Get-RawTweetAsJson] - Unable to retrieve post."    >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTweetAsJson] -   ApiURL:      $ApiURL"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTweetAsJson] -   OAuthHeader: $OAuthHeader" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTweetAsJson] -   ApiResponse: $ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawTweetAsJson] - Unable to retrieve post."
    Write-Debug "[Get-RawTweetAsJson] -   ApiURL:      $ApiURL"
    Write-Debug "[Get-RawTweetAsJson] -   OAuthHeader: $OAuthHeader"
    Write-Debug "[Get-RawTweetAsJson] -   ApiResponse: $ApiResponse"

    $_.Exception.Message
  }
}


function Get-RawTwitterFavoritesAsJson( [string] $from ) {
  <#
    .SYNOPSIS
      Returns the 20 most recent Tweets favorited by the authenticating or specified user.

    .DESCRIPTION
      Returns the 20 most recent Tweets favorited by the authenticating or specified user.

    .EXAMPLE
      Get-RawTwitterFavoritesAsJson cveira | ConvertFrom-Json

    .NOTES
      Low-level function (API).

    .LINK
      https://dev.twitter.com/docs/api/1.1/get/favorites/list
  #>


  $LogFileName                 = "TwitterModule"

  [string] $HttpRequestType    = "GET"
  [string] $HttpEndpoint       = ""
  [string] $HttpQueryString    = ""

  [string] $ApiURL             = "https://api.twitter.com/1.1/favorites/list.json?count=20&screen_name=" + $from.Trim() + "&include_entities=true"

  if ( $ApiURL.IndexOf("?") -ne -1 ) {
    $HttpEndpoint              = $ApiURL.Split("?")[0]
    $HttpQueryString           = $ApiURL.Split("?")[1]
  } else {
    $HttpEndpoint              = $ApiURL
    $HttpQueryString           = ""
  }

  $OAuthConsumerKey            = $connections.Twitter.ConsumerKey
  $OAuthConsumerSecret         = $connections.Twitter.ConsumerSecret
  $OAuthToken                  = $connections.Twitter.AccessToken
  $OAuthTokenSecret            = $connections.Twitter.AccessTokenSecret

  $OAuthNonce                  = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes([System.DateTime]::Now.Ticks.ToString()))
  $TimeStamp                   = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact("01/01/1970", "dd/MM/yyyy", $null).ToUniversalTime()
  $OAuthTimeStamp              = [System.Convert]::ToInt64($TimeStamp.TotalSeconds).ToString()

  $OAuthSignature              = Set-OAuthSignature $HttpRequestType $HttpEndpoint $HttpQueryString $OAuthNonce $OAuthTimeStamp $OAuthConsumerKey $OAuthConsumerSecret $OAuthToken $OAuthTokenSecret
  $OAuthHeader                 = Set-OAuthHeader    $OAuthConsumerKey $OAuthNonce $OAuthSignature $OAuthTimeStamp $OAuthToken

  try {
    $ApiResponse = & $BinDir\curl.exe -s -k -X GET -H "Accept: application/x-www-form-urlencoded" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: $OAuthHeader" --user-agent $DefaultUserAgent $ApiURL

    Write-Debug "[Get-RawTwitterFavoritesAsJson] - ApiURL:        $ApiURL"
    Write-Debug "[Get-RawTwitterFavoritesAsJson] -   OAuthHeader: $OAuthHeader"

    if ( ( $ApiResponse -ilike "*errors*" ) -and ( $ApiResponse -ilike "*message*" ) -and ( $ApiResponse -ilike "*code*" ) ) {
      "$(get-date -format u) [Get-RawTwitterFavoritesAsJson] - Unable to retrieve favorites." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterFavoritesAsJson] -   ApiURL:      $ApiURL"        >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterFavoritesAsJson] -   OAuthHeader: $OAuthHeader"   >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterFavoritesAsJson] -   ApiResponse: $ApiResponse"   >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawTwitterFavoritesAsJson] -   Unable to retrieve favorites."
      Write-Debug "[Get-RawTwitterFavoritesAsJson] -     ApiResponse: $ApiResponse"

      $ApiResponse = "Exception"
    }

    $ApiResponse
  } catch {
    "$(get-date -format u) [Get-RawTwitterFavoritesAsJson] - Unable to retrieve favorites." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterFavoritesAsJson] -   ApiURL:      $ApiURL"        >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterFavoritesAsJson] -   OAuthHeader: $OAuthHeader"   >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterFavoritesAsJson] -   ApiResponse: $ApiResponse"   >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawTwitterFavoritesAsJson] - Unable to retrieve favorites."
    Write-Debug "[Get-RawTwitterFavoritesAsJson] -   ApiURL:      $ApiURL"
    Write-Debug "[Get-RawTwitterFavoritesAsJson] -   OAuthHeader: $OAuthHeader"
    Write-Debug "[Get-RawTwitterFavoritesAsJson] -   ApiResponse: $ApiResponse"

    $_.Exception.Message
  }
}


function Get-RawTweetsFromUserAsJson( [string] $name, [int] $results = $connections.Twitter.DefaultResultsToReturn, [string] $FirstId = "", [string] $LastId = "" ) {
  <#
    .SYNOPSIS
      Returns a collection of the most recent Tweets posted by the user indicated by the Name parameter.

    .DESCRIPTION
      Returns a collection of the most recent Tweets posted by the user indicated by the Name parameter.

      User timelines belonging to protected users may only be requested when the authenticated user either "owns" the timeline or is an approved follower of the owner.

      The timeline returned is the equivalent of the one seen when you view a user's profile on twitter.com.

      This method can only return up to 3,200 of a user's most recent Tweets. Native retweets of other statuses by the user is included in this total.


    .EXAMPLE
      Get-RawTweetsFromUserAsJson cveira | ConvertFrom-Json

    .NOTES
      Low-level function (API).

    .LINK
      https://dev.twitter.com/docs/api/1.1/get/statuses/user_timeline
  #>


  $LogFileName                 = "TwitterModule"

  [string] $HttpRequestType    = "GET"
  [string] $HttpEndpoint       = ""
  [string] $HttpQueryString    = ""
  [string] $FilterParameters   = ""

  if ( ( $FirstId -ne "" ) -and ( $FirstId -match "\d+" ) ) { $FilterParameters += "&max_id="   + $FirstId }
  if ( ( $LastId  -ne "" ) -and ( $LastId  -match "\d+" ) ) { $FilterParameters += "&since_id=" + $LastId  }

  [string] $ApiURL             = "https://api.twitter.com/1.1/statuses/user_timeline.json?include_entities=true&include_rts=true&exclude_replies=true&count=" + $results + $FilterParameters + "&screen_name=" + $name.Trim()

  if ( $ApiURL.IndexOf("?") -ne -1 ) {
    $HttpEndpoint              = $ApiURL.Split("?")[0]
    $HttpQueryString           = $ApiURL.Split("?")[1]
  } else {
    $HttpEndpoint              = $ApiURL
    $HttpQueryString           = ""
  }

  $OAuthConsumerKey            = $connections.Twitter.ConsumerKey
  $OAuthConsumerSecret         = $connections.Twitter.ConsumerSecret
  $OAuthToken                  = $connections.Twitter.AccessToken
  $OAuthTokenSecret            = $connections.Twitter.AccessTokenSecret

  $OAuthNonce                  = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes([System.DateTime]::Now.Ticks.ToString()))
  $TimeStamp                   = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact("01/01/1970", "dd/MM/yyyy", $null).ToUniversalTime()
  $OAuthTimeStamp              = [System.Convert]::ToInt64($TimeStamp.TotalSeconds).ToString()

  $OAuthSignature              = Set-OAuthSignature $HttpRequestType $HttpEndpoint $HttpQueryString $OAuthNonce $OAuthTimeStamp $OAuthConsumerKey $OAuthConsumerSecret $OAuthToken $OAuthTokenSecret
  $OAuthHeader                 = Set-OAuthHeader    $OAuthConsumerKey $OAuthNonce $OAuthSignature $OAuthTimeStamp $OAuthToken

  try {
    $ApiResponse = & $BinDir\curl.exe -s -k -X GET -H "Accept: application/x-www-form-urlencoded" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: $OAuthHeader" --user-agent $DefaultUserAgent $ApiURL

    Write-Debug "[Get-RawTweetsFromUserAsJson] - ApiURL:        $ApiURL"
    Write-Debug "[Get-RawTweetsFromUserAsJson] -   OAuthHeader: $OAuthHeader"

    if ( ( $ApiResponse -ilike "*errors*" ) -and ( $ApiResponse -ilike "*message*" ) -and ( $ApiResponse -ilike "*code*" ) ) {
      "$(get-date -format u) [Get-RawTweetsFromUserAsJson] - Unable to retrieve tweets."  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTweetsFromUserAsJson] -   ApiURL:      $ApiURL"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTweetsFromUserAsJson] -   OAuthHeader: $OAuthHeader" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTweetsFromUserAsJson] -   ApiResponse: $ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawTweetsFromUserAsJson] -   Unable to retrieve tweets."
      Write-Debug "[Get-RawTweetsFromUserAsJson] -     ApiResponse: $ApiResponse"

      $ApiResponse = "Exception"
    }

    $ApiResponse
  } catch {
    "$(get-date -format u) [Get-RawTweetsFromUserAsJson] - Unable to retrieve tweets."  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTweetsFromUserAsJson] -   ApiURL:      $ApiURL"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTweetsFromUserAsJson] -   OAuthHeader: $OAuthHeader" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTweetsFromUserAsJson] -   ApiResponse: $ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawTweetsFromUserAsJson] - Unable to retrieve tweets."
    Write-Debug "[Get-RawTweetsFromUserAsJson] -   ApiURL:      $ApiURL"
    Write-Debug "[Get-RawTweetsFromUserAsJson] -   OAuthHeader: $OAuthHeader"
    Write-Debug "[Get-RawTweetsFromUserAsJson] -   ApiResponse: $ApiResponse"

    $_.Exception.Message
  }
}


function Get-RawTwitterTimeLineAsJson {
  <#
    .SYNOPSIS
      Returns a collection of the most recent Tweets and retweets posted by the authenticating user and the users they follow.

    .DESCRIPTION
      Returns a collection of the most recent Tweets and retweets posted by the authenticating user and the users they follow. The home timeline is central to how most users interact with the Twitter service.

      Up to 800 Tweets are obtainable on the home timeline. It is more volatile for users that follow many users or follow users who tweet frequently.

    .EXAMPLE
      Get-RawTwitterTimeLineAsJson | ConvertFrom-Json

    .NOTES
      Low-level function (API).

    .LINK
      https://dev.twitter.com/docs/api/1.1/get/statuses/home_timeline
  #>


  $LogFileName                 = "TwitterModule"

  [string] $HttpRequestType    = "GET"
  [string] $HttpEndpoint       = ""
  [string] $HttpQueryString    = ""

  [string] $ApiURL             = "https://api.twitter.com/1.1/statuses/home_timeline.json?include_entities=true&count=$($connections.Twitter.DefaultResultsToReturn)"

  if ( $ApiURL.IndexOf("?") -ne -1 ) {
    $HttpEndpoint              = $ApiURL.Split("?")[0]
    $HttpQueryString           = $ApiURL.Split("?")[1]
  } else {
    $HttpEndpoint              = $ApiURL
    $HttpQueryString           = ""
  }

  $OAuthConsumerKey            = $connections.Twitter.ConsumerKey
  $OAuthConsumerSecret         = $connections.Twitter.ConsumerSecret
  $OAuthToken                  = $connections.Twitter.AccessToken
  $OAuthTokenSecret            = $connections.Twitter.AccessTokenSecret

  $OAuthNonce                  = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes([System.DateTime]::Now.Ticks.ToString()))
  $TimeStamp                   = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact("01/01/1970", "dd/MM/yyyy", $null).ToUniversalTime()
  $OAuthTimeStamp              = [System.Convert]::ToInt64($TimeStamp.TotalSeconds).ToString()

  $OAuthSignature              = Set-OAuthSignature $HttpRequestType $HttpEndpoint $HttpQueryString $OAuthNonce $OAuthTimeStamp $OAuthConsumerKey $OAuthConsumerSecret $OAuthToken $OAuthTokenSecret
  $OAuthHeader                 = Set-OAuthHeader    $OAuthConsumerKey $OAuthNonce $OAuthSignature $OAuthTimeStamp $OAuthToken

  try {
    $ApiResponse = & $BinDir\curl.exe -s -k -X GET -H "Accept: application/x-www-form-urlencoded" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: $OAuthHeader" --user-agent $DefaultUserAgent $ApiURL

    Write-Debug "[Get-RawTwitterTimeLineAsJson] - ApiURL:        $ApiURL"
    Write-Debug "[Get-RawTwitterTimeLineAsJson] -   OAuthHeader: $OAuthHeader"

    if ( ( $ApiResponse -ilike "*errors*" ) -and ( $ApiResponse -ilike "*message*" ) -and ( $ApiResponse -ilike "*code*" ) ) {
      "$(get-date -format u) [Get-RawTwitterTimeLineAsJson] - Unable to retrieve tweets."  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterTimeLineAsJson] -   ApiURL:      $ApiURL"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterTimeLineAsJson] -   OAuthHeader: $OAuthHeader" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterTimeLineAsJson] -   ApiResponse: $ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawTwitterTimeLineAsJson] -   Unable to retrieve tweets."
      Write-Debug "[Get-RawTwitterTimeLineAsJson] -     ApiResponse: $ApiResponse"

      $ApiResponse = "Exception"
    }

    $ApiResponse
  } catch {
    "$(get-date -format u) [Get-RawTwitterTimeLineAsJson] - Unable to retrieve tweets."  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterTimeLineAsJson] -   ApiURL:      $ApiURL"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterTimeLineAsJson] -   OAuthHeader: $OAuthHeader" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterTimeLineAsJson] -   ApiResponse: $ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawTwitterTimeLineAsJson] - Unable to retrieve tweets."
    Write-Debug "[Get-RawTwitterTimeLineAsJson] -   ApiURL:      $ApiURL"
    Write-Debug "[Get-RawTwitterTimeLineAsJson] -   OAuthHeader: $OAuthHeader"
    Write-Debug "[Get-RawTwitterTimeLineAsJson] -   ApiResponse: $ApiResponse"

    $_.Exception.Message
  }
}


function Get-RawTwitterSearchAsJson( [string] $query, [int] $ResultsPerPage = $connections.Twitter.DefaultResultsToReturn, [string] $Language = "", [string] $ResultType = "", [string] $StartDate = "", [string] $GeoCode = "", [int64] $SinceId = 0, [int64] $MaxId = 0 ) {
  <#
    .SYNOPSIS
      Returns a collection of relevant Tweets matching a specified query.

    .DESCRIPTION
      Returns a collection of relevant Tweets matching a specified query.

      Please note that Twitter's search service and, by extension, the Search API is not meant to be an exhaustive source of Tweets. Not all Tweets will be indexed or made available via the search interface.

      In API v1.1, the response format of the Search API has been improved to return Tweet objects more similar to the objects you'll find across the REST API and platform. You may need to tolerate some inconsistencies and variance in perspectival values (fields that pertain to the perspective of the authenticating user) and embedded user objects.

    .EXAMPLE
      Get-RawTwitterSearchAsJson cveira | ConvertFrom-Json

    .NOTES
      Low-level function (API).

    .LINK
      https://dev.twitter.com/docs/api/1.1/get/search/tweets
      https://dev.twitter.com/docs/using-search
      https://dev.twitter.com/docs/working-with-timelines
  #>


  $LogFileName                 = "TwitterModule"

  [string] $HttpRequestType    = "GET"
  [string] $HttpEndpoint       = ""
  [string] $HttpQueryString    = ""

  [string] $SearchParameters   = "include_entities=true"

  if ( $ResultType -eq "" ) {
    $SearchParameters += "&result_type=mixed"
  } else {
    switch ( $ResultType ) {
      "mixed"   { $SearchParameters += "&result_type=mixed"   }
      "recent"  { $SearchParameters += "&result_type=recent"  }
      "popular" { $SearchParameters += "&result_type=popular" }
      default   { $SearchParameters += "&result_type=mixed"   }
    }
  }

  if ( ( $StartDate -ne "" ) -and ( $StartDate -match "\d{4}-\d{2}-\d{2}" ) ) {
    $SearchParameters += "&until=" + $StartDate
  }

  if ( ( $GeoCode -ne "" ) -and ( $GeoCode -match "(\-*[\d\.]+),(\-*[\d\.]+),(\d+)(km|mi)" ) ) {
    $SearchParameters += "&geocode=" + $GeoCode
  }

  if ( $SinceId -ne 0 ) {
    $SearchParameters += "&since_id=" + $SinceId
  }

  if ( $MaxId -ne 0 ) {
    $SearchParameters += "&max_id=" + $MaxId
  }

  $SearchParameters   += "&count=" + $ResultsPerPage + "&q="

  [string] $ApiURL     = "https://api.twitter.com/1.1/search/tweets.json?" + $SearchParameters + [System.Uri]::EscapeDataString($query.Trim())

  if ( $ApiURL.IndexOf("?") -ne -1 ) {
    $HttpEndpoint      = $ApiURL.Split("?")[0]
    $HttpQueryString   = $ApiURL.Split("?")[1]
  } else {
    $HttpEndpoint      = $ApiURL
    $HttpQueryString   = ""
  }

  $OAuthConsumerKey            = $connections.Twitter.ConsumerKey
  $OAuthConsumerSecret         = $connections.Twitter.ConsumerSecret
  $OAuthToken                  = $connections.Twitter.AccessToken
  $OAuthTokenSecret            = $connections.Twitter.AccessTokenSecret

  $OAuthNonce                  = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes([System.DateTime]::Now.Ticks.ToString()))
  $TimeStamp                   = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact("01/01/1970", "dd/MM/yyyy", $null).ToUniversalTime()
  $OAuthTimeStamp              = [System.Convert]::ToInt64($TimeStamp.TotalSeconds).ToString()

  $OAuthSignature              = Set-OAuthSignature $HttpRequestType $HttpEndpoint $HttpQueryString $OAuthNonce $OAuthTimeStamp $OAuthConsumerKey $OAuthConsumerSecret $OAuthToken $OAuthTokenSecret
  $OAuthHeader                 = Set-OAuthHeader    $OAuthConsumerKey $OAuthNonce $OAuthSignature $OAuthTimeStamp $OAuthToken

  try {
    $ApiResponse = & $BinDir\curl.exe -s -k -X GET -H "Accept: application/x-www-form-urlencoded" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: $OAuthHeader" --user-agent $DefaultUserAgent $ApiURL

    Write-Debug "[Get-RawTwitterSearchAsJson] - ApiURL:        $ApiURL"
    Write-Debug "[Get-RawTwitterSearchAsJson] -   OAuthHeader: $OAuthHeader"

    if ( ( $ApiResponse -ilike "*errors*" ) -and ( $ApiResponse -ilike "*message*" ) -and ( $ApiResponse -ilike "*code*" ) ) {
      "$(get-date -format u) [Get-RawTwitterSearchAsJson] - Unable to retrieve tweets."  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterSearchAsJson] -   ApiURL:      $ApiURL"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterSearchAsJson] -   OAuthHeader: $OAuthHeader" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterSearchAsJson] -   ApiResponse: $ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawTwitterSearchAsJson] -   Unable to retrieve tweets."
      Write-Debug "[Get-RawTwitterSearchAsJson] -     ApiResponse: $ApiResponse"

      $ApiResponse = "Exception"
    }

    $ApiResponse
  } catch {
    "$(get-date -format u) [Get-RawTwitterSearchAsJson] - Unable to retrieve tweets."  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterSearchAsJson] -   ApiURL:      $ApiURL"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterSearchAsJson] -   OAuthHeader: $OAuthHeader" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterSearchAsJson] -   ApiResponse: $ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawTwitterSearchAsJson] - Unable to retrieve tweets."
    Write-Debug "[Get-RawTwitterSearchAsJson] -   ApiURL:      $ApiURL"
    Write-Debug "[Get-RawTwitterSearchAsJson] -   OAuthHeader: $OAuthHeader"
    Write-Debug "[Get-RawTwitterSearchAsJson] -   ApiResponse: $ApiResponse"

    $_.Exception.Message
  }
}


function Send-RawTweet ( [string] $message ) {
  <#
    .SYNOPSIS
      Updates the authenticating user's current status, also known as tweeting.

    .DESCRIPTION
      Updates the authenticating user's current status, also known as tweeting.

      For each update attempt, the update text is compared with the authenticating user's recent tweets. Any attempt that would result in duplication will be blocked, resulting in a 403 error. Therefore, a user cannot submit the same status twice in a row.

      While not rate limited by the API a user is limited in the number of tweets they can create at a time. If the number of updates posted by the user reaches the current allowed limit this method will return an HTTP 403 error.

    .EXAMPLE
      Send-RawTweet "This is my first Tweet from #PowerShell using, raw #DotNet and #OAuth!"

    .NOTES
      Low-level function (API).

    .LINK
      https://dev.twitter.com/docs/api/1.1/post/statuses/update
  #>


  $LogFileName                 = "TwitterModule"

  [string] $HttpRequestType    = "POST"
  [string] $HttpEndpoint       = ""
  [string] $HttpQueryString    = ""

  [string] $ApiURL             = "https://api.twitter.com/1.1/statuses/update.json"


  if ( $TweetMessage.Length -gt 140 ) {
    $TweetMessage              = $TweetMessage.Substring(0,140)
  }

  # Body POST Data format is NOT documented!
  # look at how the supplied example looks like @ https://dev.twitter.com/docs/api/1.1/post/statuses/update
  # [byte[]] $HttpPostBody       = [System.Text.Encoding]::UTF8.GetBytes( "status=" + ( EscapeDataStringRfc3986 ($message) ) )
  $HttpPostBody                = "status=" + "$( EscapeDataStringRfc3986 $message )"
  $HttpEndpoint                = $ApiURL

  # The 'status' parameter gets encoded TWICE in the OAuth signature. This detail is NOT documented!
  # Run an example with the OAuth Tool and look at the results for the OAuth signature.
  # [System.Uri]::EscapeDataString() is not RFC3986 compliant in .NET < 4.x!
  # RFC3986 compliancy is documented in OAuth 1.0A, not in Twitter documentation!
  $HttpQueryString             = "status=" + (EscapeDataStringRfc3986 $message)

  $OAuthConsumerKey            = $connections.Twitter.ConsumerKey
  $OAuthConsumerSecret         = $connections.Twitter.ConsumerSecret
  $OAuthToken                  = $connections.Twitter.AccessToken
  $OAuthTokenSecret            = $connections.Twitter.AccessTokenSecret

  $OAuthNonce                  = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes([System.DateTime]::Now.Ticks.ToString()))
  $TimeStamp                   = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact("01/01/1970", "dd/MM/yyyy", $null).ToUniversalTime()
  $OAuthTimeStamp              = [System.Convert]::ToInt64($TimeStamp.TotalSeconds).ToString()

  $OAuthSignature              = Set-OAuthSignature $HttpRequestType $HttpEndpoint $HttpQueryString $OAuthNonce $OAuthTimeStamp $OAuthConsumerKey $OAuthConsumerSecret $OAuthToken $OAuthTokenSecret
  $OAuthHeader                 = Set-OAuthHeader    $OAuthConsumerKey $OAuthNonce $OAuthSignature $OAuthTimeStamp $OAuthToken

  try {
    $ApiResponse = & $BinDir\curl.exe -s -k -X POST --data $HttpPostBody -H "Accept: application/x-www-form-urlencoded" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: $OAuthHeader" --user-agent $DefaultUserAgent $ApiURL

    Write-Debug "[Send-RawTweet - ApiURL:        $ApiURL"
    Write-Debug "[Send-RawTweet] -   OAuthHeader: $OAuthHeader"

    if ( ( $ApiResponse -ilike "*errors*" ) -and ( $ApiResponse -ilike "*message*" ) -and ( $ApiResponse -ilike "*code*" ) ) {
      "$(get-date -format u) [Send-RawTweet] - Unable to send tweet."       >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Send-RawTweet] -   ApiURL:      $ApiURL"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Send-RawTweet] -   OAuthHeader: $OAuthHeader" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Send-RawTweet] -   ApiResponse: $ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Send-RawTweet] -   Unable to send tweet."
      Write-Debug "[Send-RawTweet] -     ApiResponse: $ApiResponse"

      $ApiResponse = "Exception"
    }

    $ApiResponse | ConvertFrom-JSON
  } catch {
    "$(get-date -format u) [Send-RawTweet] - Unable to send tweet."       >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Send-RawTweet] -   ApiURL:      $ApiURL"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Send-RawTweet] -   OAuthHeader: $OAuthHeader" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Send-RawTweet] -   ApiResponse: $ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Send-RawTweet] - Unable to send tweet."
    Write-Debug "[Send-RawTweet] -   ApiURL:      $ApiURL"
    Write-Debug "[Send-RawTweet] -   OAuthHeader: $OAuthHeader"
    Write-Debug "[Send-RawTweet] -   ApiResponse: $ApiResponse"

    $_.Exception.Message
  }
}


function Get-RawTwitterListSubscribersAsJson( [string] $TweetPermaLink, [string] $PageId = "-1" ) {
  <#
    .SYNOPSIS
      Returns the subscribers of the specified list. Private list subscribers will only be shown if the authenticated user owns the specified list.

    .DESCRIPTION
      Returns the subscribers of the specified list. Private list subscribers will only be shown if the authenticated user owns the specified list.

    .EXAMPLE
      Get-RawTwitterListSubscribersAsJson https://twitter.com/cveira/cloud | ConvertFrom-Json

    .NOTES
      Low-level function (API).

    .LINK
      https://dev.twitter.com/docs/api/1.1/get/lists/subscribers
  #>


  $LogFileName                 = "TwitterModule"

  [string] $HttpRequestType    = "GET"
  [string] $HttpEndpoint       = ""
  [string] $HttpQueryString    = ""

  [string] $ApiURL             = "https://api.twitter.com/1.1/lists/subscribers.json?slug=" + $TweetPermaLink.Split("/")[4] + "&owner_screen_name=" + $TweetPermaLink.Split("/")[3] + "&include_entities=true&cursor=" + $PageId + "&skip_status=true"


  if ( $ApiURL.IndexOf("?") -ne -1 ) {
    $HttpEndpoint              = $ApiURL.Split("?")[0]
    $HttpQueryString           = $ApiURL.Split("?")[1]
  } else {
    $HttpEndpoint              = $ApiURL
    $HttpQueryString           = ""
  }

  $OAuthConsumerKey            = $connections.Twitter.ConsumerKey
  $OAuthConsumerSecret         = $connections.Twitter.ConsumerSecret
  $OAuthToken                  = $connections.Twitter.AccessToken
  $OAuthTokenSecret            = $connections.Twitter.AccessTokenSecret

  $OAuthNonce                  = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes([System.DateTime]::Now.Ticks.ToString()))
  $TimeStamp                   = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact("01/01/1970", "dd/MM/yyyy", $null).ToUniversalTime()
  $OAuthTimeStamp              = [System.Convert]::ToInt64($TimeStamp.TotalSeconds).ToString()

  $OAuthSignature              = Set-OAuthSignature $HttpRequestType $HttpEndpoint $HttpQueryString $OAuthNonce $OAuthTimeStamp $OAuthConsumerKey $OAuthConsumerSecret $OAuthToken $OAuthTokenSecret
  $OAuthHeader                 = Set-OAuthHeader    $OAuthConsumerKey $OAuthNonce $OAuthSignature $OAuthTimeStamp $OAuthToken

  try {
    $ApiResponse = & $BinDir\curl.exe -s -k -X GET -H "Accept: application/x-www-form-urlencoded" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: $OAuthHeader" --user-agent $DefaultUserAgent $ApiURL

    Write-Debug "[Get-RawTwitterListSubscribersAsJson] - ApiURL:        $ApiURL"
    Write-Debug "[Get-RawTwitterListSubscribersAsJson] -   OAuthHeader: $OAuthHeader"

    if ( ( $ApiResponse -ilike "*errors*" ) -and ( $ApiResponse -ilike "*message*" ) -and ( $ApiResponse -ilike "*code*" ) ) {
      "$(get-date -format u) [Get-RawTwitterListSubscribersAsJson] - Unable to retrieve subscribers."  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterListSubscribersAsJson] -   ApiURL:      $ApiURL"           >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterListSubscribersAsJson] -   OAuthHeader: $OAuthHeader"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterListSubscribersAsJson] -   ApiResponse: $ApiResponse"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawTwitterListSubscribersAsJson] -   Unable to retrieve subscribers."
      Write-Debug "[Get-RawTwitterListSubscribersAsJson] -     ApiResponse: $ApiResponse"

      $ApiResponse = "Exception"
    }

    $ApiResponse
  } catch {
    "$(get-date -format u) [Get-RawTwitterListSubscribersAsJson] - Unable to retrieve subscribers." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterListSubscribersAsJson] -   ApiURL:      $ApiURL"          >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterListSubscribersAsJson] -   OAuthHeader: $OAuthHeader"     >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterListSubscribersAsJson] -   ApiResponse: $ApiResponse"     >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawTwitterListSubscribersAsJson] - Unable to retrieve subscribers."
    Write-Debug "[Get-RawTwitterListSubscribersAsJson] -   ApiURL:      $ApiURL"
    Write-Debug "[Get-RawTwitterListSubscribersAsJson] -   OAuthHeader: $OAuthHeader"
    Write-Debug "[Get-RawTwitterListSubscribersAsJson] -   ApiResponse: $ApiResponse"

    $_.Exception.Message
  }
}


function Get-RawTwitterListMembersAsJson( [string] $TweetPermaLink, [string] $PageId = "-1" ) {
  <#
    .SYNOPSIS
      Returns the members of the specified list. Private list members will only be shown if the authenticated user owns the specified list.

    .DESCRIPTION
      Returns the members of the specified list. Private list members will only be shown if the authenticated user owns the specified list.

    .EXAMPLE
      Get-RawTwitterListMembersAsJson https://twitter.com/cveira/cloud | ConvertFrom-Json

    .NOTES
      Low-level function (API).

    .LINK
      https://dev.twitter.com/docs/api/1.1/get/lists/members
  #>


  $LogFileName                 = "TwitterModule"

  [string] $HttpRequestType    = "GET"
  [string] $HttpEndpoint       = ""
  [string] $HttpQueryString    = ""

  [string] $ApiURL             = "https://api.twitter.com/1.1/lists/members.json?slug=" + $TweetPermaLink.Split("/")[4] + "&owner_screen_name=" + $TweetPermaLink.Split("/")[3] + "&include_entities=true&cursor=" + $PageId + "&skip_status=true"


  if ( $ApiURL.IndexOf("?") -ne -1 ) {
    $HttpEndpoint              = $ApiURL.Split("?")[0]
    $HttpQueryString           = $ApiURL.Split("?")[1]
  } else {
    $HttpEndpoint              = $ApiURL
    $HttpQueryString           = ""
  }

  $OAuthConsumerKey            = $connections.Twitter.ConsumerKey
  $OAuthConsumerSecret         = $connections.Twitter.ConsumerSecret
  $OAuthToken                  = $connections.Twitter.AccessToken
  $OAuthTokenSecret            = $connections.Twitter.AccessTokenSecret

  $OAuthNonce                  = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes([System.DateTime]::Now.Ticks.ToString()))
  $TimeStamp                   = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact("01/01/1970", "dd/MM/yyyy", $null).ToUniversalTime()
  $OAuthTimeStamp              = [System.Convert]::ToInt64($TimeStamp.TotalSeconds).ToString()

  $OAuthSignature              = Set-OAuthSignature $HttpRequestType $HttpEndpoint $HttpQueryString $OAuthNonce $OAuthTimeStamp $OAuthConsumerKey $OAuthConsumerSecret $OAuthToken $OAuthTokenSecret
  $OAuthHeader                 = Set-OAuthHeader    $OAuthConsumerKey $OAuthNonce $OAuthSignature $OAuthTimeStamp $OAuthToken

  try {
    $ApiResponse = & $BinDir\curl.exe -s -k -X GET -H "Accept: application/x-www-form-urlencoded" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: $OAuthHeader" --user-agent $DefaultUserAgent $ApiURL

    Write-Debug "[Get-RawTwitterListMembersAsJson] - ApiURL:        $ApiURL"
    Write-Debug "[Get-RawTwitterListMembersAsJson] -   OAuthHeader: $OAuthHeader"

    if ( ( $ApiResponse -ilike "*errors*" ) -and ( $ApiResponse -ilike "*message*" ) -and ( $ApiResponse -ilike "*code*" ) ) {
      "$(get-date -format u) [Get-RawTwitterListMembersAsJson] - Unable to retrieve members." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterListMembersAsJson] -   ApiURL:      $ApiURL"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterListMembersAsJson] -   OAuthHeader: $OAuthHeader" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterListMembersAsJson] -   ApiResponse: $ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawTwitterListMembersAsJson] -   Unable to retrieve members."
      Write-Debug "[Get-RawTwitterListMembersAsJson] -     ApiResponse: $ApiResponse"

      $ApiResponse = "Exception"
    }

    $ApiResponse
  } catch {
    "$(get-date -format u) [Get-RawTwitterListMembersAsJson] - Unable to retrieve members." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterListMembersAsJson] -   ApiURL:      $ApiURL"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterListMembersAsJson] -   OAuthHeader: $OAuthHeader" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterListMembersAsJson] -   ApiResponse: $ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawTwitterListMembersAsJson] - Unable to retrieve members."
    Write-Debug "[Get-RawTwitterListMembersAsJson] -   ApiURL:      $ApiURL"
    Write-Debug "[Get-RawTwitterListMembersAsJson] -   OAuthHeader: $OAuthHeader"
    Write-Debug "[Get-RawTwitterListMembersAsJson] -   ApiResponse: $ApiResponse"

    $_.Exception.Message
  }
}


function Get-RawTwitterListTimeLineAsJson( [string] $TweetPermaLink, [int] $ResultsPerPage = $connections.Twitter.DefaultResultsToReturn ) {
  <#
    .SYNOPSIS
      Returns a timeline of tweets authored by members of the specified list.

    .DESCRIPTION
      Returns a timeline of tweets authored by members of the specified list.

    .EXAMPLE
      Get-RawTwitterListTimeLineAsJson https://twitter.com/cveira/cloud | ConvertFrom-Json

    .NOTES
      Low-level function (API).

    .LINK
      https://dev.twitter.com/docs/api/1.1/get/lists/statuses
  #>


  $LogFileName                 = "TwitterModule"

  [string] $HttpRequestType    = "GET"
  [string] $HttpEndpoint       = ""
  [string] $HttpQueryString    = ""

  [string] $ApiURL             = "https://api.twitter.com/1.1/lists/statuses.json?slug=" + $TweetPermaLink.Split("/")[4] + "&owner_screen_name=" + $TweetPermaLink.Split("/")[3] + "&count=" + $ResultsPerPage + "&include_entities=true&include_rts=true"


  if ( $ApiURL.IndexOf("?") -ne -1 ) {
    $HttpEndpoint              = $ApiURL.Split("?")[0]
    $HttpQueryString           = $ApiURL.Split("?")[1]
  } else {
    $HttpEndpoint              = $ApiURL
    $HttpQueryString           = ""
  }

  $OAuthConsumerKey            = $connections.Twitter.ConsumerKey
  $OAuthConsumerSecret         = $connections.Twitter.ConsumerSecret
  $OAuthToken                  = $connections.Twitter.AccessToken
  $OAuthTokenSecret            = $connections.Twitter.AccessTokenSecret

  $OAuthNonce                  = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes([System.DateTime]::Now.Ticks.ToString()))
  $TimeStamp                   = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact("01/01/1970", "dd/MM/yyyy", $null).ToUniversalTime()
  $OAuthTimeStamp              = [System.Convert]::ToInt64($TimeStamp.TotalSeconds).ToString()

  $OAuthSignature              = Set-OAuthSignature $HttpRequestType $HttpEndpoint $HttpQueryString $OAuthNonce $OAuthTimeStamp $OAuthConsumerKey $OAuthConsumerSecret $OAuthToken $OAuthTokenSecret
  $OAuthHeader                 = Set-OAuthHeader    $OAuthConsumerKey $OAuthNonce $OAuthSignature $OAuthTimeStamp $OAuthToken

  try {
    $ApiResponse = & $BinDir\curl.exe -s -k -X GET -H "Accept: application/x-www-form-urlencoded" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: $OAuthHeader" --user-agent $DefaultUserAgent $ApiURL

    Write-Debug "[Get-RawTwitterListTimeLineAsJson] - ApiURL:        $ApiURL"
    Write-Debug "[Get-RawTwitterListTimeLineAsJson] -   OAuthHeader: $OAuthHeader"

    if ( ( $ApiResponse -ilike "*errors*" ) -and ( $ApiResponse -ilike "*message*" ) -and ( $ApiResponse -ilike "*code*" ) ) {
      "$(get-date -format u) [Get-RawTwitterListTimeLineAsJson] - Unable to retrieve tweets."  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterListTimeLineAsJson] -   ApiURL:      $ApiURL"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterListTimeLineAsJson] -   OAuthHeader: $OAuthHeader" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterListTimeLineAsJson] -   ApiResponse: $ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawTwitterListTimeLineAsJson] -   Unable to retrieve tweets."
      Write-Debug "[Get-RawTwitterListTimeLineAsJson] -     ApiResponse: $ApiResponse"

      $ApiResponse = "Exception"
    }

    $ApiResponse
  } catch {
    "$(get-date -format u) [Get-RawTwitterListTimeLineAsJson] - Unable to retrieve tweets."  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterListTimeLineAsJson] -   ApiURL:      $ApiURL"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterListTimeLineAsJson] -   OAuthHeader: $OAuthHeader" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterListTimeLineAsJson] -   ApiResponse: $ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawTwitterListTimeLineAsJson] - Unable to retrieve tweets."
    Write-Debug "[Get-RawTwitterListTimeLineAsJson] -   ApiURL:      $ApiURL"
    Write-Debug "[Get-RawTwitterListTimeLineAsJson] -   OAuthHeader: $OAuthHeader"
    Write-Debug "[Get-RawTwitterListTimeLineAsJson] -   ApiResponse: $ApiResponse"

    $_.Exception.Message
  }
}


function Get-RawTwitterUserFriendsFromUserAsJson( [string] $name, [string] $PageId = "-1" ) {
  <#
    .SYNOPSIS
      Returns a cursored collection of user objects for every user the specified user is following (otherwise known as their "friends").

    .DESCRIPTION
      Returns a cursored collection of user objects for every user the specified user is following (otherwise known as their "friends").

      At this time, results are ordered with the most recent following first — however, this ordering is subject to unannounced change and eventual consistency issues. Results are given in groups of 20 users and multiple "pages" of results can be navigated through using the next_cursor value in subsequent requests.

    .EXAMPLE
      Get-RawTwitterUserFriendsFromUserAsJson cveira | ConvertFrom-Json

    .NOTES
      Low-level function (API).

    .LINK
      https://dev.twitter.com/docs/api/1.1/get/friends/list
  #>


  $LogFileName                 = "TwitterModule"

  [string] $HttpRequestType    = "GET"
  [string] $HttpEndpoint       = ""
  [string] $HttpQueryString    = ""

  [string] $ApiURL             = "https://api.twitter.com/1.1/friends/list.json?screen_name=" + $name.Trim() + "&include_entities=true&cursor=" + $PageId + "&skip_status=true"


  if ( $ApiURL.IndexOf("?") -ne -1 ) {
    $HttpEndpoint              = $ApiURL.Split("?")[0]
    $HttpQueryString           = $ApiURL.Split("?")[1]
  } else {
    $HttpEndpoint              = $ApiURL
    $HttpQueryString           = ""
  }

  $OAuthConsumerKey            = $connections.Twitter.ConsumerKey
  $OAuthConsumerSecret         = $connections.Twitter.ConsumerSecret
  $OAuthToken                  = $connections.Twitter.AccessToken
  $OAuthTokenSecret            = $connections.Twitter.AccessTokenSecret

  $OAuthNonce                  = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes([System.DateTime]::Now.Ticks.ToString()))
  $TimeStamp                   = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact("01/01/1970", "dd/MM/yyyy", $null).ToUniversalTime()
  $OAuthTimeStamp              = [System.Convert]::ToInt64($TimeStamp.TotalSeconds).ToString()

  $OAuthSignature              = Set-OAuthSignature $HttpRequestType $HttpEndpoint $HttpQueryString $OAuthNonce $OAuthTimeStamp $OAuthConsumerKey $OAuthConsumerSecret $OAuthToken $OAuthTokenSecret
  $OAuthHeader                 = Set-OAuthHeader    $OAuthConsumerKey $OAuthNonce $OAuthSignature $OAuthTimeStamp $OAuthToken

  try {
    $ApiResponse = & $BinDir\curl.exe -s -k -X GET -H "Accept: application/x-www-form-urlencoded" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: $OAuthHeader" --user-agent $DefaultUserAgent $ApiURL

    Write-Debug "[Get-RawTwitterUserFriendsFromUserAsJson] - ApiURL:        $ApiURL"
    Write-Debug "[Get-RawTwitterUserFriendsFromUserAsJson] -   OAuthHeader: $OAuthHeader"

    if ( ( $ApiResponse -ilike "*errors*" ) -and ( $ApiResponse -ilike "*message*" ) -and ( $ApiResponse -ilike "*code*" ) ) {
      "$(get-date -format u) [Get-RawTwitterUserFriendsFromUserAsJson] - Unable to retrieve friends." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterUserFriendsFromUserAsJson] -   ApiURL:      $ApiURL"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterUserFriendsFromUserAsJson] -   OAuthHeader: $OAuthHeader" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterUserFriendsFromUserAsJson] -   ApiResponse: $ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawTwitterUserFriendsFromUserAsJson] -   Unable to retrieve friends."
      Write-Debug "[Get-RawTwitterUserFriendsFromUserAsJson] -     ApiResponse: $ApiResponse"

      $ApiResponse = "Exception"
    }

    $ApiResponse
  } catch {
    "$(get-date -format u) [Get-RawTwitterUserFriendsFromUserAsJson] - Unable to retrieve friends." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterUserFriendsFromUserAsJson] -   ApiURL:      $ApiURL"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterUserFriendsFromUserAsJson] -   OAuthHeader: $OAuthHeader" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterUserFriendsFromUserAsJson] -   ApiResponse: $ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawTwitterUserFriendsFromUserAsJson] - Unable to retrieve friends."
    Write-Debug "[Get-RawTwitterUserFriendsFromUserAsJson] -   ApiURL:      $ApiURL"
    Write-Debug "[Get-RawTwitterUserFriendsFromUserAsJson] -   OAuthHeader: $OAuthHeader"
    Write-Debug "[Get-RawTwitterUserFriendsFromUserAsJson] -   ApiResponse: $ApiResponse"

    $_.Exception.Message
  }
}


function Get-RawTwitterFollowersFromUserAsJson( [string] $name, [string] $PageId = "-1" ) {
  <#
    .SYNOPSIS
      Returns a cursored collection of user objects for users following the specified user.

    .DESCRIPTION
      Returns a cursored collection of user objects for users following the specified user.

      At this time, results are ordered with the most recent following first — however, this ordering is subject to unannounced change and eventual consistency issues. Results are given in groups of 20 users and multiple "pages" of results can be navigated through using the next_cursor value in subsequent requests.

    .EXAMPLE
      Get-RawTwitterFollowersFromUserAsJson cveira | ConvertFrom-Json

    .NOTES
      Low-level function (API).

    .LINK
      https://dev.twitter.com/docs/api/1.1/get/followers/list
  #>


  $LogFileName                 = "TwitterModule"

  [string] $HttpRequestType    = "GET"
  [string] $HttpEndpoint       = ""
  [string] $HttpQueryString    = ""

  [string] $ApiURL             = "https://api.twitter.com/1.1/followers/list.json?screen_name=" + $name.Trim() + "&include_entities=true&cursor=" + $PageId + "&skip_status=true"


  if ( $ApiURL.IndexOf("?") -ne -1 ) {
    $HttpEndpoint              = $ApiURL.Split("?")[0]
    $HttpQueryString           = $ApiURL.Split("?")[1]
  } else {
    $HttpEndpoint              = $ApiURL
    $HttpQueryString           = ""
  }

  $OAuthConsumerKey            = $connections.Twitter.ConsumerKey
  $OAuthConsumerSecret         = $connections.Twitter.ConsumerSecret
  $OAuthToken                  = $connections.Twitter.AccessToken
  $OAuthTokenSecret            = $connections.Twitter.AccessTokenSecret

  $OAuthNonce                  = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes([System.DateTime]::Now.Ticks.ToString()))
  $TimeStamp                   = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact("01/01/1970", "dd/MM/yyyy", $null).ToUniversalTime()
  $OAuthTimeStamp              = [System.Convert]::ToInt64($TimeStamp.TotalSeconds).ToString()

  $OAuthSignature              = Set-OAuthSignature $HttpRequestType $HttpEndpoint $HttpQueryString $OAuthNonce $OAuthTimeStamp $OAuthConsumerKey $OAuthConsumerSecret $OAuthToken $OAuthTokenSecret
  $OAuthHeader                 = Set-OAuthHeader    $OAuthConsumerKey $OAuthNonce $OAuthSignature $OAuthTimeStamp $OAuthToken

  try {
    $ApiResponse = & $BinDir\curl.exe -s -k -X GET -H "Accept: application/x-www-form-urlencoded" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: $OAuthHeader" --user-agent $DefaultUserAgent $ApiURL

    Write-Debug "[Get-RawTwitterFollowersFromUserAsJson] - ApiURL:        $ApiURL"
    Write-Debug "[Get-RawTwitterFollowersFromUserAsJson] -   OAuthHeader: $OAuthHeader"

    if ( ( $ApiResponse -ilike "*errors*" ) -and ( $ApiResponse -ilike "*message*" ) -and ( $ApiResponse -ilike "*code*" ) ) {
      "$(get-date -format u) [Get-RawTwitterFollowersFromUserAsJson] - Unable to retrieve followers."  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterFollowersFromUserAsJson] -   ApiURL:      $ApiURL"         >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterFollowersFromUserAsJson] -   OAuthHeader: $OAuthHeader"    >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterFollowersFromUserAsJson] -   ApiResponse: $ApiResponse"    >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawTwitterFollowersFromUserAsJson] -   Unable to retrieve followers."
      Write-Debug "[Get-RawTwitterFollowersFromUserAsJson] -     ApiResponse: $ApiResponse"

      $ApiResponse = "Exception"
    }

    $ApiResponse
  } catch {
    "$(get-date -format u) [Get-RawTwitterFollowersFromUserAsJson] - Unable to retrieve followers." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterFollowersFromUserAsJson] -   ApiURL:      $ApiURL"        >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterFollowersFromUserAsJson] -   OAuthHeader: $OAuthHeader"   >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterFollowersFromUserAsJson] -   ApiResponse: $ApiResponse"   >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawTwitterFollowersFromUserAsJson] - Unable to retrieve followers."
    Write-Debug "[Get-RawTwitterFollowersFromUserAsJson] -   ApiURL:      $ApiURL"
    Write-Debug "[Get-RawTwitterFollowersFromUserAsJson] -   OAuthHeader: $OAuthHeader"
    Write-Debug "[Get-RawTwitterFollowersFromUserAsJson] -   ApiResponse: $ApiResponse"

    $_.Exception.Message
  }
}


function Get-RawTwitterUserAsJson( [string] $name ) {
  <#
    .SYNOPSIS
      Returns a variety of information about the user specified by the required user_id or Name parameter. The author's most recent Tweet will be returned inline when possible.

    .DESCRIPTION
      Returns a variety of information about the user specified by the required user_id or Name parameter. The author's most recent Tweet will be returned inline when possible.

    .EXAMPLE
      Get-RawTwitterUserAsJson cveira | ConvertFrom-Json

    .NOTES
      Low-level function (API).

    .LINK
      https://dev.twitter.com/docs/api/1.1/get/users/show
  #>


  $LogFileName                 = "TwitterModule"

  [string] $HttpRequestType    = "GET"
  [string] $HttpEndpoint       = ""
  [string] $HttpQueryString    = ""

  [string] $ApiURL             = "https://api.twitter.com/1.1/users/show.json?screen_name=" + $name.Trim() + "&include_entities=true"


  if ( $ApiURL.IndexOf("?") -ne -1 ) {
    $HttpEndpoint              = $ApiURL.Split("?")[0]
    $HttpQueryString           = $ApiURL.Split("?")[1]
  } else {
    $HttpEndpoint              = $ApiURL
    $HttpQueryString           = ""
  }

  $OAuthConsumerKey            = $connections.Twitter.ConsumerKey
  $OAuthConsumerSecret         = $connections.Twitter.ConsumerSecret
  $OAuthToken                  = $connections.Twitter.AccessToken
  $OAuthTokenSecret            = $connections.Twitter.AccessTokenSecret

  $OAuthNonce                  = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes([System.DateTime]::Now.Ticks.ToString()))
  $TimeStamp                   = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact("01/01/1970", "dd/MM/yyyy", $null).ToUniversalTime()
  $OAuthTimeStamp              = [System.Convert]::ToInt64($TimeStamp.TotalSeconds).ToString()

  $OAuthSignature              = Set-OAuthSignature $HttpRequestType $HttpEndpoint $HttpQueryString $OAuthNonce $OAuthTimeStamp $OAuthConsumerKey $OAuthConsumerSecret $OAuthToken $OAuthTokenSecret
  $OAuthHeader                 = Set-OAuthHeader    $OAuthConsumerKey $OAuthNonce $OAuthSignature $OAuthTimeStamp $OAuthToken

  try {
    $ApiResponse = & $BinDir\curl.exe -s -k -X GET -H "Accept: application/x-www-form-urlencoded" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: $OAuthHeader" --user-agent $DefaultUserAgent $ApiURL

    Write-Debug "[Get-RawTwitterUserAsJson] - ApiURL:        $ApiURL"
    Write-Debug "[Get-RawTwitterUserAsJson] -   OAuthHeader: $OAuthHeader"

    if ( ( $ApiResponse -ilike "*errors*" ) -and ( $ApiResponse -ilike "*message*" ) -and ( $ApiResponse -ilike "*code*" ) ) {
      "$(get-date -format u) [Get-RawTwitterUserAsJson] - Unable to retrieve user."  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterUserAsJson] -   ApiURL:      $ApiURL"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterUserAsJson] -   OAuthHeader: $OAuthHeader" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Get-RawTwitterUserAsJson] -   ApiResponse: $ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Get-RawTwitterUserAsJson] -   Unable to retrieve user."
      Write-Debug "[Get-RawTwitterUserAsJson] -     ApiResponse: $ApiResponse"

      $ApiResponse = "Exception"
    }

    $ApiResponse
  } catch {
    "$(get-date -format u) [Get-RawTwitterUserAsJson] - Unable to retrieve user."    >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterUserAsJson] -   ApiURL:      $ApiURL"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterUserAsJson] -   OAuthHeader: $OAuthHeader" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Get-RawTwitterUserAsJson] -   ApiResponse: $ApiResponse" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Get-RawTwitterUserAsJson] - Unable to retrieve user."
    Write-Debug "[Get-RawTwitterUserAsJson] -   ApiURL:      $ApiURL"
    Write-Debug "[Get-RawTwitterUserAsJson] -   OAuthHeader: $OAuthHeader"
    Write-Debug "[Get-RawTwitterUserAsJson] -   ApiResponse: $ApiResponse"

    $_.Exception.Message
  }
}


function Get-RawUnpagedFollowerList( [object[]] $PagedFollowersList ) {
  <#
    .SYNOPSIS
      Unifies followers distributed on a collection of pages into a single follower list.

    .DESCRIPTION
      Unifies followers distributed on a collection of pages into a single follower list.

    .EXAMPLE
      $followers = Get-RawUnpagedFollowerList $PagedFollowersList

    .NOTES
      Low-level function (API).

    .LINK
      N/A
  #>


  $UnpagedFollowers = @()

  $PagedFollowersList | ForEach-Object { $UnpagedFollowers += $_.users }
  $UnpagedFollowers = $UnpagedFollowers | Select-Object * -unique

  $UnpagedFollowers
}


# --------------------------------------------------------------------------------------------------


function Get-TwUserProfileData( [string] $from ) {
  <#
    .SYNOPSIS
      Retrieves profile information about the specified user.

    .DESCRIPTION
      Retrieves profile information about the specified user.

    .EXAMPLE
      $UserProfile = Get-TwUserProfileData -from cveira

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  $LogFileName    = "TwitterModule"

  $TimeToWait     = $connections.Twitter.ApiDelayForProfiles
  $RawUserProfile = Get-RawTwitterUserAsJson $from

  if ( $RawUserProfile  -ilike "Exception*" ) {
    "$(get-date -format u) [Get-TwUserProfileData] - Unable to retrieve user profile: $from - $RawUserProfile" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    Write-Debug "[Get-TwUserProfileData] - Unable to retrieve user profile: $from"

    return $null
  }

  try {
    $RawUserProfile = $RawUserProfile | ConvertFrom-Json
  } catch {
    "$(get-date -format u) [Get-TwUserProfileData] - Unable to transform user profile data: $from - $RawUserProfile" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    Write-Debug "[Get-TwUserProfileData] - Unable to transform user profile data: $from"

    return $null
  }

  Start-Sleep -Seconds $TimeToWait

  $UserProfile      = $RawUserProfile | ConvertTo-TwNormalizedUserProfileData

  $UserProfile
}


function Get-TwFollowers( [string] $from ) {
  <#
    .SYNOPSIS
      Retrieves the complete list of followers for the specified user.

    .DESCRIPTION
      Retrieves the complete list of followers for the specified user.

    .EXAMPLE
      $followers = Get-TwFollowers -from cveira

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  # $DebugPreference = "Continue"

  $LogFileName                    = "TwitterModule"

  [PSObject[]] $RawFollowersPages           = @()
  [System.Collections.ArrayList] $followers = @()
  $CurrentPage                              = $null
  $TimeToWait                               = $connections.Twitter.ApiDelayForFollowers
  $FollowersPerPage                         = 20
  $PageCount                                = 0

  $TotalFollowers                           = Get-RawTwitterUserAsJson $from

  if ( $TotalFollowers  -ilike "Exception*" ) {
    "$(get-date -format u) [Get-TwFollowers] - Unable to retrieve followers_count: $from - $TotalFollowers" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    Write-Debug "Unable to retrieve followers_count: $from"

    return $followers
  }

  try {
    $TotalFollowers       = ( $TotalFollowers | ConvertFrom-Json ).followers_count
  } catch {
    "$(get-date -format u) [Get-TwFollowers] - Unable to transform user profile data: $from - $TotalFollowers" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    Write-Debug "[Get-TwFollowers] - Unable to transform user profile data: $from"

    $TotalFollowers       = -1
  }

  try {
    $CurrentPage          = Get-RawTwitterFollowersFromUserAsJson $from

    if ( $CurrentPage  -ilike "Exception*" ) {
      "$(get-date -format u) [Get-TwFollowers] - Unable to retrieve followers: $from - $CurrentPage" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      Write-Debug "[Get-TwFollowers] - Unable to retrieve followers: $from"

      return $null
    }

    try {
      $CurrentPage        = $CurrentPage | ConvertFrom-Json
    } catch {
      "$(get-date -format u) [Get-TwFollowers] - Unable to transform followers: $from - $CurrentPage" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      Write-Debug "[Get-TwFollowers] - Unable to transform followers: $from"

      return $null
    }

    $RawFollowersPages   += $CurrentPage
    $PageCount            = 1

    $ExecutionTime        = [Diagnostics.Stopwatch]::StartNew()
    $ExecutionTime.Stop()

    while ( $CurrentPage.next_cursor -ne 0 ) {
      Write-Progress -Activity "Retrieving Followers ..." -Status "Progress: $($PageCount * $FollowersPerPage) / $TotalFollowers - ETC: $( '{0:#0.00}' -f $( ( ( $TotalFollowers - $($PageCount * $FollowersPerPage) ) / $FollowersPerPage ) * $ExecutionTime.Elapsed.TotalMinutes) ) minutes - Time Elapsed: $( '{0:#0.00}' -f $( $PageCount *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes" -PercentComplete ( (($PageCount * $FollowersPerPage) / $TotalFollowers) * 100 )

      Write-Debug "[INFO] PageCount:           $PageCount"
      Write-Debug "[INFO] TotalFollowers:      $TotalFollowers"
      Write-Debug "[INFO] ElapsedMinutes:      $($ExecutionTime.Elapsed.TotalMinutes)"

      $ExecutionTime      = [Diagnostics.Stopwatch]::StartNew()

      Start-Sleep -Seconds $TimeToWait

      $CurrentPage        = Get-RawTwitterFollowersFromUserAsJson $from -PageId $CurrentPage.next_cursor

      if ( $CurrentPage -ilike "Exception*" ) {
        "$(get-date -format u) [Get-TwFollowers] - Unable to retrieve followers: $from - $( $CurrentPage.next_cursor ) - $CurrentPage" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "Unable to retrieve followers: $from - $( $CurrentPage.next_cursor )"

        break
      } else {
        try {
          $CurrentPage      = $CurrentPage | ConvertFrom-Json
        } catch {
          "$(get-date -format u) [Get-TwFollowers] - Unable to transform followers: $from - $( $CurrentPage.next_cursor ) - $CurrentPage" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
          Write-Debug "Unable to transform followers: $from - $( $CurrentPage.next_cursor )"

          break
        }

        $RawFollowersPages += $CurrentPage
        $PageCount++
      }

      $ExecutionTime.Stop()
    }
  } catch {
    [PSCustomObject[]] $RawFollowersPages = @()
    $_.Exception.Message
  }

  $RawFollowers           = Get-RawUnpagedFollowerList $RawFollowersPages

  $i                      = 1
  $ExecutionTime          = [Diagnostics.Stopwatch]::StartNew()
  $ExecutionTime.Stop()

  foreach ( $user in $RawFollowers ) {
    Write-Progress -Activity "Normalizing Information ..." -Status "Progress: $i / $($RawFollowers.Count) - ETC: $( '{0:#0.00}' -f ( ( $($RawFollowers.Count) - $i ) * $ExecutionTime.Elapsed.TotalMinutes) ) minutes - Time Elapsed: $( '{0:#0.00}' -f (( $i - 1 ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes" -PercentComplete ( ( $i / $RawFollowers.Count ) * 100 )

    $ExecutionTime        = [Diagnostics.Stopwatch]::StartNew()

    $NormalizedUser       = $user | ConvertTo-TwNormalizedUserProfileData

    $followers.Add( $( $NormalizedUser | ConvertTo-JSON ) ) | Out-Null

    $ExecutionTime.Stop()

    $i++
  }

  # $DebugPreference = "SilentlyContinue"

  $followers | ForEach-Object { if ( $_ -ne $null ) { ConvertFrom-JSON $_ } }
}


function ConvertTo-TwNormalizedUserProfileData( [string] $schema = $SCHEMA_DEFAULT ) {
  <#
    .SYNOPSIS
      Normalizes user information by mapping Twitter API data structures into a normalized one. Additionally, it also gathers additional relevant information about that user.

    .DESCRIPTION
      Normalizes user information by mapping Twitter API data structures into a normalized one. Additionally, it also gathers additional relevant information about that user.

    .EXAMPLE
      $NormalizedUser  = $user  | ConvertTo-TwNormalizedUserProfileData
      $NormalizedUsers = $users | ConvertTo-TwNormalizedUserProfileData

    .NOTES
      High-level function. However, under normal circumstances, an end user shouldn't feel the need to use this function: other high-level functions use of it in order to make this details transparent to the end user.

    .LINK
      N/A
  #>


  begin {
    # $DebugPreference = "Continue"

    $LogFileName                           = "TwitterModule"
    $TimeToWait                            = $connections.Twitter.ApiDelayForProfiles
  }

  process {
    $user                                  = $_

    $NewUser                               = New-SMUser -schema $schema
    $NewUser.RetainUntilDate               = "{0:$DefaultDateFormat}" -f [datetime] ( ( [datetime] $NewUser.RetainUntilDate ).AddDays( $connections.Twitter.DataRetention ) )

    $NewUser.NormalizedUser.UserId         = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $user.screen_name } else { Get-SMPostDigest $user.screen_name }
    $NewUser.NormalizedUser.DisplayName    = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $user.name        } else { Get-SMPostDigest $user.name        }
    $NewUser.NormalizedUser.Description    = $user.description
    $NewUser.NormalizedUser.Language       = $user.lang
    $NewUser.NormalizedUser.Location       = $( if ( !$user.location ) { $user.time_zone } else { "$($user.time_zone) - $($user.location)" } )
    $NewUser.NormalizedUser.PermaLink      = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { "https://twitter.com/$($user.screen_name)"   } else { Get-SMPostDigest "https://twitter.com/$($user.screen_name)"   }
    $NewUser.NormalizedUser.ChannelName    = $CHANNEL_NAME_TWITTER
    $NewUser.NormalizedUser.ContactLinks   = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { ( $user.url | Expand-ShortLink ).ExpandedUrl } else { Get-SMPostDigest ( $user.url | Expand-ShortLink ).ExpandedUrl }
    $NewUser.NormalizedUser.PostsCount     = $user.statuses_count
    $NewUser.NormalizedUser.FollowersCount = $user.followers_count
    $NewUser.NormalizedUser.FollowingCount = $user.friends_count
    $NewUser.NormalizedUser.GroupsCount    = $user.listed_count
    $NewUser.NormalizedUser.PrivateProfile = $user.protected

    $NewUser.NormalizedUser.CreationDate   = "{0:$DefaultDateFormat}" -f [datetime] ( $user.created_at.Split("+")[1].Split(" ")[1] + " " + $user.created_at.Split("+")[0] )

    if ( $user.status -eq $null ) {
      $UserProfile                         = Get-RawTwitterUserAsJson $user.screen_name

      if ( $UserFromTwitter  -ilike "Exception*" ) {
        "$(get-date -format u) [ConvertTo-TwNormalizedUserProfileData] - Unable to retrieve user profile: $( $user.screen_name ) - $UserProfile" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "Unable to retrieve user profile: $( $user.screen_name )"

        $NewUser.NormalizedUser.LastPublishingDate   = "{0:$DefaultDateFormat}" -f [datetime] 0
      } else {
        try {
          $UserProfile                               = $UserProfile | ConvertFrom-Json
        } catch {
          "$(get-date -format u) [ConvertTo-TwNormalizedUserProfileData] - Unable to transform user profile data: $( $user.screen_name ) - $UserProfile" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
          Write-Debug "Unable to transform user profile data: $( $user.screen_name )"

          $NewUser.NormalizedUser.LastPublishingDate = "{0:$DefaultDateFormat}" -f [datetime] 0
        }

        Start-Sleep -Seconds $TimeToWait

        if ( $UserProfile.status -eq $null ) {
          $NewUser.NormalizedUser.LastPublishingDate = "{0:$DefaultDateFormat}" -f [datetime] 0
        } else {
          $NewUser.NormalizedUser.LastPublishingDate = "{0:$DefaultDateFormat}" -f [datetime] ( $UserProfile.status.created_at.Split("+")[1].Split(" ")[1] + " " + $UserProfile.status.created_at.Split("+")[0] )
        }
      }
    } else {
      $NewUser.NormalizedUser.LastPublishingDate     = "{0:$DefaultDateFormat}" -f [datetime] ( $user.status.created_at.Split("+")[1].Split(" ")[1] + " " + $user.status.created_at.Split("+")[0] )
    }

    $NewUser.RawObject                               = $user
  }

  end {
    # $DebugPreference = "SilentlyContinue"

    $NewUser
  }
}


function Update-TwUsersProfileData( [PSObject[]] $from ) {
  <#
    .SYNOPSIS
      Updates users profile data.

    .DESCRIPTION
      Updates users profile data. Unlike Update-TwUserProfileData, this function doesn't accept data from the pipeline. Howerver, it does provide feedback about the progress of the update process.

    .EXAMPLE
      $UpdatedTwitterFollowers = Update-TwUserProfileData -from $followers
      $UpdatedTwitterFollowers = Update-TwUserProfileData -from $NormalizedTwitterUsers
      $UpdatedTwitterProfiles  = Update-TwUserProfileData -from $ScreenNamesList

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  [System.Collections.ArrayList] $UpdatedUsers = @()

  $i               = 1
  $ExecutionTime   = [Diagnostics.Stopwatch]::StartNew()
  $ExecutionTime.Stop()

  foreach ( $user in $from ) {
    Write-Progress -Activity "Updating Users ..." -Status "Progress: $i / $($from.Count) - ETC: $( '{0:#0.00}' -f $( $($from.Count) - $i ) * $ExecutionTime.Elapsed.TotalMinutes ) minutes - Time Elapsed: $( '{0:#0.00}' -f $( $i *  $ExecutionTime.Elapsed.TotalMinutes ) ) minutes" -PercentComplete ( ( $i / $($from.Count) ) * 100 )

    Write-Debug "[INFO] CurrentUser:         $i"
    Write-Debug "[INFO] TotalUsers:          $($from.Count)"
    Write-Debug "[INFO] ElapsedMinutes:      $($ExecutionTime.Elapsed.TotalMinutes)"

    $ExecutionTime = [Diagnostics.Stopwatch]::StartNew()

    $UpdatedUsers.Add( $( $user | Update-TwUserProfileData | ConvertTo-JSON ) ) | Out-Null

    $ExecutionTime.Stop()

    $i++
  }

  $UpdatedUsers | ForEach-Object { if ( $_ -ne $null ) { ConvertFrom-JSON $_ } }
}


function Update-TwUserProfileData( [switch] $IncludeAll, [string] $schema = $SCHEMA_DEFAULT ) {
  <#
    .SYNOPSIS
      Updates users profile data.

    .DESCRIPTION
      Updates users profile data. Unlike Update-TwUserProfileData, this function accepts data from the pipeline. Howerver, it doesn't provide feedback about the progress of the update process.

    .EXAMPLE
      $UpdatedTwitterUser      = $NormalizedTwitterUser      | Update-TwUserProfileData
      $UpdatedTwitterFollowers = $NormalizedTwitterFollowers | Update-TwUserProfileData

      $UpdatedTwitterUser      = $ScreenName                 | Update-TwUserProfileData
      $UpdatedTwitterProfiles  = $ScreenNamesList            | Update-TwUserProfileData

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  begin {
    $LogFileName = "TwitterModule"
    $TimeToWait  = $connections.Twitter.ApiDelayForProfiles
  }

  process {
    $UpdatedUser = [PSCustomObject] @{}

    if ( $_ -is [string] ) {
      $user                            = New-SMUser -schema $schema
      $user.NormalizedUser.UserId      = $_
      $user.NormalizedUser.ChannelName = $CHANNEL_NAME_TWITTER
    } else {
      $user                            = $_
    }

    if ( $user.NormalizedUser.ChannelName -eq $CHANNEL_NAME_TWITTER ) {
      $UserFromTwitter           = Get-RawTwitterUserAsJson $user.NormalizedUser.UserId

      if ( $UserFromTwitter  -ilike "Exception*" ) {
        "$(get-date -format u) [Update-TwUserProfileData] - Unable to retrieve user: $( $user.NormalizedUser.UserId ) - $UserFromTwitter" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "[Update-TwUserProfileData] - Unable to retrieve user: $( $user.NormalizedUser.UserId )"

        return $null
      } else {
        try {
          $UserFromTwitter       = $UserFromTwitter | ConvertFrom-Json
        } catch {
          "$(get-date -format u) [Update-TwUserProfileData] - Unable to transform user profile data: $( $user.NormalizedUser.UserId ) - $UserFromTwitter" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
          Write-Debug "[Update-TwUserProfileData] - Unable to transform user profile data: $( $user.NormalizedUser.UserId )"

          return $null
        }

        $UserFromTwitter         = $UserFromTwitter | ConvertTo-TwNormalizedUserProfileData
        Start-Sleep -Seconds $TimeToWait
      }
    } else {
      Write-Debug "[Update-TwUserProfileData] - Skipping non-Twitter user: $($_.ChannelName)"

      return $null
    }

    $ChangeLog                   = New-Object PSObject -Property $ChangeLogTemplate

    $ChangeLog.TimeStamp         = Get-Date -format $DefaultDateFormat
    $ChangeLog.PropertyName      = "LastUpdateDate"
    $ChangeLog.OriginalValue     = $user.LastUpdateDate
    $ChangeLog.NewValue          = $ChangeLog.TimeStamp

    $UpdatedUser                 = $user
    $UpdatedUser.LastUpdateDate  = $ChangeLog.TimeStamp
    [PSObject[]] $UpdatedUser.ChangeLog += $ChangeLog

    ( $UpdatedUser.NormalizedUser | Get-Member -MemberType NoteProperty ).Name | ForEach-Object {
      Write-Debug "[Update-TwUserProfileData] - Current Property Name: $_"

      if ( $user.NormalizedUser.$_ -ne $null ) {
        $CurrentChanges            = Compare-Object $user.NormalizedUser.$_ $UserFromTwitter.NormalizedUser.$_

        if ( $CurrentChanges.Count -ne 0 ) {
          $ChangeLog.TimeStamp     = $UpdatedUser.LastUpdateDate
          $ChangeLog.PropertyName  = $_
          $ChangeLog.OriginalValue = $user.NormalizedUser.$_
          $ChangeLog.NewValue      = $UserFromTwitter.NormalizedUser.$_

          [PSObject[]] $UpdatedUser.ChangeLog += $ChangeLog
        }
      }
    }

    $UpdatedUser.NormalizedUser  = $UserFromTwitter.NormalizedUser
    [PSObject[]] $UpdatedUser.RawObject += $UserFromTwitter.RawObject

    $UpdatedUser
  }
}


function Get-TwTimeLine( [string] $name, [int] $results = $connections.Twitter.DefaultResultsToReturn, [switch] $quick ) {
  <#
    .SYNOPSIS
      Retrieves the current state of a users's time line.

    .DESCRIPTION
      Retrieves the current state of a users's time line.

    .EXAMPLE
      $tweets = Get-TwTimeLine -name cveira -results 250 -quick

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  # $DebugPreference = "Continue"

  $LogFileName                             = "TwitterModule"

  [System.Collections.ArrayList] $TimeLine = @()
  [PSObject[]] $tweets                     = @()

  $TwitterMaxResults                       = $connections.Twitter.ApiMaxResults
  $TimeToWait                              = $connections.Twitter.ApiDelayForTweets


  if ( $results -lt $TwitterMaxResults ) {
    $tweets = Get-RawTweetsFromUserAsJson -name $name -results $results

    if ( $tweets  -ilike "Exception*" ) {
      "$(get-date -format u) [Get-TwTimeLine] - Unable to retrieve tweets: $name - $tweets" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      Write-Debug "[Get-TwTimeLine] - Unable to retrieve tweets: $name"

      return $null
    }

    try {
      $tweets          = $tweets | ConvertFrom-Json

      if ( $tweets.count -gt $results ) {
        $tweets        = $tweets[0..( $results - 1 )]
      }
    } catch {
      "$(get-date -format u) [Get-TwTimeLine] - Unable to transform tweets: $name - $tweets" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      Write-Debug "[Get-TwTimeLine] - Unable to transform tweets: $name"

      return $null
    }
  } else {
    $ExecutionTime     = [Diagnostics.Stopwatch]::StartNew()
    $ExecutionTime.Stop()

    do {
      Write-Progress -Activity "Retrieving Tweets ..." -Status "Progress: $($tweets.Count) / $results  - ETC: $( '{0:#0.00}' -f (( $results - $($tweets.Count) ) * $ExecutionTime.Elapsed.TotalMinutes ) ) minutes - Time Elapsed: $( '{0:#0.00}' -f (( $($tweets.Count) - 1 ) * $ExecutionTime.Elapsed.TotalMinutes ) ) minutes" -PercentComplete ( ( $($tweets.Count) / $results ) * 100 )

      $ExecutionTime   = [Diagnostics.Stopwatch]::StartNew()

      $CurrentTweets   = Get-RawTweetsFromUserAsJson -name $name -results $TwitterMaxResults -FirstId $LastId

      if ( $CurrentTweets  -ilike "Exception*" ) {
        "$(get-date -format u) [Get-TwTimeLine] - Unable to retrieve tweets: $name - $CurrentTweets" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "[Get-TwTimeLine] - Unable to retrieve tweets: $name"

        return $null
      }

      try {
        $CurrentTweets = $CurrentTweets | ConvertFrom-Json
      } catch {
        "$(get-date -format u) [Get-TwTimeLine] - Unable to transform tweets: $name - $CurrentTweets" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "[Get-TwTimeLine] - Unable to transform tweets: $name"

        return $null
      }

      Write-Debug "[Get-TwTimeLine] - Retrieved Tweets:    $($tweets.Count)"
      Write-Debug "[Get-TwTimeLine] - CurrentTweets count: $($CurrentTweets.Count)"
      Write-Debug "[Get-TwTimeLine] - LastId:              $LastId"
      Write-Debug "[Get-TwTimeLine] - FirstId:             $($CurrentTweets[0].id)"

      if ( $CurrentTweets[0].id -eq $LastId ) {
        $FirstTweet    = 1
      } else {
        $FirstTweet    = 0
      }

      $LastId          = $CurrentTweets[ ( $CurrentTweets.Count - 1 ) ].id
      $tweets         += $CurrentTweets[ $FirstTweet..($CurrentTweets.Count - 1) ]

      Start-Sleep -Seconds $TimeToWait

      $ExecutionTime.Stop()
    } until ( $tweets.Count -gt $results )

    $tweets            = $tweets[0..( $results - 1 )]
  }

  if ( $quick ) {
    $i                 = 1
    $ExecutionTime     = [Diagnostics.Stopwatch]::StartNew()
    $ExecutionTime.Stop()

    foreach ( $tweet in $tweets ) {
      Write-Progress -Activity "Normalizing Information (QuickMode) ..." -Status "Progress: $i / $results - ETC: $( '{0:#0.00}' -f (( $results - $i ) * $ExecutionTime.Elapsed.TotalMinutes ) ) minutes - Time Elapsed: $( '{0:#0.00}' -f (( $i - 1 ) * $ExecutionTime.Elapsed.TotalMinutes ) ) minutes" -PercentComplete ( ( $i / $results ) * 100 )

      $ExecutionTime   = [Diagnostics.Stopwatch]::StartNew()

      $NormalizedPost  = $tweet | ConvertTo-TwNormalizedPost

      $TimeLine.Add( $( $NormalizedPost | ConvertTo-JSON ) ) | Out-Null

      $ExecutionTime.Stop()

      $i++
    }
  } else {
    $i                 = 1
    $ExecutionTime     = [Diagnostics.Stopwatch]::StartNew()
    $ExecutionTime.Stop()

    foreach ( $tweet in $tweets ) {
      Write-Progress -Activity "Normalizing Information ..." -Status "Progress: $i / $results - ETC: $( '{0:#0.00}' -f (( $results - $i ) * $ExecutionTime.Elapsed.TotalMinutes ) ) minutes - Time Elapsed: $( '{0:#0.00}' -f (( $i - 1 ) * $ExecutionTime.Elapsed.TotalMinutes ) ) minutes" -PercentComplete ( ( $i / $results ) * 100 )

      $ExecutionTime   = [Diagnostics.Stopwatch]::StartNew()

      $NormalizedPost  = $tweet | ConvertTo-TwNormalizedPost -IncludeAll

      $TimeLine.Add( $( $NormalizedPost | ConvertTo-JSON ) ) | Out-Null

      $ExecutionTime.Stop()

      $i++
    }
  }

  $TimeLine | ForEach-Object { ConvertFrom-JSON $_ }

  # $DebugPreference = "SilentlyContinue"
}


function ConvertTo-TwNormalizedPost( [switch] $IncludeAll, [string] $schema = $SCHEMA_DEFAULT ) {
  <#
    .SYNOPSIS
      Normalizes post information by mapping Twitter API data structures into a normalized one. Additionally, it also gathers additional relevant information about that post.

    .DESCRIPTION
      Normalizes post information by mapping Twitter API data structures into a normalized one. Additionally, it also gathers additional relevant information about that post.

    .EXAMPLE
      $NormalizedTweet  = $tweet  | ConvertTo-TwNormalizedPost -IncludeAll
      $TimeLine        += $tweets | ConvertTo-TwNormalizedPost -IncludeAll

    .NOTES
      High-level function. However, under normal circumstances, an end user shouldn't feel the need to use this function: other high-level functions use of it in order to make this details transparent to the end user.

    .LINK
      N/A
  #>


  begin {
    # $DebugPreference = "Continue"

    $LogFileName                     = "TwitterModule"

    $TimeToWait                      = 0
    $TimeToWaitForRTs                = $connections.Twitter.ApiDelayForRTs
    $TimeToWaitForFavs               = $connections.Twitter.ApiDelayForFavs

    $SourcePattern                   = '((?s)<a[^>]*[^>]*>(?<TweetSource>.*?)</a>)'

    $IncludeRTs                      = $false
    $IncludeFavorites                = $false
    $IncludeLinkMetrics              = $false

    $SkipRetweets                    = $false

    if ( $IncludeAll ) {
      $IncludeRTs                    = $true
      $IncludeFavorites              = $true
      $IncludeLinkMetrics            = $true
    }

    if ( $TimeToWaitForRTs -ge $TimeToWaitForFavs ) {
      $TimeToWait                    = $TimeToWaitForRTs
    } else {
      $TimeToWait                    = $TimeToWaitForFavs
    }
  }

  process {
    $tweet                                           = $_

    $NewTweet                                        = New-SMPost -schema $schema
    $NewTweet.RetainUntilDate                        = "{0:$DefaultDateFormat}" -f [datetime] ( ( [datetime] $NewTweet.RetainUntilDate ).AddDays( $connections.Twitter.DataRetention ) )

    $NewTweet.NormalizedPost.PostId                  = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $tweet.id } else { Get-SMPostDigest $tweet.id }
    $NewTweet.NormalizedPost.PostDigest              = Get-SMPostDigest $tweet.text

    if ( $tweet.retweeted_status.user.screen_name -eq $null ) {
      $NewTweet.NormalizedPost.PermaLink             = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { "https://twitter.com/$($tweet.user.screen_name)/status/$($tweet.id)"                                      } else { Get-SMPostDigest "https://twitter.com/$($tweet.user.screen_name)/status/$($tweet.id)"                                      }
    } else {
      $NewTweet.NormalizedPost.PermaLink             = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { "https://twitter.com/$($tweet.retweeted_status.user.screen_name)/status/$($tweet.retweeted_status.id)" } else { Get-SMPostDigest "https://twitter.com/$($NewTweet.retweeted_status.user.screen_name)/status/$($tweet.retweeted_status.id)" }
    }

    $NewTweet.NormalizedPost.ChannelName             = $CHANNEL_NAME_TWITTER
    $NewTweet.NormalizedPost.SubChannelName          = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_LOW    ) { $tweet.user.screen_name } else { Get-SMPostDigest $tweet.user.screen_name }
    $NewTweet.NormalizedPost.SourceDomain            = $VALUE_NA
    $NewTweet.NormalizedPost.PostType                = $POST_TYPE_MESSAGE
    $NewTweet.NormalizedPost.ChannelType             = $CHANNEL_TYPE_MICROBLOG
    $NewTweet.NormalizedPost.ChannelDataEngine       = $CHANNEL_DATA_ENGINE_RESTAPI
    $NewTweet.NormalizedPost.SourceFormat            = $DATA_FORMAT_JSON
    $NewTweet.NormalizedPost.Language                = if ( ( $tweet.lang -eq $null ) -or ( $tweet.lang -eq "" ) ) { $VALUE_NA } else { $tweet.lang }

    $NewTweet.NormalizedPost.AuthorId                = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_LOW    ) { $tweet.user.screen_name } else { Get-SMPostDigest $tweet.user.screen_name }
    $NewTweet.NormalizedPost.AuthorDisplayName       = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_LOW    ) { $tweet.user.name        } else { Get-SMPostDigest $tweet.user.name        }

    $NewTweet.NormalizedPost.PublishingDate          = "{0:$DefaultDateFormat}" -f [datetime] ( $tweet.created_at.Split("+")[1].Split(" ")[1] + " " + $tweet.created_at.Split("+")[0] )

    $NewTweet.NormalizedPost.Title                   = $tweet.text
    $NewTweet.NormalizedPost.PostContent             = $tweet.text


    if ( $tweet.source -match $SourcePattern ) {
      $NewTweet.NormalizedPost.SourceApplication     = $Matches.TweetSource
    }

    $NewTweet.NormalizedPost.SharedLinks             = @()
    $NewTweet.NormalizedPost.SharedTargetURLs        = @()
    $NewTweet.NormalizedPost.Tags                    = @()

    $NewTweet.NormalizedPost.SharedLinks            += if ( $tweet.entities.urls.expanded_url -eq $null ) { "" } else { $tweet.entities.urls.expanded_url }
    $NewTweet.NormalizedPost.SharedTargetURLs       += if ( $tweet.entities.urls.expanded_url -match $LinkShorteners ) { ( $tweet.entities.urls.expanded_url | Expand-ShortLink ).ExpandedUrl } else { $tweet.entities.urls.expanded_url }
    $NewTweet.NormalizedPost.Tags                   += if ( $tweet.entities.hashtags.text -eq $null ) { "" } else { $tweet.entities.hashtags.text }


    if ( $IncludeLinkMetrics ) {
      if ( $NewTweet.NormalizedPost.SharedLinks -gt 0 ) {
        $NewTweet.NormalizedPost.SharedLinks | ForEach-Object {
          if ( $_ -like "*bit*" ) {
            $LinkGlobalMetrics                           = Get-BLLinkGlobalMetrics $_

            $NewTweet.NormalizedPost.ClickThroughsCount += $LinkGlobalMetrics.clicks.link_clicks
            $NewTweet.NormalizedPost.InteractionsCount  += $LinkGlobalMetrics.shares.total_shares

            Start-Sleep -Seconds $connections.BitLy.ApiDelay
          }
        }
      }
    }


    $ExistingConnections                                 = $NewTweet.PostConnections.count
    $i                                                   = $ExistingConnections

    if ( $tweet.entities.user_mentions.count -gt 0 ) {
      $NewTweet.PostConnections                         += New-Object PSObject -Property $UserConnectionsTemplate

      $tweet.entities.user_mentions | ForEach-Object {
        $NewTweet.PostConnections[$i].UserId             = if ( $connections.Twitter.PrivacyLevel -eq $PRIVACY_LEVEL_NONE ) { $_.screen_name                          } else { Get-SMPostDigest $_.screen_name                          }
        $NewTweet.PostConnections[$i].UserDisplayName    = if ( $connections.Twitter.PrivacyLevel -eq $PRIVACY_LEVEL_NONE ) { $_.name                                 } else { Get-SMPostDigest $_.name                                 }
        $NewTweet.PostConnections[$i].UserProfileUrl     = if ( $connections.Twitter.PrivacyLevel -eq $PRIVACY_LEVEL_NONE ) { "https://twitter.com/$($_.screen_name)" } else { Get-SMPostDigest "https://twitter.com/$($_.screen_name)" }
        $NewTweet.PostConnections[$i].EngagementType     = $ENGAGEMENT_TYPE_INTERACTION

        if ( ( $ExistingConnections + $tweet.entities.user_mentions.screen_name.count ) -gt ( $i + 1 ) ) {
          $NewTweet.PostConnections                     += New-Object PSObject -Property $UserConnectionsTemplate
        }

        $i++
      }

      $NewTweet.NormalizedPost.InteractionsCount         = $tweet.entities.user_mentions.count
    }


    if ( $IncludeRTs ) {
      if ( $tweet.entities.retweets -eq $null ) {
        $tweet.entities | Add-Member -NotePropertyName retweets -NotePropertyValue @()
      } else {
        $tweet.entities.retweets                         = @()
      }

      $tweet.entities.retweets                           = Get-RawTweetRetweetsAsJson $NewTweet.NormalizedPost.PermaLink

      if ( $tweet.entities.retweets  -ilike "Exception*" ) {
        "$(get-date -format u) [ConvertTo-TwNormalizedPost] - Unable to retrieve retweets: $( $NewTweet.NormalizedPost.PermaLink ) - $( $tweet.entities.retweets )" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "Unable to retrieve retweets: $( $NewTweet.NormalizedPost.PermaLink )"

        $SkipRetweets                                    = $true
      } else {
        try {
          $tweet.entities.retweets                       = $tweet.entities.retweets | ConvertFrom-Json
          $SkipRetweets                                  = $false
        } catch {
          "$(get-date -format u) [ConvertTo-TwNormalizedPost] - Unable to transform retweets: $( $NewTweet.NormalizedPost.PermaLink ) - $( $tweet.entities.retweets )" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
          Write-Debug "Unable to transform retweets: $( $NewTweet.NormalizedPost.PermaLink )"

          $SkipRetweets                                  = $true
        }
      }

      if ( !$SkipRetweets ) {
        $ExistingConnections                             = $NewTweet.PostConnections.count
        $i                                               = $ExistingConnections

        if ( $tweet.entities.retweets.count -gt 0 ) {
          $NewTweet.PostConnections                     += New-Object PSObject -Property $UserConnectionsTemplate

          $tweet.entities.retweets | ForEach-Object {
            $NewTweet.PostConnections[$i].UserId         = if ( $connections.Twitter.PrivacyLevel -eq $PRIVACY_LEVEL_NONE ) { $_.user.screen_name                          } else { Get-SMPostDigest $_.user.screen_name                          }
            $NewTweet.PostConnections[$i].UserProfileUrl = if ( $connections.Twitter.PrivacyLevel -eq $PRIVACY_LEVEL_NONE ) { "https://twitter.com/$($_.user.screen_name)" } else { Get-SMPostDigest "https://twitter.com/$($_.user.screen_name)" }
            $NewTweet.PostConnections[$i].Location       = $_.user.location
            $NewTweet.PostConnections[$i].EngagementType = $ENGAGEMENT_TYPE_CONVERSATION

            if ( ( $ExistingConnections + $tweet.entities.retweets.count ) -gt ( $i + 1 ) ) {
              $NewTweet.PostConnections                 += New-Object PSObject -Property $UserConnectionsTemplate
            }

            $i++
          }

          $NewTweet.NormalizedPost.InteractionsCount    += $tweet.entities.retweets.count
        }
      }
    }


    if ( $IncludeFavorites ) {
      if ( $tweet.favorites_count -eq $null ) {
        $tweet | Add-Member -NotePropertyName favorites_count -NotePropertyValue 0
      } else {
        $tweet.favorites_count                           = 0
      }

      $SourceCode                                        = Get-PageSourceCode $NewTweet.NormalizedPost.PermaLink
      $tweet.favorites_count                             = Get-RawTweetFavoritesFromPage ([ref] $SourceCode)

      if ( $tweet.favorites_count -eq $null ) {
        $tweet.favorites_count                           = 0
      }

      $NewTweet.NormalizedPost.InterestCount             = $tweet.favorites_count
    }

    if ( $IncludeAll ) { Start-Sleep -Seconds $TimeToWait }

    $NewTweet.RawObject                                  = $tweet

    $NewTweet

    # $DebugPreference = "SilentlyContinue"
  }
}


function Update-TwPosts( [PSObject[]] $from ) {
  <#
    .SYNOPSIS
      Updates information about a collection of posts.

    .DESCRIPTION
      Updates information about a collection of posts. Unlike Update-TwPost, this function doesn't accept data from the pipeline. Howerver, it does provide feedback about the progress of the update process.

    .EXAMPLE
      $UpdatedTwitterTimeLine = Update-TwPosts -from $NormalizedTimeLine
      $UpdatedTwitterTimeLine = Update-TwPosts -from $PermaLinksList

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

    Write-Debug "[Update-TwPosts] - CurrentUser:         $i"
    Write-Debug "[Update-TwPosts] - TotalUsers:          $($from.Count)"
    Write-Debug "[Update-TwPosts] - Retrieved Tweets:    $($ExecutionTime.Elapsed.TotalMinutes)"

    $ExecutionTime = [Diagnostics.Stopwatch]::StartNew()

    $UpdatedPosts.Add( $( $post | Update-TwPost -IncludeAll | ConvertTo-JSON ) ) | Out-Null

    $ExecutionTime.Stop()

    $i++
  }

  $UpdatedPosts | ForEach-Object { if ( $_ -ne $null ) { ConvertFrom-JSON $_ } }
}


function Update-TwPost( [switch] $IncludeAll, [string] $schema = $SCHEMA_DEFAULT ) {
  <#
    .SYNOPSIS
      Updates information about a collection of posts.

    .DESCRIPTION
      Updates information about a collection of posts. Unlike Update-TwPosts, this function accepts data from the pipeline. Howerver, it doesn't provide feedback about the progress of the update process.

    .EXAMPLE
      $UpdatedTwitterPost     = $NormalizedTwitterPost     | Update-TwPost -IncludeAll
      $UpdatedTwitterTimeLine = $NormalizedTwitterTimeLine | Update-TwPost -IncludeAll

      $UpdatedTwitterPost     = $PermaLink                       $UpdatedTwitterFollowers = Update-TwUserProfileData -from $followers
      $UpdatedTwitterFollowers = Update-TwUserProfileData -from $followers
| Update-TwPost -IncludeAll
      $UpdatedTwitterTimeLine = $PermaLinksList            | Update-TwPost -IncludeAll

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  begin {
    $LogFileName = "TwitterModule"
    $TimeToWait  = $connections.Twitter.ApiDelayForTweets
  }

  process {
    $UpdatedPost = [PSCustomObject] @{}

    if ( $_ -is [string] ) {
      $post                              = New-SMPost -schema $schema
      $post.NormalizedPost.PermaLink     = $_

      if ( $_ -ilike "*$CHANNEL_NAME_TWITTER*" ) {
        $post.NormalizedPost.ChannelName = $CHANNEL_NAME_TWITTER
      } else {
        $post.NormalizedPost.ChannelName = $CHANNEL_NAME_UNKNOWN
      }
    } else {
      $post                              = $_
    }

    if ( $post.NormalizedPost.ChannelName -eq $CHANNEL_NAME_TWITTER ) {
      $PostFromTwitter           = Get-RawTweetAsJson $post.NormalizedPost.PermaLink

      if ( $PostFromTwitter  -ilike "Exception*" ) {
        "$(get-date -format u) [Update-TwPost] - Unable to retrieve post: $( $post.NormalizedPost.PermaLink ) - $PostFromTwitter" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "[Update-TwPost] - Unable to retrieve post: $( $post.NormalizedPost.PermaLink )"

        return $null
      } else {
        try {
          $PostFromTwitter       = $PostFromTwitter | ConvertFrom-Json
        } catch {
          "$(get-date -format u) [Update-TwPost] - Unable to transform post: $( $post.NormalizedPost.PermaLink ) - $PostFromTwitter" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
          Write-Debug "[Update-TwPost] - Unable to transform post: $( $post.NormalizedPost.PermaLink )"

          return $null
        }

        $PostFromTwitter         = $PostFromTwitter | ConvertTo-TwNormalizedPost -IncludeAll
        Start-Sleep -Seconds $TimeToWait
      }
    } else {
      Write-Debug "[Update-TwPost] - Skipping non-Twitter post: $($_.ChannelName)"

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
      Write-Debug "[Update-TwPost] - Current Property Name: $_"

      if ( $post.NormalizedPost.$_ -ne $null ) {
        $CurrentChanges            = Compare-Object $post.NormalizedPost.$_ $PostFromTwitter.NormalizedPost.$_

        if ( $CurrentChanges.Count -ne 0 ) {
          $ChangeLog.TimeStamp     = $UpdatedPost.LastUpdateDate
          $ChangeLog.PropertyName  = $_
          $ChangeLog.OriginalValue = $post.NormalizedPost.$_
          $ChangeLog.NewValue      = $PostFromTwitter.NormalizedPost.$_

          [PSObject[]] $UpdatedPost.ChangeLog += $ChangeLog
        }
      }
    }

    $UpdatedPost.NormalizedPost          = $PostFromTwitter.NormalizedPost
    [PSObject[]] $UpdatedPost.RawObject += $PostFromTwitter.RawObject

    $UpdatedPost
  }
}


function Search-TwPosts( [string] $query, [int] $results = $connections.Twitter.DefaultResultsToReturn, [string] $language = "", [string] $type = "mixed", [string] $StartDate = "", [string] $GeoCode = "", [switch] $quick ) {
  <#
    .SYNOPSIS
      Returns a collection of relevant Tweets matching a specified query.

    .DESCRIPTION
      Returns a collection of relevant Tweets matching a specified query.

    .EXAMPLE
      Search-TwPosts -query "#cloud" -results 250

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  # $DebugPreference = "Continue"

  $LogFileName           = "TwitterModule"

  [System.Collections.ArrayList] $TimeLine = @()
  [PSObject[]] $tweets                     = @()
  $TwitterMaxResults                       = $connections.Twitter.ApiMaxResults
  $TimeToWait                              = $connections.Twitter.ApiDelayForSearch
  [int64] $MaxId                           = 0


  if    ( ( $type      -ne "recent" ) -and ( $type      -ne    "popular"                                ) )   { $type      = "mixed" }
  if ( !( ( $StartDate -ne ""       ) -and ( $StartDate -match "\d{4}-\d{2}-\d{2}"                      ) ) ) { $StartDate = ""      }
  if ( !( ( $GeoCode   -ne ""       ) -and ( $GeoCode   -match "(\-*[\d\.]+),(\-*[\d\.]+),(\d+)(km|mi)" ) ) ) { $GeoCode   = ""      }
  if ( !( ( $language  -ne ""       ) -and ( $language  -match "\w{2}"                                  ) ) ) { $language  = ""      }


  if ( $results -lt $TwitterMaxResults ) {
    $tweets          = Get-RawTwitterSearchAsJson -query $query -ResultsPerPage $results -Language $language -ResultType $type -StartDate $StartDate -GeoCode $GeoCode

    if ( $tweets -ilike "Exception*" ) {
      "$(get-date -format u) [Search-TwPosts] - Unable to retrieve search: $query - $tweets" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      Write-Debug "[Search-TwPosts] - Unable to retrieve search: $query"

      return $null
    }

    try {
      $tweets        = ( $tweets | ConvertFrom-Json ).statuses

      if ( $tweets.count -gt $results ) {
        $tweets      = $tweets[0..( $results - 1 )]
      }
    } catch {
      "$(get-date -format u) [Search-TwPosts] - Unable to transform tweets: $query - $tweets" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      Write-Debug "[Search-TwPosts] - Unable to transform tweets: $query - $tweets"

      return $null
    }
  } else {
    $MaxId           = 0
    $ExecutionTime   = [Diagnostics.Stopwatch]::StartNew()
    $ExecutionTime.Stop()

    do {
      Write-Progress -Activity "Retrieving Tweets ..." -Status "Progress: $($tweets.Count) / $results - ETC: $( '{0:#0.00}' -f (( $results - $($tweets.Count) ) * $ExecutionTime.Elapsed.TotalMinutes) ) minutes - Time Elapsed: $( '{0:#0.00}' -f (( $($tweets.Count) - 1 ) * $ExecutionTime.Elapsed.TotalMinutes) ) minutes" -PercentComplete ( ( $($tweets.Count) / $results ) * 100 )

      $ExecutionTime = [Diagnostics.Stopwatch]::StartNew()

      if ( $MaxId -eq 0 ) {
        $CurrentTweets = Get-RawTwitterSearchAsJson -query $query -ResultsPerPage $TwitterMaxResults -Language $language -ResultType $type -StartDate $StartDate -GeoCode $GeoCode
      } else {
        $CurrentTweets = Get-RawTwitterSearchAsJson -query $query -ResultsPerPage $TwitterMaxResults -Language $language -ResultType $type -StartDate $StartDate -GeoCode $GeoCode -MaxId ( $MaxId - 1 )
      }

      if ( $CurrentTweets  -ilike "Exception*" ) {
        "$(get-date -format u) [Search-TwPosts] - Unable to retrieve search: $query - $CurrentTweets" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "[Search-TwPosts] - Unable to retrieve search: $query - $CurrentTweets"

        return $null
      }

      try {
        $CurrentTweets = $CurrentTweets | ConvertFrom-Json
      } catch {
        "$(get-date -format u) [Search-TwPosts] - Unable to transform tweets: $query - $CurrentTweets" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "[Search-TwPosts] - Unable to transform tweets: $query - $CurrentTweets"

        return $null
      }

      if ( $CurrentTweets.statuses.count -eq 0 ) {
        break
      }

      Write-Debug "[Search-TwPosts] - Retrieved Tweets:             $($tweets.Count)"
      Write-Debug "[Search-TwPosts] - CurrentTweets count:          $($CurrentTweets.statuses.Count)"
      Write-Debug "[Search-TwPosts] - CurrentTweets metadata count: $($CurrentTweets.search_metadata.count)"
      Write-Debug "[Search-TwPosts] - MaxId:                        $MaxId"

      $MaxId           = $CurrentTweets.search_metadata.max_id
      $tweets         += $CurrentTweets.statuses

      Start-Sleep -Seconds $TimeToWait

      $ExecutionTime.Stop()
    } until ( $tweets.Count -gt $results )

    if ( $tweets.count -gt $results ) {
      $tweets          = $tweets[0..( $results - 1 )]
    }
  }

  if ( $quick ) {
    $i                 = 1
    $ExecutionTime     = [Diagnostics.Stopwatch]::StartNew()
    $ExecutionTime.Stop()

    foreach ( $tweet in $tweets ) {
      Write-Progress -Activity "Normalizing Information (QuickMode) ..." -Status "Progress: $i / $results - ETC: $( '{0:#0.00}' -f (( $results - $i ) * $ExecutionTime.Elapsed.TotalMinutes ) ) minutes - Time Elapsed: $( '{0:#0.00}' -f (( $i - 1 ) * $ExecutionTime.Elapsed.TotalMinutes ) ) minutes" -PercentComplete ( ( $i / $results ) * 100 )

      $ExecutionTime   = [Diagnostics.Stopwatch]::StartNew()

      $NormalizedPost  = $tweet | ConvertTo-TwNormalizedPost

      $TimeLine.Add( $( $NormalizedPost | ConvertTo-JSON ) ) | Out-Null

      $ExecutionTime.Stop()

      $i++
    }
  } else {
    $i                 = 1
    $ExecutionTime     = [Diagnostics.Stopwatch]::StartNew()
    $ExecutionTime.Stop()

    foreach ( $tweet in $tweets ) {
      Write-Progress -Activity "Normalizing Information ..." -Status "Progress: $i / $results - ETC: $( '{0:#0.00}' -f (( $results - $i ) * $ExecutionTime.Elapsed.TotalMinutes ) ) minutes - Time Elapsed: $( '{0:#0.00}' -f (( $i - 1 ) * $ExecutionTime.Elapsed.TotalMinutes ) ) minutes" -PercentComplete ( ( $i / $results ) * 100 )

      $ExecutionTime   = [Diagnostics.Stopwatch]::StartNew()

      $NormalizedPost  = $tweet | ConvertTo-TwNormalizedPost -IncludeAll

      $TimeLine.Add( $( $NormalizedPost | ConvertTo-JSON ) ) | Out-Null

      $ExecutionTime.Stop()

      $i++
    }
  }

  $TimeLine | ForEach-Object { ConvertFrom-JSON $_ }

  # $DebugPreference = "SilentlyContinue"
}