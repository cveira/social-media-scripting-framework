<#
-------------------------------------------------------------------------------
Name:    Social Media Scripting Framework
Module:  LinkedIn
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


function Get-LINGroupPostLikesFromPage( [ref] $PageSourceCode ) {
  # $SourceCode = Get-PageSourceCodeFromIE <LinkedIn-Group-Post-PermaLink>
  # Get-LINGroupPostLikesFromPage ([ref] $SourceCode)

  [string] $AtLeastOneLike  = 'first liker'
  [string] $AtLeastTwoLikes = 'second liker'
  [string] $RemainingLikes  = '(?s)<a[^>]*all-likers-discussion[^>]*>(?<RemainingLikes>.*?)</a>'

  $LikesFound               = 0

  if ( $PageSourceCode.Value -match $AtLeastTwoLikes ) {
    $LikesFound = 2

    if ( $PageSourceCode.Value -match $RemainingLikes ) {
      $LikesFound += [int] $Matches.RemainingLikes.Split(" ")[0]
    }
  } elseif ( $PageSourceCode.Value -match $AtLeastOneLike ) {
    $LikesFound = 1
  }

  $LikesFound
}


function Get-LINGroupPostCommentsFromPage( [ref] $PageSourceCode ) {
  # $SourceCode = Get-PageSourceCodeFromIE <LinkedIn-Group-Post-PermaLink>
  # Get-LINGroupPostCommentsFromPage ([ref] $SourceCode)

  [string] $CommentsPattern = '(?s)<p[^>]*last-comment[^>]*><span[^>]*count[^>]*>(?<CommentsCount>.*?)</span>'

  $CommentsFound            = 0

  if ( $PageSourceCode.Value -match $CommentsPattern ) {
    $CommentsFound += [int] $Matches.CommentsCount.Split(" ")[0]
  }

  $CommentsFound
}


function Get-LINGroupPostsFromPage( [ref] $PageSourceCode ) {
  # $SourceCode = Get-PageSourceCodeFromIE <LinkedIn-Group-PermaLink>
  # Get-LINGroupPostsFromPage ([ref] $SourceCode)
  # NOTE: LinkedIn Groups only return 15 posts per page

  [string]   $PostTitlePattern     = '(?s)<h3[^>]*groups[^>]*>.*?<a[^>]*[^>]*>(?<PostTitle>.*?)</a>'
  [RegEx]    $PostTitleListPattern = '(?s)(<h3[^>]*groups[^>]*>.*?<a[^>]*[^>]*>.*?</a>)+'
  [string[]] $PostTitles           = @()


  $CurrentMatch      =  $PostTitleListPattern.match($PageSourceCode.Value)

  if (!$CurrentMatch.Success) {
    $PostTitles      += "N/D"
  } else {
    while ($CurrentMatch.Success) {
      if ( $CurrentMatch.Value -match $PostTitlePattern ) {
        $PostTitles  += $Matches.PostTitle
      } else {
        $PostTitles  += "N/D"
      }

      $CurrentMatch  =  $CurrentMatch.NextMatch()
    }
  }

  $PostTitles
}


