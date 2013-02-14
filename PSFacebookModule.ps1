<#
-------------------------------------------------------------------------------
Name:    Social Media Scripting Framework
Module:  Facebook
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


function Get-FBPostById( [string] $PostId, [ref] $TimeLine ) {
  # Get-FBPostById <Facebook-Post-Id> ([ref] $TimeLine)

  foreach ( $post in $TimeLine.Value ) {
    if ( $PostId -eq $post.id.Split("_")[1] ) {
      $post
      break
    }
  }
}


function Get-FBPostByPermaLink( [string] $PermaLink, [ref] $TimeLine ) {
  # Get-FBPostByPermaLink <Facebook-Post-PermaLink> ([ref] $TimeLine)

  foreach ( $post in $TimeLine.Value ) {
    if ( $PermaLink -eq $post.Link ) {
      $post
      break
    }
  }
}


function Get-FBPostAudienceFromPage( [ref] $PageSourceCode ) {
  # $SourceCode = Get-PageSourceCodeFromIE <Facebook-Post-PermaLink>
  # Get-FBPostAudienceFromPage ([ref] $SourceCode)

  [string] $AudiencePattern = '<a href="#">(?<AudienceCount>.*?) people saw this post</a>'

  $AudienceFound            = 0

  if ( $PageSourceCode.Value -match $AudiencePattern ) {
    $AudienceFound = [int] $Matches.AudienceCount.Trim()
  }

  $AudienceFound
}


function Get-FBPostLikesFromPage( [ref] $PageSourceCode ) {
  # $SourceCode = Get-PageSourceCodeFromIE <Facebook-Post-PermaLink>
  # Get-FBPostLikesFromPage ([ref] $SourceCode)

  # [string] $LikesPattern = '"text":"(?<LikesCount>.*?) people like this."'
  [string] $LikesPattern = '"likecount":(?<LikesCount>.*?),'

  $LikesFound            = 0

  if ( $PageSourceCode.Value -match $LikesPattern ) {
    $LikesFound = [int] $Matches.LikesCount.Trim()
  }

  $LikesFound
}


function Get-FBPostCommentsFromPage( [ref] $PageSourceCode ) {
  # $SourceCode = Get-PageSourceCodeFromIE <Facebook-Post-PermaLink>
  # Get-FBPostCommentsFromPage ([ref] $SourceCode)

  [string] $CommentsPattern = '"commentcount":(?<CommentsCount>.*?),'

  $CommentsFound            = 0

  if ( $PageSourceCode.Value -match $CommentsPattern ) {
    $CommentsFound = [int] $Matches.CommentsCount.Trim()
  }

  $CommentsFound
}

# --------------------------------------------------------------------------------------------------


function Get-FBTimeLine( $connection ) {
  Get-FBPost -Connection $connection
}


function Analyze-FBPosts() {
  # Requires a normalized TimeLine
  # $TimeLine | Analyze-FBPosts | format-table -autoSize

  begin {
    [PSObject[]] $BasicMetrics = @()
  }

  process {
    $post           = $_

    $BasicMetrics  += New-Object PSObject -Property @{
      PostId        = $post.PostId
      CommentsCount = $post.comments_count
      LikesCount    = $post.likes_count
      SharesCount   = $post.shares_count
      AudienceCount = $post.audience_count
    }
  }

  end {
    $BasicMetrics
  }
}


function Analyze-FBTimeLine() {
  # Requires a normalized TimeLine
  # $TimeLine | Analyze-FBTimeLine | format-table -autoSize

  begin {
    [PSObject[]] $EngagementMetrics = @()

    $TotalComments = 0
    $TotalLikes    = 0
    $TotalShares   = 0
    $TotalAudience = 0
  }

  process {
    $post           = $_

    $TotalComments += $post.comments_count
    $TotalLikes    += $post.likes_count
    $TotalShares   += $post.shares_count
    $TotalAudience += $post.audience_count
  }

  end {
    New-Object PSObject -Property @{
      TotalComments = $TotalComments
      TotalLikes    = $TotalLikes
      TotalShares   = $TotalShares
      TotalAudience = $TotalAudience
    }
  }
}


function Get-FBTimeLineProspects() {
  # $TimeLine | Get-FBTimeLineProspects | format-table -autoSize

  begin {
    [PSObject[]] $Prospects = @()
  }

  process {
    $post         = $_

    $post.likes | ForEach-Object {
      $Prospects += New-Object PSObject -Property @{
        Name = $_.name
      }
    }

    $post.comments | ForEach-Object {
      $Prospects += New-Object PSObject -Property @{
        Name = $_.from.name
      }
    }
  }

  end {
    $Prospects | Select-Object Name -unique | Sort-Object Name
  }
}


