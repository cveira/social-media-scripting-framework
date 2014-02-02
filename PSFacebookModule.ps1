<#
-------------------------------------------------------------------------------
Name:    Social Media Scripting Framework
Module:  Facebook
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


function Get-RawFBPostAudienceFromPage( [ref] $PageSourceCode ) {
  <#
    .SYNOPSIS
      Parses the raw HTML contents of a web-based Facebook post to get the audience information.

    .DESCRIPTION
      Parses the raw HTML contents of a web-based Facebook post to get the audience information.

    .EXAMPLE
      $SourceCode = Get-PageSourceCodeFromIE <Facebook-Post-PermaLink>
      Get-RawFBPostAudienceFromPage ([ref] $SourceCode)

    .NOTES
      Low-level function. Depends on Get-PageSourceCodeFromIE in order leverage existing session cookies.

    .LINK
      N/A
  #>


  # [string] $AudiencePattern = '<a href="#">(?<AudienceCount>.*?) people saw this post</a>'
  [string] $AudiencePattern = '<span class="pas fcb">(?<AudienceCount>.*?) people saw this post</span>'

  $AudienceFound            = 0

  if ( $PageSourceCode.Value -match $AudiencePattern ) {
    $AudienceFound          = [int] $Matches.AudienceCount.Trim()
  }

  $AudienceFound
}


function Get-RawFBPostLikesFromPage( [ref] $PageSourceCode ) {
  <#
    .SYNOPSIS
      Parses the raw HTML contents of a web-based Facebook post to get the number of likes.

    .DESCRIPTION
      Parses the raw HTML contents of a web-based Facebook post to get the number of likes.

    .EXAMPLE
      $SourceCode = Get-PageSourceCodeFromIE <Facebook-Post-PermaLink>
      Get-RawFBPostLikesFromPage ([ref] $SourceCode)

    .NOTES
      Low-level function. Depends on Get-PageSourceCodeFromIE in order leverage existing session cookies.

    .LINK
      N/A
  #>


  # [string] $LikesPattern = '"text":"(?<LikesCount>.*?) people like this."'
  [string] $LikesPattern = '"likecount":(?<LikesCount>.*?),'

  $LikesFound            = 0

  if ( $PageSourceCode.Value -match $LikesPattern ) {
    $LikesFound          = [int] $Matches.LikesCount.Trim()
  }

  $LikesFound
}


function Get-RawFBPostCommentsFromPage( [ref] $PageSourceCode ) {
  <#
    .SYNOPSIS
      Parses the raw HTML contents of a web-based Facebook post to get the number of comments.

    .DESCRIPTION
      Parses the raw HTML contents of a web-based Facebook post to get the number of comments.

    .EXAMPLE
      $SourceCode = Get-PageSourceCodeFromIE <Facebook-Post-PermaLink>
      Get-RawFBPostCommentsFromPage ([ref] $SourceCode)

    .NOTES
      Low-level function. Depends on Get-PageSourceCodeFromIE in order leverage existing session cookies.

    .LINK
      N/A
  #>


  [string] $CommentsPattern = '"commentcount":(?<CommentsCount>.*?),'

  $CommentsFound            = 0

  if ( $PageSourceCode.Value -match $CommentsPattern ) {
    $CommentsFound          = [int] $Matches.CommentsCount.Trim()
  }

  $CommentsFound
}


function Search-RawFBPost( [string] $text, [ref] $on, [string] $by = "digest" ) {
  <#
    .SYNOPSIS
      Retrieves the first post in the Time Line that matches the provided text.

    .DESCRIPTION
      Retrieves the first post in the Time Line that matches the provided text. Search is performed over key post properties only like Digest or PermaLink.

    .EXAMPLE
      $PostFromFacebook = Search-RawFBPost -text $post.NormalizedPost.PermaLink -on ([ref] $TimeLine) -by permalink
      $PostFromFacebook = Search-RawFBPost -text $post.NormalizedPost.PermaLink -on ([ref] $TimeLine) -by digest

    .NOTES
      Low-level function. TimeLine is not normalized (is in Raw format)

    .LINK
      N/A
  #>


  $post = $null

  switch ( $by.ToLower() ) {
    "permalink" {
      $on.Value | ForEach-Object {
        if ( $_.link -match "photo.php" ) {
          if ( $text -eq $_.link ) {
            $post = $_

            break
          }
        } else {
          if ( $text -eq $_.actions[0].link ) {
            $post = $_

            break
          }
        }
      }
    }

    default {
      $on.Value | ForEach-Object {
        if ( $text -eq $( Get-SMPostDigest $_.message ) ) {
          $post = $_

          break
        }
      }
    }
  }

  $post
}