function Get-LINCompanyPostsFromPage( [ref] $PageSourceCode ) {
  # $SourceCode = Get-PageSourceCodeFromIE <LinkedIn-CompanyPage-PermaLink>
  # $CorporatePosts = Get-LINCompanyPostsFromPage ([ref] $SourceCode)
  # $CorporatePosts | Format-List Title, Description, Likes, Comments, EngagementMetrics

  # NOTE: LinkedIn All Activity Page returns: 14 posts

  [string]   $PostTitlePattern          = '(?s)<p[^>]*share-title[^>]*>.*?<a[^>]*[^>]*>(?<PostTitle>.*?)</a>'
  [string]   $PostDescriptionPattern    = '(?s)<p[^>]*share-desc[^>]*>(?<PostDescription>.*?)</p>'
  [string]   $PostLikesPattern          = 'data-li-num-liked="(?<PostLikesCount>.*?)"'
  [string]   $PostCommentsPattern       = '(?s)Comment.*?\(<span>(?<PostCommentsCount>.*?)</span>\)'
  [string]   $PostMetricsPattern        = '(?s)<span[^>]*[^>]*><span[^>]*engage[^>]*>(?<PostMetricValue>.*?)</span>(?<PostMetricName>.*?)</span>'

  [RegEx]    $PostListPattern           = '(?s)(<li[^>]*feed-item[^>]*>.*?</li>.*?<li[^>]*feed-item[^>]*>)+'
  [RegEx]    $PostEngagementListPattern = '(?s)(<span[^>]*[^>]*><span[^>]*engage[^>]*>.*?</span>.*?</span>)+'           # When present, 4 entries per post: impressions, clicks, shares, engagement

  [PSObject[]] $PostData                = @()

  $CurrentMatch      =  $PostListPattern.match($PageSourceCode.Value)

  if (!$CurrentMatch.Success) {
    [PSObject[]] $PostData              = @()
  } else {
    while ($CurrentMatch.Success) {
      $CurrentPost  = New-Object PSObject -Property @{
        RawContent        =  $CurrentMatch.Value
        Title             =  ""
        Description       =  ""
        Likes             =  0
        Comments          =  0
        EngagementMetrics =  @{ Impressions = 0; Clicks = 0; Shares = 0; Engagement = 0 }
      }

      if ( $CurrentMatch.Value -match $PostTitlePattern       ) { $CurrentPost.Title       = $Matches.PostTitle.Trim()        }
      if ( $CurrentMatch.Value -match $PostDescriptionPattern ) { $CurrentPost.Description = $Matches.PostDescription.Trim()  }
      if ( $CurrentMatch.Value -match $PostLikesPattern       ) { $CurrentPost.Likes       = [int] $Matches.PostLikesCount    }
      if ( $CurrentMatch.Value -match $PostCommentsPattern    ) { $CurrentPost.Comments    = [int] $Matches.PostCommentsCount }

      $CurrentPostMetricsMatch = $PostEngagementListPattern.match($CurrentMatch.Value)

      if ($CurrentPostMetricsMatch.Success) {
        while ($CurrentPostMetricsMatch.Success) {
          if ( $CurrentPostMetricsMatch.Value -match $PostMetricsPattern ) {
            $CurrentPost.EngagementMetrics.$($Matches.PostMetricName.Trim()) = $Matches.PostMetricValue
          }

          $CurrentPostMetricsMatch = $CurrentPostMetricsMatch.NextMatch()
        }
      }

      $PostData           += $CurrentPost

      $CurrentMatch       =  $CurrentMatch.NextMatch()
    }
  }

  $PostData
}


function Rebuild-LINTimeLine( [PSObject[]] $from ) {
  [PSObject[]] $TimeLine = @()
  $TimeToWait            = 6
  $i                     = 1
  $ExecutionTime         = [Diagnostics.Stopwatch]::StartNew()

  $from | ForEach-Object {
    if ( $SourceSchema.count -eq 0 ) {
      $SourceSchema      = $_ | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }
      $PropertyName      = GetMatchesInCollection "PermaLink" $SourceSchema
    }

    $ExecutionTime.Stop()

    Write-Progress -Activity "Retrieving tweets ..." -Status "Progress: $i / $($from.Count) - ETC: $( '{0:#0.00}' -f (( $from.Count - $i ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes - Time Elapsed: $( '{0:#0.00}' -f (( $i - 1 ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes" -PercentComplete ( ( $i / $from.Count ) * 100 )

    $ExecutionTime       = [Diagnostics.Stopwatch]::StartNew()

    if ( $_.$PropertyName -match "linkedin.com" ) {
      if ( $_.$PropertyName -match "group" ) {
        $SourceCode      = Get-PageSourceCodeFromIE $_.$PropertyName

        $TimeLine       += New-Object PSObject -Property @{
          PermaLink      = $_.$PropertyName
          likes_count    = Get-LINGroupPostLikesFromPage ([ref] $SourceCode)
          comments_count = Get-LINGroupPostCommentsFromPage ([ref] $SourceCode)
        }
      } else {
        Write-Host -foregroundcolor $COLOR_NORMAL "     INFO: Skipping non-group post: $($_.$PropertyName)"
      }

      Start-Sleep -Seconds $TimeToWait
    } else {
      Write-Host -foregroundcolor $COLOR_BRIGHT "     INFO: Skipping non-LinkedIn post: $($_.$PropertyName)"
    }

    $i++
  }

  $TimeLine
}