function Analyze-FBTimeLineProspects() {
  # $TimeLine | Analyze-FBTimeLineProspects | format-table -autoSize

  begin {
    $ProspectsStats = @{}
  }

  process {
    $post = $_

    foreach ( $LikeInfo in $post.likes ) {
      if ( $LikeInfo.Name -ne $null ) {
        if ( $ProspectsStats.ContainsKey( $LikeInfo.Name ) ) {
          $ProspectsStats.$($LikeInfo.Name).Likes += 1
        } else {
          $ProspectsStats.Add( $LikeInfo.Name, @{ Likes = 1; Comments = 0 } )
        }
      }
    }

    foreach ( $CommentInfo in $post.comments ) {
      if ( $CommentInfo.from.name -ne $null ) {
        if ( $ProspectsStats.ContainsKey( $CommentInfo.from.name ) ) {
          $ProspectsStats.$($CommentInfo.from.name).Comments += 1
        } else {
          $ProspectsStats.Add( $CommentInfo.from.name, @{ Likes = 0; Comments = 1 } )
        }
      }
    }
  }

  end {
    [PSObject[]] $Prospects = @()

    $ProspectsStats.Keys | ForEach-Object {
      $Prospects += New-Object PSObject -Property @{
        Name     = $_
        Likes    = $ProspectsStats["$_"].Likes
        Comments = $ProspectsStats["$_"].Comments
      }
    }

    $Prospects
  }
}


function Normalize-FBTimeLine( [PSObject[]] $TimeLine, [switch] $IncludeAll ) {
  # $TimeLine = Normalize-FBTimeLine $FBPosts -IncludeAll

  # $DebugPreference = "Continue"

  [PSObject[]] $NewTimeLine = @()
  $TimeToWait               = 5
  $i                        = 1


  $TimeLine | ForEach-Object {
    $NewPost                = $_

    if ( $IncludeAll ) {
      Write-Progress -Activity "Normalizing Information ..." -Status "Progress: $i / $($TimeLine.Count) - ETC: $( (( $TimeLine.Count - $i ) * $TimeToWait ) / 60 ) minutes - Time Elapsed: $( (( $i - 1 ) * $TimeToWait ) / 60 ) minutes" -PercentComplete ( ( $i / $TimeLine.Count ) * 100 )
    } else {
      Write-Progress -Activity "Normalizing Information ..." -Status "Progress: $i / $($TimeLine.Count)" -PercentComplete ( ( $i / $TimeLine.Count ) * 100 )
    }

    Write-Debug ".user not exists:           $( $NewTweet.user -eq $null )"

    if ( $NewPost.user -eq $null ) {
      $NewPost | Add-Member -NotePropertyName user           -NotePropertyValue "$($NewPost.from.name)"
    } else {
      $NewPost.user = $NewPost.from.name
    }

    Write-Debug ".PostPermaLink not exists:  $( $NewTweet.PostPermaLink -eq $null )"

    if ( $NewPost.PostPermaLink -eq $null ) {
      if ( $NewPost.link -match "photo.php" ) {
        $NewPost | Add-Member -NotePropertyName PostPermaLink  -NotePropertyValue "$($NewPost.link)"
      } else {
        $NewPost | Add-Member -NotePropertyName PostPermaLink  -NotePropertyValue "$($NewPost.actions[0].link)"
      }
    } else {
      if ( $NewPost.link -match "photo.php" ) {
        $NewPost.PostPermaLink = $NewPost.link
      } else {
        $NewPost.PostPermaLink = $NewPost.actions[0].link
      }
    }

    Write-Debug ".PostPrivacy not exists:    $( $NewTweet.PostPrivacy -eq $null )"

    if ( $NewPost.PostPrivacy -eq $null ) {
      $NewPost | Add-Member -NotePropertyName PostPrivacy    -NotePropertyValue "$($NewPost.privacy.description)"
    } else {
      $NewPost.PostPrivacy   = $NewPost.privacy.description
    }


    $SourceCode              = Get-PageSourceCodeFromIE $NewPost.PostPermaLink


    Write-Debug ".likes_count not exists:    $( $NewTweet.likes_count -eq $null )"

    if ( $NewPost.likes_count -eq $null ) {
      $NewPost | Add-Member -NotePropertyName likes_count    -NotePropertyValue $( Get-FBPostLikesFromPage    ([ref] $SourceCode) )
    } else {
      $NewPost.likes_count   = $( Get-FBPostLikesFromPage    ([ref] $SourceCode) )
    }

    Write-Debug ".comments_count not exists: $( $NewTweet.comments_count -eq $null )"

    if ( $NewPost.comments_count -eq $null ) {
      $NewPost | Add-Member -NotePropertyName comments_count -NotePropertyValue $( Get-FBPostCommentsFromPage ([ref] $SourceCode) )
    } else {
      $NewPost.comments_count = $( Get-FBPostCommentsFromPage ([ref] $SourceCode) )
    }

    Write-Debug ".shares_count not exists:   $( $NewTweet.shares_count -eq $null )"

    if ( $NewPost.shares.count -eq $null ) {
      if ( $NewPost.shares_count -eq $null ) {
        $NewPost | Add-Member -NotePropertyName shares_count -NotePropertyValue 0
      } else {
        $NewPost.shares_count = 0
      }
    } else {
      if ( $NewPost.shares_count -eq $null ) {
        $NewPost | Add-Member -NotePropertyName shares_count -NotePropertyValue $($NewPost.shares.count)
      } else {
        if ( $NewPost.shares_count -lt $NewPost.shares.count ) {
          $NewPost.shares_count = $NewPost.shares.count
        }
      }
    }

    Write-Debug "[INFO] user:                $($NewPost.user)"
    Write-Debug "[INFO] PostPermaLink:       $($NewPost.PostPermaLink)"
    Write-Debug "[INFO] PostPrivacy:         $($NewPost.PostPrivacy)"
    Write-Debug "[INFO] likes_count:         $($NewPost.likes_count)"
    Write-Debug "[INFO] comments_count:      $($NewPost.comments_count)"
    Write-Debug "[INFO] shares_count:        $($NewPost.shares_count)"
    Write-Debug "[INFO] shares.count:        $($NewPost.shares.count)"

    if ( $IncludeAll ) {
      if ( $IncludeAll ) {
        Write-Progress -Activity "Retrieving Audience ..." -Status "Progress: $i / $($TimeLine.Count) - ETC: $( (( $TimeLine.Count - $i ) * $TimeToWait ) / 60 ) minutes - Time Elapsed: $( (( $i - 1 ) * $TimeToWait ) / 60 ) minutes" -PercentComplete ( ( $i / $TimeLine.Count ) * 100 )
      } else {
        Write-Progress -Activity "Retrieving Audience ..." -Status "Progress: $i / $($TimeLine.Count)" -PercentComplete ( ( $i / $TimeLine.Count ) * 100 )
      }

      Write-Debug ".audience_count not exists: $( $NewTweet.audience_count -eq $null )"

      if ( $NewPost.audience_count -eq $null ) {
        $NewPost | Add-Member -NotePropertyName audience_count -NotePropertyValue $( Get-FBPostAudienceFromPage ([ref] $SourceCode) )
      } else {
        $NewPost.audience_count = $( Get-FBPostAudienceFromPage ([ref] $SourceCode) )
      }

      Write-Debug "[INFO] audience_count:      $($NewPost.audience_count)"
    }

    Start-Sleep -Seconds $TimeToWait

    $NewTimeLine += $NewPost
    $i++
  }

  # $DebugPreference = "SilentlyContinue"

  $NewTimeLine
}