function Get-RawFBTimeLine( $connection = $connections.Facebook.connection ) {
  <#
    .SYNOPSIS
      Retrieves the raw Facebook Time Line either from the local cache or from Facebook itself.

    .DESCRIPTION
      Retrieves the raw Facebook Time Line either from the local cache or from Facebook itself.

    .EXAMPLE
      $RawFBTimeLine = Get-RawFBTimeLine

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  $CacheFile    = "$CurrentCacheDir\FBTimeLineCache-$($connections.Facebook.DefaultPageName).xml"

  if ( Test-Path $CacheFile ) {
    if ( ( Get-ChildItem $CacheFile ).LastWriteTime.Subtract( $(Get-Date) ).TotalHours -lt -($connections.Facebook.PostsCacheExpiration) ) {
      $TimeLine = Get-FBPost -Connection $connection
      $TimeLine | Export-CliXml $CacheFile
    } else {
      $TimeLine = Import-CliXml $CacheFile
    }
  } else {
    $TimeLine   = Get-FBPost -Connection $connection
    $TimeLine | Export-CliXml $CacheFile
  }

  $TimeLine
}


# --------------------------------------------------------------------------------------------------


function New-FBConnectionDetails() {
  <#
    .SYNOPSIS
      Creates a new connection to Facebook and displays the associated configuration information.

    .DESCRIPTION
      Creates a new connection to Facebook and displays the associated configuration information.

    .EXAMPLE
      New-FBConnectionDetails

    .NOTES
      High-level function. It is used during initial configuration or whenever there is a need to refresh connection details in the configuration file.

    .LINK
      N/A
  #>


  $connection = New-FBConnection -ExtendToken

  $connection

  Get-FBPage | Select Name, PageId, access_token | Format-List
}


function Get-FBTimeLine( [switch] $quick ) {
  <#
    .SYNOPSIS
      Retrieves a normalized Facebook Time Line either from the local cache or from Facebook itself.

    .DESCRIPTION
      Retrieves a normalized Facebook Time Line either from the local cache or from Facebook itself.

    .EXAMPLE
      $FBTimeLine = Get-FBTimeLine -quick

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  # $DebugPreference = "Continue"

  [PSObject[]] $RawTimeLine                = @()
  [System.Collections.ArrayList] $TimeLine = @()


  $RawTimeLine         = Get-RawFBTimeLine -connection $connections.Facebook.connection
  $results             = $RawTimeLine.count

  if ( $quick ) {
    $i                 = 1
    $ExecutionTime     = [Diagnostics.Stopwatch]::StartNew()
    $ExecutionTime.Stop()

    foreach ( $post in $RawTimeLine ) {
      Write-Progress -Activity "Normalizing Information (QuickMode) ..." -Status "Progress: $i / $results - ETC: $( '{0:#0.00}' -f (( $results - $i ) * $ExecutionTime.Elapsed.TotalMinutes ) ) minutes - Time Elapsed: $( '{0:#0.00}' -f (( $i - 1 ) * $ExecutionTime.Elapsed.TotalMinutes ) ) minutes" -PercentComplete ( ( $i / $results ) * 100 )

      $ExecutionTime   = [Diagnostics.Stopwatch]::StartNew()

      $NormalizedPost  = $post | ConvertTo-FBNormalizedPost

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

      $NormalizedPost  = $post | ConvertTo-FBNormalizedPost -IncludeAll

      $TimeLine.Add( $( $NormalizedPost | ConvertTo-JSON -Compress ) ) | Out-Null

      $ExecutionTime.Stop()

      $i++
    }
  }

  $TimeLine | ForEach-Object { ConvertFrom-JSON $_ }

  # $DebugPreference = "SilentlyContinue"
}