function Rebuild-FBTimeLine( [PSObject[]] $from ) {
  [PSObject[]] $TimeLine = @()
  $TimeToWait            = 6
  $i                     = 1

  Write-Host -foregroundcolor $COLOR_BRIGHT "     INFO: Retrieving page Time Line"
  $FBPosts               = Get-FBTimeLine -connection $FBPageConnection

  Write-Host -foregroundcolor $COLOR_BRIGHT "     INFO: Retrieving page Photos"
  $FBPhotos              = Get-FBPhoto -AllAlbums -connection $FBPageConnection

  $from | ForEach-Object {
    if ( $SourceSchema.count -eq 0 ) {
      $SourceSchema      = $_ | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }
      $PropertyName      = GetMatchesInCollection "PermaLink" $SourceSchema
    }

    if ( $_.$PropertyName -match "facebook.com" ) {
      $PostFound   = $false

      if ( $_.$PropertyName -match "photo.php" ) {
        for ( $i = 0; $i -lt $FBPhotos.Length; $i++ ) {
          if ( $_.$PropertyName -eq $FBPhotos[$i].link ) {
            $TimeLine   += $FBPhotos[$i]
            $PostFound   = $true

            if ( $i -eq 0 )                                                  { $FBPhotos = $FBPhotos[1..($FBPhotos.Length)]     }
            elseif ( $i -eq ( $FBPhotos.Length - 1 ) )                       { $FBPhotos = $FBPhotos[0..($FBPhotos.Length - 2)] }
            elseif ( ( $i -gt 0 ) -and ( $i -ne ( $FBPhotos.Length - 1 ) ) ) { $FBPhotos = $FBPhotos[0..($i - 1) + ($i + 1)..($FBPhotos.Length - 1)] }
          }
        }
      } else {
        for ( $i = 0; $i -lt $FBPosts.Length; $i++ ) {
          if ( $_.$PropertyName.Split("/")[($_.$PropertyName.Split("/").Length - 1)] -eq $FBPosts[$i].id.Split("_")[1] ) {
            $TimeLine   += $FBPosts[$i]
            $PostFound   = $true

            if ( $i -eq 0 )                                                 { $FBPosts = $FBPosts[1..($FBPosts.Length)]     }
            elseif ( $i -eq ( $FBPosts.Length - 1 ) )                       { $FBPosts = $FBPosts[0..($FBPosts.Length - 2)] }
            elseif ( ( $i -gt 0 ) -and ( $i -ne ( $FBPosts.Length - 1 ) ) ) { $FBPosts = $FBPosts[0..($i - 1) + ($i + 1)..($FBPosts.Length - 1)] }
          }
        }
      }

      if ( !$PostFound ) {
        Write-Host -foregroundcolor $COLOR_BRIGHT "     INFO: unable to find post:        $($_.$PropertyName)"
      }
    } else {
      Write-Host -foregroundcolor $COLOR_NORMAL$ "     INFO: Skipping non-Facebook post: $($_.$PropertyName)"
    }
  }

  $TimeLine
}