function ConvertTo-FBNormalizedPost( [switch] $IncludeAll, [string] $schema = $SCHEMA_DEFAULT ) {
  <#
    .SYNOPSIS
      Normalizes post information by mapping Facebook API data structures into a normalized one. Additionally, it also gathers additional relevant information about that post.

    .DESCRIPTION
      Normalizes post information by mapping Facebook API data structures into a normalized one. Additionally, it also gathers additional relevant information about that post.

    .EXAMPLE
      $NormalizedFBPost   = $FBPost  | ConvertTo-FBNormalizedPost -IncludeAll
      $NormalizedFBPosts += $FBPosts | ConvertTo-FBNormalizedPost -IncludeAll

    .NOTES
      High-level function. However, under normal circumstances, an end user shouldn't feel the need to use this function: other high-level functions use of it in order to make this details transparent to the end user.

    .LINK
      N/A
  #>


  begin {
    # $DebugPreference = "Continue"

    $LogFileName              = "FacebookModule"

    [PSObject[]] $NewTimeLine = @()
    $TimeToWait               = $connections.Facebook.ApiDelay

    if ( $IncludeAll ) {
      $IncludeRTs             = $true
      $IncludeFavorites       = $true
      $IncludeLinkMetrics     = $true
    }
  }

  process {
    $post                                               = $_
    $NewPost                                            = New-SMPost -schema $schema
    $NewPost.RetainUntilDate                            = "{0:$DefaultDateFormat}" -f [datetime] ( ( [datetime] $NewPost.RetainUntilDate ).AddDays( $connections.Facebook.DataRetention ) )

    $NewPost.NormalizedPost.PostId                      = if ( $connections.Facebook.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.id              } else { Get-SMPostDigest $post.id              }
    $NewPost.NormalizedPost.PostDigest                  = Get-SMPostDigest $post.message

    if ( $post.link -match "photo.php" ) {
      $NewPost.NormalizedPost.PermaLink                 = if ( $connections.Facebook.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.link            } else { Get-SMPostDigest $post.link            }
    } else {
      $NewPost.NormalizedPost.PermaLink                 = if ( $connections.Facebook.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.actions[0].link } else { Get-SMPostDigest $post.actions[0].link }
    }

    $NewPost.NormalizedPost.ChannelName                 = $CHANNEL_NAME_FACEBOOK
    $NewPost.NormalizedPost.SubChannelName              = if ( $connections.Facebook.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.from.name       } else {  Get-SMPostDigest $post.from.name      }
    $NewPost.NormalizedPost.SourceDomain                = $VALUE_NA

    if ( $post.type -eq $null ) {
      $NewPost.NormalizedPost.PostType                  = $VALUE_NA
    } else {
      switch ( $post.type ) {
        "link"   { $NewPost.NormalizedPost.PostType     = $POST_TYPE_LINK    }
        "status" { $NewPost.NormalizedPost.PostType     = $POST_TYPE_MESSAGE }
        "photo"  { $NewPost.NormalizedPost.PostType     = $POST_TYPE_PICTURE }
        "video"  { $NewPost.NormalizedPost.PostType     = $POST_TYPE_VIDEO   }
        "swf"    { $NewPost.NormalizedPost.PostType     = $POST_TYPE_VIDEO   }
        "event"  { $NewPost.NormalizedPost.PostType     = $POST_TYPE_EVENT   }
        default  { $NewPost.NormalizedPost.PostType     = $POST_TYPE_MESSAGE }
      }
    }

    $NewPost.NormalizedPost.ChannelType                 = $CHANNEL_TYPE_SN
    $NewPost.NormalizedPost.ChannelDataEngine           = $CHANNEL_DATA_ENGINE_RESTAPI
    $NewPost.NormalizedPost.SourceFormat                = $DATA_FORMAT_JSON
    $NewPost.NormalizedPost.Language                    = $VALUE_NA

    $NewPost.NormalizedPost.AuthorId                    = if ( $connections.Facebook.PrivacyLevel -le $PRIVACY_LEVEL_LOW    ) { $post.from.id         } else { Get-SMPostDigest $post.from.id         }
    $NewPost.NormalizedPost.AuthorDisplayName           = if ( $connections.Facebook.PrivacyLevel -le $PRIVACY_LEVEL_LOW    ) { $post.from.name       } else { Get-SMPostDigest $post.from.name       }

    $NewPost.NormalizedPost.PublishingDate              = "{0:$DefaultDateFormat}" -f $post.created_time

    $NewPost.NormalizedPost.Title                       = $post.name
    $NewPost.NormalizedPost.PostContent                 = $post.message

    $NewPost.NormalizedPost.SourceApplication           = $post.application.name

    if ( $post.application.name -eq $null ) {
      $NewPost.NormalizedPost.SourceApplication         = $VALUE_NA
    } else {
      $NewPost.NormalizedPost.SourceApplication         = $post.application.name
    }

    $NewPost.NormalizedPost.SharedLinks                 = @()
    $NewPost.NormalizedPost.SharedTargetURLs            = @()
    $NewPost.NormalizedPost.Tags                        = @()

    $NewPost.NormalizedPost.SharedLinks                += if ( $post.link -eq $null ) { "" } else { $post.link }
    $NewPost.NormalizedPost.SharedTargetURLs           += if ( $post.link -match $LinkShorteners ) { ( $post.link | Expand-ShortLink ).ExpandedUrl } else { $post.link }

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

    $SourceCode                                         = Get-PageSourceCodeFromIE $NewPost.NormalizedPost.PermaLink
    $NewPost.NormalizedPost.InterestCount               = Get-RawFBPostLikesFromPage    ([ref] $SourceCode)
    $NewPost.NormalizedPost.InteractionsCount           = Get-RawFBPostCommentsFromPage ([ref] $SourceCode)
    $NewPost.NormalizedPost.AudienceCount               = Get-RawFBPostAudienceFromPage ([ref] $SourceCode)

    if ( $post.shares -ne $null ) {
      $NewPost.NormalizedPost.InteractionsCount += $post.shares.count
    }


    $ExistingConnections                                = $NewPost.PostConnections.count
    $i                                                  = $ExistingConnections

    if ( $post.likes.count -gt 0 ) {
      $NewPost.PostConnections                         += New-Object PSObject -Property $UserConnectionsTemplate

      $post.likes | ForEach-Object {
        $NewPost.PostConnections[$i].UserId             = if ( $connections.Facebook.PrivacyLevel -eq $PRIVACY_LEVEL_NONE ) { $_.id                               } else { Get-SMPostDigest $_.id                               }
        $NewPost.PostConnections[$i].UserDisplayName    = if ( $connections.Facebook.PrivacyLevel -eq $PRIVACY_LEVEL_NONE ) { $_.name                             } else { Get-SMPostDigest $_.name                             }
        $NewPost.PostConnections[$i].UserProfileUrl     = if ( $connections.Facebook.PrivacyLevel -eq $PRIVACY_LEVEL_NONE ) { "https://www.facebook.com/$($_.id)" } else { Get-SMPostDigest "https://www.facebook.com/$($_.id)" }
        $NewPost.PostConnections[$i].EngagementType     = $ENGAGEMENT_TYPE_INTEREST

        if ( ( $ExistingConnections + $post.likes.count ) -gt ( $i + 1 ) ) {
          $NewPost.PostConnections                     += New-Object PSObject -Property $UserConnectionsTemplate
        }

        $i++
      }
    }


    $ExistingConnections                                = $NewPost.PostConnections.count
    $i                                                  = $ExistingConnections

    if ( $post.comments.count -gt 0 ) {
      $NewPost.PostConnections                         += New-Object PSObject -Property $UserConnectionsTemplate

      $post.comments.from | ForEach-Object {
        $NewPost.PostConnections[$i].UserId             = if ( $connections.Facebook.PrivacyLevel -eq $PRIVACY_LEVEL_NONE ) { $_.id                               } else { Get-SMPostDigest $_.id                               }
        $NewPost.PostConnections[$i].UserDisplayName    = if ( $connections.Facebook.PrivacyLevel -eq $PRIVACY_LEVEL_NONE ) { $_.name                             } else { Get-SMPostDigest $_.name                             }
        $NewPost.PostConnections[$i].UserProfileUrl     = if ( $connections.Facebook.PrivacyLevel -eq $PRIVACY_LEVEL_NONE ) { "https://www.facebook.com/$($_.id)" } else { Get-SMPostDigest "https://www.facebook.com/$($_.id)" }
        $NewPost.PostConnections[$i].EngagementType     = $ENGAGEMENT_TYPE_INTERACTION

        if ( ( $ExistingConnections + $post.comments.count ) -gt ( $i + 1 ) ) {
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


function Update-FBPosts( [PSObject[]] $from ) {
  <#
    .SYNOPSIS
      Updates information about a collection of posts. Unlike Update-FBPost, this function doesn't accept data from the pipeline. Howerver, it does provide feedback about the progress of the update process.

    .DESCRIPTION
      Updates information about a collection of posts. Unlike Update-FBPost, this function doesn't accept data from the pipeline. Howerver, it does provide feedback about the progress of the update process.

    .EXAMPLE
      $UpdatedFacebookTimeLine = Update-FBPosts -from $NormalizedTimeLine
      $UpdatedFacebookTimeLine = Update-FBPosts -from $PermaLinksList

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

    Write-Debug "[Update-FBPosts] - CurrentElement:      $i"
    Write-Debug "[Update-FBPosts] - TotalElements:       $($from.Count)"
    Write-Debug "[Update-FBPosts] - ElapsedMinutes:      $($ExecutionTime.Elapsed.TotalMinutes)"

    $ExecutionTime = [Diagnostics.Stopwatch]::StartNew()

    $UpdatedPosts.Add( $( $post | Update-FBPost -IncludeAll | ConvertTo-JSON ) ) | Out-Null

    $ExecutionTime.Stop()

    $i++
  }

  $UpdatedPosts | ForEach-Object { if ( $_ -ne $null ) { ConvertFrom-JSON $_ } }
}


function Update-FBPost( [switch] $IncludeAll, [string] $schema = $SCHEMA_DEFAULT ) {
  <#
    .SYNOPSIS
      Updates information about a collection of posts. Unlike Update-FBPosts, this function accepts data from the pipeline. Howerver, it doesn't provide feedback about the progress of the update process.

    .DESCRIPTION
      Updates information about a collection of posts. Unlike Update-FBPosts, this function accepts data from the pipeline. Howerver, it doesn't provide feedback about the progress of the update process.

    .EXAMPLE
      $UpdatedFBPost     = $NormalizedFacebookPost     | Update-FBPost -IncludeAll
      $UpdatedFBTimeLine = $NormalizedFacebookTimeLine | Update-FBPost -IncludeAll

      $UpdatedFBPost     = $PermaLink                  | Update-FBPost -IncludeAll
      $UpdatedFBTimeLine = $PermaLinksList             | Update-FBPost -IncludeAll

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  begin {
    $LogFileName = "FacebookModule"
    $TimeToWait  = $connections.Facebook.ApiDelay
  }

  process {
    $UpdatedPost                         = [PSCustomObject] @{}
    $SearchByPermalink                   = $false

    if ( $_ -is [string] ) {
      $post                              = New-SMPost -schema $schema

      if ( $_ -ilike "*$($connections.Facebook.DefaultPageName)*" ) {
        $post.NormalizedPost.PermaLink   = $_ -replace $connections.Facebook.DefaultPageName, $connections.Facebook.DefaultPageId
      } else {
        $post.NormalizedPost.PermaLink   = $_
      }

      if ( $_ -ilike "*$CHANNEL_NAME_FACEBOOK*" ) {
        $post.NormalizedPost.ChannelName = $CHANNEL_NAME_FACEBOOK
        $SearchByPermalink               = $true
      } else {
        $post.NormalizedPost.ChannelName = $CHANNEL_NAME_UNKNOWN
      }
    } else {
      $post                              = $_
    }


    if ( $post.NormalizedPost.ChannelName -eq $CHANNEL_NAME_FACEBOOK ) {
      $UpdatedTimeLine                   = Get-RawFBTimeLine -connection $connections.Facebook.connection

      if ( $SearchByPermalink ) {
        $PostFromFacebook                = Search-RawFBPost -text $post.NormalizedPost.PermaLink  -on ([ref] $UpdatedTimeLine) -by permalink
      } else {
        $PostFromFacebook                = Search-RawFBPost -text $post.NormalizedPost.PostDigest -on ([ref] $UpdatedTimeLine)
      }

      if ( $PostFromFacebook  -eq $null ) {
        "$(get-date -format u) [Update-FBPost] - Unable to retrieve post: $( $post.NormalizedPost.PermaLink )" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Warning "[Update-FBPost] - Unable to retrieve post: $( $post.NormalizedPost.PermaLink )"

        return $null
      } else {
        $PostFromFacebook        = $PostFromFacebook | ConvertTo-FBNormalizedPost -IncludeAll
      }
    } else {
      Write-Debug "[Update-FBPost] - Skipping non-Facebook post: $($_.ChannelName)"

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
      Write-Debug "[Update-FBPost] - Current Property Name: $_"

      if ( $post.NormalizedPost.$_ -ne $null ) {
        $CurrentChanges            = Compare-Object $post.NormalizedPost.$_ $PostFromFacebook.NormalizedPost.$_

        if ( $CurrentChanges.Count -ne 0 ) {
          $ChangeLog.TimeStamp     = $UpdatedPost.LastUpdateDate
          $ChangeLog.PropertyName  = $_
          $ChangeLog.OriginalValue = $post.NormalizedPost.$_
          $ChangeLog.NewValue      = $PostFromFacebook.NormalizedPost.$_

          [PSObject[]] $UpdatedPost.ChangeLog += $ChangeLog
        }
      }
    }

    $UpdatedPost.NormalizedPost  = $PostFromFacebook.NormalizedPost
    [PSObject[]] $UpdatedPost.RawObject += $PostFromFacebook.RawObject

    $UpdatedPost
  }
}