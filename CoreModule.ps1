$COLOR_PROMPT               = 'Magenta'
$COLOR_BRIGHT               = 'Yellow'
$COLOR_DARK                 = 'DarkGray'
$COLOR_RESULT               = 'Green' # 'DarkCyan'
$COLOR_NORMAL               = 'White'
$COLOR_ERROR                = 'Red'
$COLOR_ENPHASIZE            = 'Magenta'

$PRIVACY_LEVEL_NONE         = 0
$PRIVACY_LEVEL_LOW          = 1
$PRIVACY_LEVEL_MEDIUM       = 2
$PRIVACY_LEVEL_HIGH         = 3

$VALUE_NA                   = "N/A"



[Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("System.Net")      | Out-Null


function New-SMSessionId() {
  <#
    .SYNOPSIS
      Returns a new unique Session Id.

    .DESCRIPTION
      Returns a new unique Session Id.

    .EXAMPLE
      $SessionId = New-SMSessionId

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  $SessionId     = Get-Date
  $SessionId     = "$($SessionId.Year)$($SessionId.Month)$($SessionId.Day)-$($SessionId.Hour)$($SessionId.Minute)-$($SessionId.Second)-$($SessionId.Millisecond)"

  $SessionId
}


function New-SMSessionStore( [string] $name = "session", [string] $SessionId = $( New-SMSessionId ) ) {
  <#
    .SYNOPSIS
      Creates and returns a new Session Store using a Name and a Session Id.

    .DESCRIPTION
      Creates and returns a new Session Store using a Name and a Session Id.

    .EXAMPLE
      New-SMSessionStore
      New-SMSessionStore -Sessionid "20131214-133-6-304" -name "MyCampaign"

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  if ( $name -eq "session" ) {
    New-Item $CurrentHomeDir\$name-$SessionId -type directory -force | Out-Null

    "$CurrentHomeDir\$name-$SessionId"
  } else {
    New-Item $CurrentHomeDir\$name            -type directory -force | Out-Null

    "$CurrentHomeDir\$name"
  }
}


function Get-SMSessionStores( [string] $name = "session" ) {
  <#
    .SYNOPSIS
      Returns the existing Session Stores under the current active profile.

    .DESCRIPTION
      Returns the existing Session Stores under the current active profile.

    .EXAMPLE
      Get-SMSessionStores

    .NOTES
      High-level function.

    .LINK
      N/A
  #>

  ( Get-ChildItem $CurrentHomeDir\$name-* | Where-Object { $_.PSIsContainer } ).Name
}


function Remove-SMSessionStores( [string] $name = "session", [switch] $EmptyOnly ) {
  <#
    .SYNOPSIS
      Removes Session Stores under the current active profile.

    .DESCRIPTION
      Removes Session Stores under the current active profile. Useful to clean up Stores that are no longer used.

    .EXAMPLE
      Remove-SMSessionStores
      Remove-SMSessionStores -EmptyOnly
      Remove-SMSessionStores -name "MyOldCampaign"

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  ( Get-ChildItem $CurrentHomeDir\$name-* | Where-Object { $_.PSIsContainer } ).Name | ForEach-Object {
    if ( $EmptyOnly ) {
      if ( ( Get-ChildItem $CurrentHomeDir\$_ ).count -eq 0 ) { Remove-Item $CurrentHomeDir\$_ -force | Out-Null }
    } else {
      Remove-Item $CurrentHomeDir\$_ -recurse -force | Out-Null
    }
  }
}


function Set-SMProfile( [string] $name = "" ) {
  <#
    .SYNOPSIS
      Loads an activates new configuration and execution profile.

    .DESCRIPTION
      Loads an activates new configuration and execution profile.

    .EXAMPLE
      Set-SMProfile
      Set-SMProfile -name "cveira"

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  if ( $name -eq "" ) {
    $name = $DefaultProfileName
  }

  if ( Test-Path $ProfilesDir\$name ) {
    Set-Location $ProfilesDir

    $CurrentProfileName         = $name
    $CurrentProfileDir          = $ProfilesDir       + "\" + $name
    $CurrentHomeDir             = $CurrentProfileDir + "\home"
    $CurrentLogsDir             = $CurrentProfileDir + "\logs"
    $CurrentCacheDir            = $CurrentProfileDir + "\cache"
    $FeedsCacheDir              = $CurrentCacheDir   + "\feeds"

    Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "  + Loading Profile... "

    ( Get-ChildItem $CurrentProfileDir\*.ps1 ).Name | ForEach-Object { . $CurrentProfileDir\$_ }

    $connections = $channels | ConvertFrom-JSON

    Write-Host -foregroundcolor $COLOR_BRIGHT "done"

    Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "  + Checking Configuration Settings... "

    Test-SMSettings

    Write-Host -foregroundcolor $COLOR_BRIGHT "done"

    Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "  + Connecting to Social Networks... "

    if ( $connections.Facebook.AccessToken -ne '<AccessToken>' ) {
      $connections.Facebook.connection = New-FBConnection -AccessToken $connections.Facebook.AccessToken
    }

    Write-Host -foregroundcolor $COLOR_BRIGHT "done"

    Write-Host -foregroundcolor $COLOR_NORMAL -noNewLine "  + Creating a Session Environment... "

    . Initialize-RawLINApiQuotaStatus

    Remove-SMSessionStores -EmptyOnly

    if ( $ForcedSessionId -eq "") {
      $CurrentSessionId    = New-SMSessionId
    } else {
      $CurrentSessionId    = $ForcedSessionId
    }

    if ( $DefaultSessionStore -eq "") {
      $CurrentSessionStore = New-SMSessionStore -SessionId $CurrentSessionId
    } else {
      $CurrentSessionStore = New-SMSessionStore -name $DefaultSessionStore
    }

    Write-Host -foregroundcolor $COLOR_BRIGHT "done"

    Set-Location $CurrentSessionStore
  }
}


function Test-SMSettings() {
  <#
    .SYNOPSIS
      Verifies Social Media connection settings under the current profile.

    .DESCRIPTION
      Verifies Social Media connection settings under the current profile.

    .EXAMPLE
      Test-SMSettings

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  $TwitterSettingsHelp = @"

      HOW TO: Setup up your Twitter Credentials
      -------------------------------------------------------------------------------------------
      Step 1: Register SMSF as one of your Twitter applications in https://dev.twitter.com/apps
      Step 2: Update your Access Token if necessary.
      Step 3: Edit the file 'SMSF-security.ps1' and update each setting with the correct values.
      -------------------------------------------------------------------------------------------
"@


  $FacebookSettingsHelp = @"

      HOW TO: Set up your Facebook Credentials
      -------------------------------------------------------------------------------------------
      Step 1: Download and install the 'Facebook PowerShell Module' from:
        http://facebookpsmodule.codeplex.com/
      Step 2: Open a PowerShell console in STA mode:
        C:\> powershell.exe -STA
      Step 3: Run the following command:
        PS C:\> New-FBConnection
      Step 4: Introduce your Facebook credentials on the pop-up window.
        NOTE: Select the 'Keep me logged in' option!
      Step 5: Run the following commands:
        PS C:\> Get-FBPage | Select name, PageId, category | Format-Table -AutoSize
      Step 6: Select/Copy the PageId of the Page you want to operate in.
      Step 7: Edit the file 'SMSF-security.ps1' and update the 'FBDefaultPageId' value accordingly.
      Step 8: Run the following command:
        PS C:\> ( New-FBConnection -PageId <YourPageId> -ExtendToken ).AccessToken
      Step 9: Edit the file 'SMSF-security.ps1' and update the 'FBAccessToken' value accordingly.
      -------------------------------------------------------------------------------------------
"@


  if ( ( $connections.Twitter.ConsumerKey -eq "" ) -or ( $connections.Twitter.ConsumerSecret    -eq "" ) -or
       ( $connections.Twitter.AccessToken -eq "" ) -or ( $connections.Twitter.AccessTokenSecret -eq "" ) )    {

    Write-Host -foregroundcolor $COLOR_ERROR  "    + ERROR: Twitter credentials are not defined correctly."
    Write-Host -foregroundcolor $COLOR_NORMAL $TwitterSettingsHelp
  }


  if ( ( Get-Command -Module Facebook ) -eq $null ) {
    Write-Host -foregroundcolor $COLOR_ERROR  "    + ERROR: the 'Facebook PowerShell Module' is not installed correctly."
    Write-Host -foregroundcolor $COLOR_NORMAL $FacebookSettingsHelp
  }

  if ( $connections.Facebook.AccessToken -eq "" ) {
    Write-Host -foregroundcolor $COLOR_ERROR  "    + ERROR: Facebook credentials are not defined correctly."
    Write-Host -foregroundcolor $COLOR_NORMAL $FacebookSettingsHelp
  }
}


function New-SMPost( [string] $schema = $SCHEMA_DEFAULT ) {
  <#
    .SYNOPSIS
      Creates a new normalized and empty instance of a Social Media Post Object.

    .DESCRIPTION
      Creates a new normalized and empty instance of a Social Media Post Object.

    .EXAMPLE
      New-SMPost

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  $SMPost                  = New-Object PSObject -Property $SNPostMap.$schema

  $SMPost.OwnerId          = $DataSetOwnerId
  $SMPost.OwnerDisplayName = $DataSetOwnerDisplayName

  # Workaround to guarantee that $DefaultDateFormat is actually enforced
  $SMPost.CreationDate     = Get-Date -format $DefaultDateFormat
  $SMPost.LastUpdateDate   = Get-Date -format $DefaultDateFormat
  $SMPost.RetainUntilDate  = Get-Date -format $DefaultDateFormat

  $SMPost
}


function New-SMUser( [string] $schema = $SCHEMA_DEFAULT ) {
  <#
    .SYNOPSIS
      Creates a new normalized and empty instance of a Social Media User Object.

    .DESCRIPTION
      Creates a new normalized and empty instance of a Social Media User Object.

    .EXAMPLE
      New-SMUser

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  $SMUser                  = New-Object PSObject -Property $SNUserMap.$schema

  $SMUser.OwnerId          = $DataSetOwnerId
  $SMUser.OwnerDisplayName = $DataSetOwnerDisplayName

  # Workaround to guarantee that $DefaultDateFormat is actually enforced
  $SMUser.CreationDate     = Get-Date -format $DefaultDateFormat
  $SMUser.LastUpdateDate   = Get-Date -format $DefaultDateFormat
  $SMUser.RetainUntilDate  = Get-Date -format $DefaultDateFormat

  $SMUser
}


function New-SMUserDigitalProfile( [string] $schema = $SCHEMA_DEFAULT ) {
  <#
    .SYNOPSIS
      Creates a new normalized and empty instance of a Social Media User Digital Profile Object.

    .DESCRIPTION
      Creates a new normalized and empty instance of a Social Media User Digital Profile Object.

    .EXAMPLE
      New-SMUserDigitalProfile

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  $DigitalProfile                  = New-Object PSObject -Property $DigitalProfileMap.$schema

  $DigitalProfile.OwnerId          = $DataSetOwnerId
  $DigitalProfile.OwnerDisplayName = $DataSetOwnerDisplayName

  # Workaround to guarantee that $DefaultDateFormat is actually enforced
  $DigitalProfile.CreationDate     = Get-Date -format $DefaultDateFormat
  $DigitalProfile.LastUpdateDate   = Get-Date -format $DefaultDateFormat
  $DigitalProfile.RetainUntilDate  = Get-Date -format $DefaultDateFormat

  $DigitalProfile
}


function Get-SMPostDigest( [string] $PostContent = "" ) {
  <#
    .SYNOPSIS
      Computes a hash/digest string that uniquely represents the content provided.

    .DESCRIPTION
      Computes a hash/digest string that uniquely represents the content provided. Used to artificially compute a unique id for any post.

    .EXAMPLE
      Get-SMPostDigest -PostContent $Title

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  if ( $PostContent -ne "" ) {
    $Hasher       = New-Object System.Security.Cryptography.HMACSHA1
    $Hasher.Key   = [System.Text.Encoding]::ASCII.GetBytes($HashingMasterKey)

    $SMPostDigest = [System.Convert]::ToBase64String($Hasher.ComputeHash([System.Text.Encoding]::ASCII.GetBytes($PostContent)))

    $SMPostDigest
  } else {
    $VALUE_NA
  }
}


function Measure-SMPostTopics( [string] $by ) {
  <#
    .SYNOPSIS
      Counts how many posts in a Normalized Time Line are associated with a given Label, Category or Keyword.

    .DESCRIPTION
      Counts how many posts in a Normalized Time Line are associated with a given Label, Category or Keyword.

    .EXAMPLE
      $posts.NormalizedPost | Measure-SNPostTopics -by tags
      $posts.NormalizedPost | Measure-SNPostTopics -by category
      $posts.NormalizedPost | Measure-SNPostTopics -by keyword

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  begin {
    $Topics               = @{}
    [PSObject[]] $ranking = @()

    switch ( $by.ToLower() ) {
      "tags"     { $PropertyName = "Tags"       }
      "category" { $PropertyName = "Categories" }
      "keyword"  { $PropertyName = "Keywords"   }
    }
  }

  process {
    $post = $_

    $post.$PropertyName | ForEach-Object {
      if ( $Topics.ContainsKey("$_") ) {
        $Topics["$_"] = $Topics["$_"] + 1
      } else {
        $Topics.Add("$_", 1)
      }
    }
  }

  end {
    $Topics.keys | ForEach-Object {
      $ranking += New-Object PSObject -Property @{
        $PropertyName = $_
        Count         = $Topics.$_
      }
    }

    $ranking
  }
}


function Measure-SMPostConnections( [string] $by ) {
  <#
    .SYNOPSIS
      Counts how many users in a Normalized Time Line are associated with a given engagement property.

    .DESCRIPTION
      Counts how many users in a Normalized Time Line are associated with a given engagement property.

    .EXAMPLE
      $posts.PostConnections | Measure-SMPostConnections -by UserId
      $posts.PostConnections | Measure-SMPostConnections -by UserDisplayName
      $posts.PostConnections | Measure-SMPostConnections -by Location
      $posts.PostConnections | Measure-SMPostConnections -by EngagementType
      $posts.PostConnections | Measure-SMPostConnections -by CompoundReputationIndex
      $posts.PostConnections | Measure-SMPostConnections -by KloutScore
      $posts.PostConnections | Measure-SMPostConnections -by KredInfluenceScore
      $posts.PostConnections | Measure-SMPostConnections -by KredOutreachScore
      $posts.PostConnections | Measure-SMPostConnections -by PeerIndex
      $posts.PostConnections | Measure-SMPostConnections -by TrustCloudScore

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  begin {
    $Connections          = @{}
    [PSObject[]] $ranking = @()

    switch ( $by.ToLower() ) {
      "UserId"                  { $PropertyName = "UserId"                  }
      "UserDisplayName"         { $PropertyName = "UserDisplayName"         }
      "Location"                { $PropertyName = "Location"                }
      "EngagementType"          { $PropertyName = "EngagementType"          }
      "CompoundReputationIndex" { $PropertyName = "CompoundReputationIndex" }
      "KloutScore"              { $PropertyName = "KloutScore"              }
      "KredInfluenceScore"      { $PropertyName = "KredInfluenceScore"      }
      "KredOutreachScore"       { $PropertyName = "KredOutreachScore"       }
      "PeerIndex"               { $PropertyName = "PeerIndex"               }
      "TrustCloudScore"         { $PropertyName = "TrustCloudScore"         }
    }
  }

  process {
    $post = $_

    $post.$PropertyName | ForEach-Object {
      if ( $Connections.ContainsKey("$_") ) {
        $Connections["$_"] = $Connections["$_"] + 1
      } else {
        $Connections.Add("$_", 1)
      }
    }
  }

  end {
    $Connections.keys | ForEach-Object {
      $ranking += New-Object PSObject -Property @{
        $PropertyName  = $_
        Count          = $Connections.$_
      }
    }

    $ranking
  }
}


function Measure-SMPostProspects() {
  <#
    .SYNOPSIS
      Returns information about users in a Normalized Time Line that have had any sort of interaction with the content shared on that Time Line.

    .DESCRIPTION
      Returns information about users in a Normalized Time Line that have had any sort of interaction with the content shared on that Time Line.

    .EXAMPLE
      $posts.PostConnections | Measure-SMPostProspects

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  begin {
    $Connections          = @{}
    [PSObject[]] $ranking = @()
  }

  process {
    $post = $_

    $post | ForEach-Object {
      if ( $Connections.ContainsKey("($_.UserDisplayName)") ) {
        switch ( $_.EngagementType ) {
          $ENGAGEMENT_TYPE_INTERACTION {
            $Connections["($_.UserDisplayName)"].Interactions += 1
          }

          $ENGAGEMENT_TYPE_INTEREST {
            $Connections["($_.UserDisplayName)"].Interest     += 1
          }

          $ENGAGEMENT_TYPE_UNKNOWN {
            $Connections["($_.UserDisplayName)"].Unknown      += 1
          }
        }
      } else {
        switch ( $_.EngagementType ) {
          $ENGAGEMENT_TYPE_INTERACTION {
            $Connections.Add("($_.UserDisplayName)", @{ Interactions = 1; Interest = 0; Unknown = 0 ; KloutScore = $_.KloutScore ; KredInfluenceScore = $_.KredInfluenceScore ; KredOutreachScore = $_.KredOutreachScore ; PeerIndex = $_.PeerIndex ; TrustCloudScore = $_.TrustCloudScore ; CompoundReputationIndex = $_.CompoundReputationIndex ; Location = $_.Location })
          }

          $ENGAGEMENT_TYPE_INTEREST {
            $Connections.Add("($_.UserDisplayName)", @{ Interactions = 0; Interest = 1; Unknown = 0 ; KloutScore = $_.KloutScore ; KredInfluenceScore = $_.KredInfluenceScore ; KredOutreachScore = $_.KredOutreachScore ; PeerIndex = $_.PeerIndex ; TrustCloudScore = $_.TrustCloudScore ; CompoundReputationIndex = $_.CompoundReputationIndex ; Location = $_.Location })
          }

          $ENGAGEMENT_TYPE_UNKNOWN {
            $Connections.Add("($_.UserDisplayName)", @{ Interactions = 0; Interest = 0; Unknown = 1 ; KloutScore = $_.KloutScore ; KredInfluenceScore = $_.KredInfluenceScore ; KredOutreachScore = $_.KredOutreachScore ; PeerIndex = $_.PeerIndex ; TrustCloudScore = $_.TrustCloudScore ; CompoundReputationIndex = $_.CompoundReputationIndex ; Location = $_.Location })
          }
        }
      }
    }
  }

  end {
    $Connections.keys | ForEach-Object {
      $ranking += New-Object PSObject -Property @{
        ProspectName            = $_
        InteractionsCount       = $Connections["$_"].Interactions
        InterestCount           = $Connections["$_"].Interest
        UnknownCount            = $Connections["$_"].Unknown
        KloutScore              = $Connections["$_"].KloutScore
        KredInfluenceScore      = $Connections["$_"].KredInfluenceScore
        KredOutreachScore       = $Connections["$_"].KredOutreachScore
        PeerIndex               = $Connections["$_"].PeerIndex
        TrustCloudScore         = $Connections["$_"].TrustCloudScore
        CompoundReputationIndex = $Connections["$_"].CompoundReputationIndex
        Location                = $Connections["$_"].Location
      }
    }

    $ranking
  }
}


function Measure-SMPostTimeProfile( [string] $by = 'month' ) {
  <#
    .SYNOPSIS
      Returns information about the publishing time profile in a Normalized Time Line.

    .DESCRIPTION
      Returns information about the publishing time profile in a Normalized Time Line.

    .EXAMPLE
      $posts.NormalizedPost | Measure-SMPostTimeProfile -by dayofweek
      $posts.NormalizedPost | Measure-SMPostTimeProfile -by day
      $posts.NormalizedPost | Measure-SMPostTimeProfile -by month
      $posts.NormalizedPost | Measure-SMPostTimeProfile -by year
      $posts.NormalizedPost | Measure-SMPostTimeProfile -by hour

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  begin {
    $TimeProfile          = @{}
    [PSObject[]] $ranking = @()

    switch ( $by.ToLower() ) {
      "dayofweek"    { $PropertyName = "DayOfWeek"    }
      "day"          { $PropertyName = "Day"          }
      "month"        { $PropertyName = "Month"        }
      "year"         { $PropertyName = "Year"         }
      "hour"         { $PropertyName = "Hour"         }
    }
  }

  process {
    $post             = $_

    $CurrentDayOfWeek = ( [datetime] $post.PublishingDate ).DayOfWeek
    $CurrentDay       = ( [datetime] $post.PublishingDate ).Day
    $CurrentMonth     = ( [datetime] $post.PublishingDate ).Month
    $CurrentYear      = ( [datetime] $post.PublishingDate ).Year
    $CurrentHour      = ( [datetime] $post.PublishingDate ).Hour

    switch ( $PropertyName ) {
      "DayOfWeek" {
        if ( $TimeProfile.ContainsKey("$CurrentDayOfWeek") ) {
          $TimeProfile["$CurrentDayOfWeek"] = $TimeProfile["$CurrentDayOfWeek"] + 1
        } else {
          $TimeProfile.Add("$CurrentDayOfWeek", 1)
        }
      }

      "Day" {
        if ( $TimeProfile.ContainsKey("$CurrentDay") ) {
          $TimeProfile["$CurrentDay"] = $TimeProfile["$CurrentDay"] + 1
        } else {
          $TimeProfile.Add("$CurrentDay", 1)
        }
      }

      "Month" {
        if ( $TimeProfile.ContainsKey("$CurrentMonth") ) {
          $TimeProfile["$CurrentMonth"] = $TimeProfile["$CurrentMonth"] + 1
        } else {
          $TimeProfile.Add("$CurrentMonth", 1)
        }
      }

      "Year" {
        if ( $TimeProfile.ContainsKey("$CurrentYear") ) {
          $TimeProfile["$CurrentYear"] = $TimeProfile["$CurrentYear"] + 1
        } else {
          $TimeProfile.Add("$CurrentYear", 1)
        }
      }

      "Hour" {
        if ( $TimeProfile.ContainsKey("$CurrentHour") ) {
          $TimeProfile["$CurrentHour"] = $TimeProfile["$CurrentHour"] + 1
        } else {
          $TimeProfile.Add("$CurrentHour", 1)
        }
      }
    }
  }

  end {
    $TimeProfile.keys | ForEach-Object {
      $ranking += New-Object PSObject -Property @{
        $PropertyName = $_
        Count         = $TimeProfile.$_
      }
    }

    $ranking
  }
}


function Measure-SMPostImpact() {
  <#
    .SYNOPSIS
      Returns the total measured impact of a Normalized Time Line.

    .DESCRIPTION
      Returns the total measured impact of a Normalized Time Line.

    .EXAMPLE
      $posts.NormalizedPost | Measure-SMPostImpact | Format-List -autoSize

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  begin {
    [PSObject[]] $ImpactMetrics = @()

    $TotalInteractions          = 0
    $TotalInterest              = 0
    $TotalAudience              = 0
    $TotalDownloads             = 0
    $TotalClickThroughs         = 0
    $EstimatedVirality          = "0%"
  }

  process {
    $post                       = $_

    $TotalInteractions         += $post.InteractionsCount
    $TotalInterest             += $post.InterestCount
    $TotalAudience             += $post.AudienceCount
    $TotalDownloads            += $post.DownloadsCount
    $TotalClickThroughs        += $post.ClickThroughsCount
  }

  end {
    if ( $TotalAudience -ne 0 ) {
      $EstimatedVirality        = ( '{0:#0.00}' -f $( $TotalInteractions / $TotalAudience ) ) + "%"
    }

    New-Object PSObject -Property @{
      TotalInteractions         = $TotalInteractions
      TotalInterest             = $TotalInterest
      TotalAudience             = $TotalAudience
      TotalDownloads            = $TotalDownloads
      TotalClickThroughs        = $TotalClickThroughs
      EstimatedVirality         = $EstimatedVirality
    }
  }
}


function Expand-TimeLine( $from, [string] $by = "category" ) {
  <#
    .SYNOPSIS
      Flattens a Normalized Time Line dataset. As a result, a new dataset is created based on the cartesian product of posts and categories, tags or keywords.

    .DESCRIPTION
      Flattens a Normalized Time Line dataset. As a result, a new dataset is created based on the cartesian product of posts and categories, tags or keywords. Useful to create datasets that can feed other Information Systems or Data Anlytics tools.

    .EXAMPLE
      $ExpandedTimeLine += Expand-TimeLine -from $NormalizedTimeLine -by category
      $ExpandedTimeLine += Expand-TimeLine -from $NormalizedTimeLine -by tag
      $ExpandedTimeLine += Expand-TimeLine -from $NormalizedTimeLine -by keyword

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  $LogFileName                = "CoreModule"
  $DumpFileName               = "CoreModule-Dump"

  $PostsProcessed             = 0
  $AverageElapsedTime         = 0
  $ElapsedTime                = 0
  $ExecutionTime              = [Diagnostics.Stopwatch]::StartNew()
  $ExecutionTime.Stop()

  $BY_CATEGORY                = "category"
  $BY_TAG                     = "tag"
  $BY_KEYWORD                 = "keyword"

  [PSObject[]] $ExpandedPosts = @()

  # $DebugPreference = "Continue"


  if ( $from.Count -gt 0 ) {
    if ( $from[0].NormalizedPost -eq $null ) {
      return $null
    }
  } else {
    if ( $from.NormalizedPost -eq $null ) {
      return $null
    }
  }


  foreach ( $CurrentPost in $from.NormalizedPost ) {
    if ( $AverageElapsedTime -eq 0 ) {
      $AverageElapsedTime = $ExecutionTime.Elapsed.TotalMinutes
    } else {
      $AverageElapsedTime = ( $AverageElapsedTime + $ExecutionTime.Elapsed.TotalMinutes ) / 2
    }

    $ElapsedTime         += $ExecutionTime.Elapsed.TotalMinutes

    Write-Progress -Activity "Processing Posts ..." -Status "Progress: $PostsProcessed / $($from.Count) - ETC: $( '{0:#0.00}' -f (( $($from.Count) - $PostsProcessed ) *  $AverageElapsedTime) ) minutes - Time Elapsed: $( '{0:#0.00}' -f $ElapsedTime ) minutes" -PercentComplete ( ( $PostsProcessed / $($from.Count) ) * 100 ) -currentOperation $CurrentPost.Title

    $ExecutionTime        = [Diagnostics.Stopwatch]::StartNew()

    $ElementsProcessed    = 0

    switch ( $by ) {
      $BY_CATEGORY {
        $ElementsCount         = if ( $CurrentPost.Categories.count -eq 0 ) { 1 } else { $CurrentPost.Categories.count }

        $CurrentPost.Categories | ForEach-Object {
          Write-Progress -Activity "Expanding Post ..." -id 1 -Status "Progress: $ElementsProcessed / $ElementsCount" -PercentComplete ( ( $ElementsProcessed / $ElementsCount ) * 100 ) -currentOperation $_

          $ExpandedPost        = New-Object -Type PSObject -Property @{
            ChannelType        = $CurrentPost.ChannelType
            ChannelDataEngine  = $CurrentPost.ChannelDataEngine
            ChannelName        = $CurrentPost.ChannelName
            SubChannelName     = $CurrentPost.SubChannelName
            SourceDomain       = $CurrentPost.SourceDomain
            SourceFormat       = $CurrentPost.SourceFormat
            Language           = $CurrentPost.Language
            Title              = $CurrentPost.Title
            Author             = $CurrentPost.AuthorDisplayName
            PublishingDate     = $CurrentPost.PublishingDate
            Topic              = $_
            PostType           = $CurrentPost.PostType
            UsersRating        = $CurrentPost.UsersRating
            InteractionsCount  = $CurrentPost.InteractionsCount
            InterestCount      = $CurrentPost.InterestCount
            AudienceCount      = $CurrentPost.AudienceCount
            DownloadsCount     = $CurrentPost.DownloadsCount
            ClickThroughsCount = $CurrentPost.ClickThroughsCount
            Virality           = $CurrentPost.Virality
          }

          $ExpandedPosts      += $ExpandedPost
          $ElementsProcessed++
        }
      }

      $BY_TAG {
        $ElementsCount         = if ( $CurrentPost.Tags.count -eq 0 ) { 1 } else { $CurrentPost.Tags.count }

        $CurrentPost.Tags | ForEach-Object {
          Write-Progress -Activity "Expanding Post ..." -id 1 -Status "Progress: $ElementsProcessed / $ElementsCount" -PercentComplete ( ( $ElementsProcessed / $ElementsCount ) * 100 ) -currentOperation $_

          $ExpandedPost        = New-Object -Type PSObject -Property @{
            ChannelType        = $CurrentPost.ChannelType
            ChannelDataEngine  = $CurrentPost.ChannelDataEngine
            ChannelName        = $CurrentPost.ChannelName
            SubChannelName     = $CurrentPost.SubChannelName
            SourceDomain       = $CurrentPost.SourceDomain
            SourceFormat       = $CurrentPost.SourceFormat
            Language           = $CurrentPost.Language
            Title              = $CurrentPost.Title
            Author             = $CurrentPost.Author
            PublishingDate     = $CurrentPost.PublishingDate
            Topic              = $_
            PostType           = $CurrentPost.PostType
            UsersRating        = $CurrentPost.UsersRating
            InteractionsCount  = $CurrentPost.InteractionsCount
            InterestCount      = $CurrentPost.InterestCount
            AudienceCount      = $CurrentPost.AudienceCount
            DownloadsCount     = $CurrentPost.DownloadsCount
            ClickThroughsCount = $CurrentPost.ClickThroughsCount
            Virality           = $CurrentPost.Virality
          }

          $ExpandedPosts      += $ExpandedPost
          $ElementsProcessed++
        }
      }

      $BY_KEYWORD {
        $ElementsCount         = if ( $CurrentPost.Keywords.count -eq 0 ) { 1 } else { $CurrentPost.Keywords.count }

        $CurrentPost.Keywords | ForEach-Object {
          Write-Progress -Activity "Expanding Post ..." -id 1 -Status "Progress: $ElementsProcessed / $ElementsCount" -PercentComplete ( ( $ElementsProcessed / $ElementsCount ) * 100 ) -currentOperation $_

          $ExpandedPost        = New-Object -Type PSObject -Property @{
            ChannelType        = $CurrentPost.ChannelType
            ChannelDataEngine  = $CurrentPost.ChannelDataEngine
            ChannelName        = $CurrentPost.ChannelName
            SubChannelName     = $CurrentPost.SubChannelName
            SourceDomain       = $CurrentPost.SourceDomain
            SourceFormat       = $CurrentPost.SourceFormat
            Language           = $CurrentPost.Language
            Title              = $CurrentPost.Title
            Author             = $CurrentPost.Author
            PublishingDate     = $CurrentPost.PublishingDate
            Topic              = $_
            PostType           = $CurrentPost.PostType
            UsersRating        = $CurrentPost.UsersRating
            InteractionsCount  = $CurrentPost.InteractionsCount
            InterestCount      = $CurrentPost.InterestCount
            AudienceCount      = $CurrentPost.AudienceCount
            DownloadsCount     = $CurrentPost.DownloadsCount
            ClickThroughsCount = $CurrentPost.ClickThroughsCount
            Virality           = $CurrentPost.Virality
          }

          $ExpandedPosts      += $ExpandedPost
          $ElementsProcessed++
        }
      }
    }

    $ExecutionTime.Stop()

    $PostsProcessed++
  }

  # $DebugPreference = "SilentlyContinue"


  $ExpandedPosts
}


function Measure-TLTopics( $from, [string[]] $GroupBy = @("Topic","Month") ) {
  <#
    .SYNOPSIS
      Analyzes topicality on an Expanded Time Line.

    .DESCRIPTION
      Analyzes topicality on an Expanded Time Line.

    .EXAMPLE
      $Topics         = Measure-TLTopics -from $ExpandedTimeLine
      $Topics         = Measure-TLTopics -from $ExpandedTimeLine -GroupBy Day
      $TopicsBySource = Measure-TLTopics -from $ExpandedTimeLine -GroupBy SourceDomain
      $TopicsBySource = Measure-TLTopics -from $ExpandedTimeLine -GroupBy SourceDomain,Day

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  $LogFileName                     = "CoreModule"

  $GroupBySourceDomain             = $false

  if ( $GroupBy.Count -in 1..2 ) {
    switch ( $GroupBy[0].ToLower() ) {
      "sourcedomain" { $GroupBySourceDomain   = $true   }
      "month"        { $GroupByTime           = "Month" }
      "year"         { $GroupByTime           = "Year"  }
      "day"          { $GroupByTime           = "Day"   }
    }

    if ( $GroupBy.Count -gt 1 ) {
      switch ( $GroupBy[1].ToLower() ) {
        "sourcedomain" { $GroupBySourceDomain = $true   }
        "month"        { $GroupByTime         = "Month" }
        "year"         { $GroupByTime         = "Year"  }
        "day"          { $GroupByTime         = "Day"   }
      }
    }
  } else {
    $GroupBy                       = @("Topic","Month")
    $GroupBySourceDomain           = $false
    $GroupByTime                   = "Month"
  }

  Write-Debug "[Measure-TLTopics] - GroupBy SourceDomain: $GroupBySourceDomain."
  Write-Debug "[Measure-TLTopics] - GroupBy Time:         $GroupByTime."

  [PSObject[]] $RawTopicsRanking                = @()
  [System.Collections.ArrayList] $TopicsRanking = @()

  $TOPIC_NAME                      = 0
  $DOMAINSOURCE_NAME               = 1
  $PUBLISHING_DATE                 = 2
  $USER_RATING                     = 3
  $INTERACTIONS_COUNT              = 4
  $INTEREST_COUNT                  = 5
  $AUDIENCE_COUNT                  = 6
  $DOWNLOADS_COUNT                 = 7
  $CLICKTHROUGHS_COUNT             = 8
  $VIRALITY_COUNT                  = 9


  # $DebugPreference = "Continue"


  $ExecutionTime                   = [Diagnostics.Stopwatch]::StartNew()
  $ElapsedTime                     = 0
  $AverageElapsedTime              = 0


  $ExecutionTime.Stop()
  $ElapsedTime                    += $ExecutionTime.Elapsed.TotalMinutes

  Write-Debug "[Measure-TLTopics] - Source Elements: $( $from.Count )."

  Write-Progress -Activity "Normalizing Dates ..." -Status "Stage 1 : 1 / 2 - Total Posts: $($from.Count) - Time Elapsed: $( '{0:#0.00}' -f $ElapsedTime ) minutes" -PercentComplete ( ( 1 / 2 ) * 100 ) -currentOperation "Ranking posts ..."
  $ExecutionTime                   = [Diagnostics.Stopwatch]::StartNew()

  $from                            = $from | Where-Object { ( $_.Topic -ne $null ) -and ( $_.SourceDomain -ne $null ) -and ( $_.PublishingDate -ne $null ) } | Select-Object Topic, SourceDomain, @{Name='PublishingDate'; Expression={ '{0:yyyy/MM/dd}' -f [datetime] $_.PublishingDate }}, UsersRating, InteractionsCount, InterestCount, AudienceCount, DownloadsCount, ClickThroughsCount, Virality

  Write-Debug "[Measure-TLTopics] - Without Null Elements: $( $from.Count )."


  $ExecutionTime.Stop()
  $ElapsedTime                    += $ExecutionTime.Elapsed.TotalMinutes


  Write-Progress -Activity "Grouping Posts by Topic ..." -Status "Stage 1: 2 / 2 - Total Posts: $($from.Count) - Time Elapsed: $( '{0:#0.00}' -f $ElapsedTime ) minutes" -PercentComplete ( ( 2 / 2 ) * 100 ) -currentOperation "Ranking posts ..."
  $ExecutionTime                   = [Diagnostics.Stopwatch]::StartNew()

  $RawTopicsRanking                = $from | Group-Object Topic, SourceDomain, PublishingDate, UsersRating, InteractionsCount, InterestCount, AudienceCount, DownloadsCount, ClickThroughsCount, Virality

  Write-Debug "[Measure-TLTopics] - RawTopicsRanking Elements: $( $RawTopicsRanking.Count )."


  $ExecutionTime.Stop()
  $ElapsedTime                    += $ExecutionTime.Elapsed.TotalMinutes


  $i                               = 1

  foreach ( $topic in $RawTopicsRanking ) {
    if ( $AverageElapsedTime -eq 0 ) {
      $AverageElapsedTime          = $ExecutionTime.Elapsed.TotalMinutes
    } else {
      $AverageElapsedTime          = ( $AverageElapsedTime + $ExecutionTime.Elapsed.TotalMinutes ) / 2
    }

    $ElapsedTime                  += $ExecutionTime.Elapsed.TotalMinutes

    $ExecutionTime                 = [Diagnostics.Stopwatch]::StartNew()

    Write-Progress -Activity "Processing Posts ..." -Status "Stage 2: Progress: $i / $( $RawTopicsRanking.Count ) - ETC: $( '{00:00:#0.00}' -f (( $RawTopicsRanking.Count  - $i ) * $AverageElapsedTime ) ) minutes - Time Elapsed: $( '{00:00:#0.00}' -f $ElapsedTime ) minutes" -PercentComplete ( ( $i / $RawTopicsRanking.Count ) * 100 ) -currentOperation "Aggregating data ..."

    $CurrentTopic                  = ""
    $CurrentSourceDomain           = ""
    $CurrentPublishingDate         = [datetime] 0
    $CurrentUsersRating            = 0
    $CurrentInteractionsCount      = 0
    $CurrentInterestCount          = 0
    $CurrentAudienceCount          = 0
    $CurrentDownloadsCount         = 0
    $CurrentClickThroughsCount     = 0
    $CurrentVirality               = 0
    $CurrentPostsCount             = $topic.Count


    $CurrentElement                = $topic.Name.Split(",")


    $CurrentTopic                  = $CurrentElement[$TOPIC_NAME]
    $CurrentSourceDomain           = $CurrentElement[$DOMAINSOURCE_NAME]

    try {
      switch ( $GroupByTime.ToLower() ) {
        "day"   { $CurrentPublishingDate   = [string] $CurrentElement[$PUBLISHING_DATE]                                 }
        "month" { $CurrentPublishingDate   = [string] ( '{0:yyyy/MM}' -f [datetime] $CurrentElement[$PUBLISHING_DATE] ) }
        "year"  { $CurrentPublishingDate   = [string] ( '{0:yyyy}'    -f [datetime] $CurrentElement[$PUBLISHING_DATE] ) }
        default { $CurrentPublishingDate   = [string] ( '{0:yyyy/MM}' -f [datetime] $CurrentElement[$PUBLISHING_DATE] ) }
      }
    } catch {
      "$(get-date -format u) [Measure-TLTopics] - Issues with PublishingDate: $( $CurrentElement[$PUBLISHING_DATE] )"         >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Measure-TLTopics] -   Topic: $CurrentTopic"                                                     >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      Write-Debug "[Measure-TLTopics] - Issues with PublishingDate: $( $CurrentElement[$PUBLISHING_DATE] )."
      Write-Debug "[Measure-TLTopics] -   Topic: $CurrentTopic"

      $CurrentPublishingDate       = [string] ( '{0:yyyy/MM}' -f [datetime] 0 )
    }

    try {
      $CurrentUsersRating          = [int] $CurrentElement[$USER_RATING]
    } catch {
      "$(get-date -format u) [Measure-TLTopics] - Issues with UserRating: $( $CurrentElement[$USER_RATING] )"                 >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Measure-TLTopics] -   Topic: $CurrentTopic"                                                     >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      Write-Debug "[Measure-TLTopics] - Issues with UserRating: $( $CurrentElement[$USER_RATING] )."
      Write-Debug "[Measure-TLTopics] -   Topic: $CurrentTopic"

      $CurrentUsersRating          = 0
    }

    try {
      $CurrentInteractionsCount    = [int] $CurrentElement[$INTERACTIONS_COUNT]
    } catch {
      "$(get-date -format u) [Measure-TLTopics] - Issues with InteractionsCount: $( $CurrentElement[$INTERACTIONS_COUNT] )"   >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Measure-TLTopics] -   Topic: $CurrentTopic"                                                     >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      Write-Debug "[Measure-TLTopics] - Issues with InteractionsCount: $( $CurrentElement[$INTERACTIONS_COUNT] )."
      Write-Debug "[Measure-TLTopics] -   Topic: $CurrentTopic"

      $CurrentInteractionsCount    = 0
    }

    try {
      $CurrentInterestCount        = [int] $CurrentElement[$INTEREST_COUNT]
    } catch {
      "$(get-date -format u) [Measure-TLTopics] - Issues with InterestCount: $( $CurrentElement[$INTEREST_COUNT] )"           >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Measure-TLTopics] -   Topic: $CurrentTopic"                                                     >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      Write-Debug "[Measure-TLTopics] - Issues with InterestCount: $( $CurrentElement[$INTEREST_COUNT] )."
      Write-Debug "[Measure-TLTopics] -   Topic: $CurrentTopic"

      $CurrentInterestCount        = 0
    }

    try {
      $CurrentAudienceCount        = [int] $CurrentElement[$AUDIENCE_COUNT]
    } catch {
      "$(get-date -format u) [Measure-TLTopics] - Issues with AudienceCount: $( $CurrentElement[$AUDIENCE_COUNT] )"           >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Measure-TLTopics] -   Topic: $CurrentTopic"                                                     >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      Write-Debug "[Measure-TLTopics] - Issues with AudienceCount: $( $CurrentElement[$AUDIENCE_COUNT] )."
      Write-Debug "[Measure-TLTopics] -   Topic: $CurrentTopic"

      $CurrentAudienceCount        = 0
    }

    try {
      $CurrentDownloadsCount       = [int] $CurrentElement[$DOWNLOADS_COUNT]
    } catch {
      "$(get-date -format u) [Measure-TLTopics] - Issues with DownloadsCount: $( $CurrentElement[$DOWNLOADS_COUNT] )"         >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Measure-TLTopics] -   Topic: $CurrentTopic"                                                     >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      Write-Debug "[Measure-TLTopics] - Issues with DownloadsCount: $( $CurrentElement[$DOWNLOADS_COUNT] )."
      Write-Debug "[Measure-TLTopics] -   Topic: $CurrentTopic"

      $CurrentDownloadsCount       = 0
    }

    try {
      $CurrentClickThroughsCount   = [int] $CurrentElement[$CLICKTHROUGHS_COUNT]
    } catch {
      "$(get-date -format u) [Measure-TLTopics] - Issues with ClickThroughsCount: $( $CurrentElement[$CLICKTHROUGHS_COUNT] )" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Measure-TLTopics] -   Topic: $CurrentTopic"                                                     >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      Write-Debug "[Measure-TLTopics] - Issues with ClickThroughsCount: $( $CurrentElement[$CLICKTHROUGHS_COUNT] )."
      Write-Debug "[Measure-TLTopics] -   Topic: $CurrentTopic"

      $CurrentClickThroughsCount   = 0
    }

    try {
      $CurrentVirality             = [int] $CurrentElement[$VIRALITY_COUNT]
    } catch {
      "$(get-date -format u) [Measure-TLTopics] - Issues with ViralityCount: $( $CurrentElement[$VIRALITY_COUNT] )"           >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Measure-TLTopics] -   Topic: $CurrentTopic"                                                     >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      Write-Debug "[Measure-TLTopics] - Issues with ViralityCount: $( $CurrentElement[$VIRALITY_COUNT] )."
      Write-Debug "[Measure-TLTopics] -   Topic: $CurrentTopic"

      $CurrentVirality             = 0
    }


    if ( ( $TopicsRanking | Where-Object { ( $_.Topic -eq $CurrentTopic ) -and ( $_.SourceDomain -eq $( if ( $GroupBySourceDomain ) { $CurrentSourceDomain } else { $VALUE_NA } ) ) -and ( $_.PublishingDate -eq $CurrentPublishingDate ) } ).Count -eq 0 ) {
      $NewTopic = New-Object PSObject -Property @{
        Topic                      = $CurrentTopic
        SourceDomain               = if ( $GroupBySourceDomain ) { $CurrentSourceDomain } else { $VALUE_NA }
        PublishingDate             = $CurrentPublishingDate
        UsersRating                = $CurrentUsersRating
        InteractionsCount          = $CurrentInteractionsCount
        InterestCount              = $CurrentInterestCount
        AudienceCount              = $CurrentAudienceCount
        DownloadsCount             = $CurrentDownloadsCount
        ClickThroughsCount         = $CurrentClickThroughsCount
        Virality                   = $CurrentVirality
        PostsCount                 = $CurrentPostsCount
        SourcesCount               = ( $RawTopicsRanking | Where-Object { $_.Topic -eq $CurrentTopic } | Select-Object SourceDomain -unique | Measure-Object ).Count
      }

      $TopicsRanking.Add( $NewTopic ) | Out-Null
    } else {
      $TopicsRanking | Where-Object { ( $_.Topic -eq $CurrentTopic ) -and ( $_.SourceDomain -eq $( if ( $GroupBySourceDomain ) { $CurrentSourceDomain } else { $VALUE_NA } ) ) -and ( $_.PublishingDate -eq $CurrentPublishingDate ) } | ForEach-Object {
        $_.UsersRating            += $CurrentUsersRating
        $_.InteractionsCount      += $CurrentInteractionsCount
        $_.InterestCount          += $CurrentInterestCount
        $_.AudienceCount          += $CurrentAudienceCount
        $_.DownloadsCount         += $CurrentDownloadsCount
        $_.ClickThroughsCount     += $CurrentClickThroughsCount
        $_.Virality               += $CurrentVirality
      }
    }


    $ExecutionTime.Stop()

    $i++
  }

  # $DebugPreference = "SilentlyContinue"

  Write-Debug "[Measure-TLTopics] - TopicsRanking Elements: $( $TopicsRanking.Count )."

  $TopicsRanking | ForEach-Object { $_ }
}


function Measure-TopicsTrends() {
  <#
    .SYNOPSIS
      Takes a number of Topics from the pipe line and sends them to Google Trends to see their relative relevance.

    .DESCRIPTION
      Takes a number of Topics from the pipe line and sends them to Google Trends to see their relative relevance. Because of Google Trends limitations, the maximum number of topics is just 5.

    .EXAMPLE
      "Cloud", "Big Data", "OpenStack" | Measure-TopicsTrends

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  param(
    [parameter(
       Mandatory         = $true,
       Position          = 0,
       ValueFromPipeline = $true,
       HelpMessage       = 'An array of strings containing the Topics to analyze.'
    )] [string] $topic
  )

  begin {
    [string[]] $TargetTopics   = @()
    [string] $SerializedTopics = ""
    [string] $EncodedTopics    = ""
  }

  process {
    $TargetTopics   += $topic
  }

  end {
    # $DebugPreference = "Continue"

    $TargetTopics[0..4] | ForEach-Object { $SerializedTopics += "$_, " }
    $EncodedTopics   = EscapeDataStringRfc3986 ( $SerializedTopics.SubString( 0, ($SerializedTopics.Length - 2) ).Trim() )

    Open-WebPage "https://www.google.com/trends/explore#q=$EncodedTopics&cmpt=q"

    Write-Debug "Serialized topics:        $SerializedTopics"
    Write-Debug "Encoded topics:           $EncodedTopics"
    Write-Debug "Target URL:               https://www.google.com/trends/explore#q=$EncodedTopics&cmpt=q"

    # $DebugPreference = "SilentlyContinue"
  }
}


function Get-SNTimeLine() {
  <#
    .SYNOPSIS
      Composes a Time Line with every post from all the Social Media channels defined on the Current Profile.

    .DESCRIPTION
      Composes a Time Line with every post from all the Social Media channels defined on the Current Profile. If local data cache is still valid, it will use it as the data source.

    .EXAMPLE
      $TimeLine = Get-SNTimeLine

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  [PSObject[]] $TimeLine = @()

  $connections.Twitter.TrackedUsersList | ForEach-Object {
    $TimeLine += Get-TwTimeLine $_
  }

  $TimeLine   += Get-FBTimeLine
  $TimeLine   += Get-LINTimeLine

  $TimeLine
}


function Update-SNPosts( [PSObject[]] $from ) {
  <#
    .SYNOPSIS
      Updates information about a collection of posts regardless of the Social Media channel used.

    .DESCRIPTION
      Updates information about a collection of posts regardless of the Social Media channel used.

    .EXAMPLE
      $UpdatedTimeLine = Update-SNPosts -from $NormalizedTimeLine
      $UpdatedTimeLine = Update-SNPosts -from $PermaLinksList

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  $UpdatedPosts    = [PSCustomObject[]] @{}

  $i               = 1
  $ExecutionTime   = [Diagnostics.Stopwatch]::StartNew()

  foreach ( $post in $from ) {
    Write-Progress -Activity "Updating Posts ..." -Status "Progress: $i / $($from.Count) - ETC: $( '{0:#0.00}' -f $( $($from.Count) - $i ) * $ExecutionTime.Elapsed.TotalMinutes ) minutes - Time Elapsed: $( '{0:#0.00}' -f $( $i *  $ExecutionTime.Elapsed.TotalMinutes ) ) minutes" -PercentComplete ( ( $i / $($from.Count) ) * 100 )

    Write-Debug "[Update-SNPosts] - CurrentUser:         $i"
    Write-Debug "[Update-SNPosts] - TotalUsers:          $($from.Count)"
    Write-Debug "[Update-SNPosts] - Retrieved Tweets:    $($ExecutionTime.Elapsed.TotalMinutes)"

    $ExecutionTime = [Diagnostics.Stopwatch]::StartNew()

    $UpdatedPosts += $post | Update-TwPost  -IncludeAll
    $UpdatedPosts += $post | Update-FBPost  -IncludeAll
    $UpdatedPosts += $post | Update-LINPost -IncludeAll

    $ExecutionTime.Stop()

    $i++
  }

  $UpdatedPosts    = $UpdatedPosts -ne $null

  $UpdatedPosts
}


function ContertTo-PrivateTimeLine( [PSObject[]] $from ) {
  <#
    .SYNOPSIS
      Takes an existing normalized Time Line and anonymizes those pieces of information affected by Privacy Levels defined on the connection settings.

    .DESCRIPTION
      Takes an existing normalized Time Line and anonymizes those pieces of information affected by Privacy Levels defined on the connection settings. Connection settings are defined on your current profile.

    .EXAMPLE
      $PrivateTimeLine = ContertTo-PrivateTimeLine -from $NormalizedTimeLine

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  $UpdatedPosts    = [PSCustomObject[]] @{}

  $i               = 1
  $ExecutionTime   = [Diagnostics.Stopwatch]::StartNew()

  foreach ( $post in $from ) {
    Write-Progress -Activity "Updating Posts ..." -Status "Progress: $i / $($from.Count) - ETC: $( '{0:#0.00}' -f $( $($from.Count) - $i ) * $ExecutionTime.Elapsed.TotalMinutes ) minutes - Time Elapsed: $( '{0:#0.00}' -f $( $i *  $ExecutionTime.Elapsed.TotalMinutes ) ) minutes" -PercentComplete ( ( $i / $($from.Count) ) * 100 )

    Write-Debug "[ContertTo-PrivateTimeLine] - CurrentElement:      $i"
    Write-Debug "[ContertTo-PrivateTimeLine] - TotalElements:       $($from.Count)"
    Write-Debug "[ContertTo-PrivateTimeLine] - ElapsedMinutes:      $($ExecutionTime.Elapsed.TotalMinutes)"

    $ExecutionTime = [Diagnostics.Stopwatch]::StartNew()

    $UpdatedPosts += $post | ConvertTo-PrivatePost

    $ExecutionTime.Stop()

    $i++
  }

  $UpdatedPosts
}


function ConvertTo-PrivatePost() {
  <#
    .SYNOPSIS
      Takes an existing normalized post and anonymizes those pieces of information affected by Privacy Levels defined on the connection settings.

    .DESCRIPTION
      Takes an existing normalized post and anonymizes those pieces of information affected by Privacy Levels defined on the connection settings. Connection settings are defined on your current profile.

    .EXAMPLE
      $PrivatePost = $NormalizedPost | ContertTo-PrivatePost

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  process {
    $post                                        = $_

    switch ( $post.NormalizedPost.ChannelName ) {
      $CHANNEL_NAME_TWITTER {
        $post.NormalizedPost.PostId              = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM  ) { $post.NormalizedPost.PostId            } else { Get-SMPostDigest $post.NormalizedPost.PostId            }
        $post.NormalizedPost.PermaLink           = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM  ) { $post.NormalizedPost.PermaLink         } else { Get-SMPostDigest $post.NormalizedPost.PermaLink         }
        $post.NormalizedPost.SubChannelName      = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_LOW     ) { $post.NormalizedPost.SubChannelName    } else { Get-SMPostDigest $post.NormalizedPost.SubChannelName    }
        $post.NormalizedPost.AuthorId            = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_LOW     ) { $post.NormalizedPost.AuthorId          } else { Get-SMPostDigest $post.NormalizedPost.AuthorId          }
        $post.NormalizedPost.AuthorDisplayName   = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_LOW     ) { $post.NormalizedPost.AuthorDisplayName } else { Get-SMPostDigest $post.NormalizedPost.AuthorDisplayName }

        $post.PostConnections | ForEach-Object {
          $_.UserId                              = if ( $connections.Twitter.PrivacyLevel -eq $PRIVACY_LEVEL_NONE    ) { $_.UserId                              } else { Get-SMPostDigest $_.UserId                              }
          $_.UserDisplayName                     = if ( $connections.Twitter.PrivacyLevel -eq $PRIVACY_LEVEL_NONE    ) { $_.UserDisplayName                     } else { Get-SMPostDigest $_.UserDisplayName                     }
        }
      }

      $CHANNEL_NAME_FACEBOOK {
        $post.NormalizedPost.PostId              = if ( $connections.Facebook.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.NormalizedPost.PostId            } else { Get-SMPostDigest $post.NormalizedPost.PostId            }
        $post.NormalizedPost.PermaLink           = if ( $connections.Facebook.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.NormalizedPost.PermaLink         } else { Get-SMPostDigest $post.NormalizedPost.PermaLink         }
        $post.NormalizedPost.SubChannelName      = if ( $connections.Facebook.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.NormalizedPost.SubChannelName    } else { Get-SMPostDigest $post.NormalizedPost.SubChannelName    }
        $post.NormalizedPost.AuthorId            = if ( $connections.Facebook.PrivacyLevel -le $PRIVACY_LEVEL_LOW    ) { $post.NormalizedPost.AuthorId          } else { Get-SMPostDigest $post.NormalizedPost.AuthorId          }
        $post.NormalizedPost.AuthorDisplayName   = if ( $connections.Facebook.PrivacyLevel -le $PRIVACY_LEVEL_LOW    ) { $post.NormalizedPost.AuthorDisplayName } else { Get-SMPostDigest $post.NormalizedPost.AuthorDisplayName }

        $post.PostConnections | ForEach-Object {
          $_.UserId                              = if ( $connections.Facebook.PrivacyLevel -eq $PRIVACY_LEVEL_NONE   ) { $_.UserId                              } else { Get-SMPostDigest $_.UserId                              }
          $_.UserDisplayName                     = if ( $connections.Facebook.PrivacyLevel -eq $PRIVACY_LEVEL_NONE   ) { $_.UserDisplayName                     } else { Get-SMPostDigest $_.UserDisplayName                     }
        }
      }

      $CHANNEL_NAME_LINKEDIN {
        $post.NormalizedPost.PostId              = if ( $connections.LinkedIn.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.NormalizedPost.PostId            } else { Get-SMPostDigest $post.NormalizedPost.PostId            }
        $post.NormalizedPost.PermaLink           = if ( $connections.LinkedIn.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.NormalizedPost.PermaLink         } else { Get-SMPostDigest $post.NormalizedPost.PermaLink         }
        $post.NormalizedPost.SubChannelName      = if ( $connections.LinkedIn.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.NormalizedPost.SubChannelName    } else { Get-SMPostDigest $post.NormalizedPost.SubChannelName    }
        $post.NormalizedPost.AuthorId            = if ( $connections.LinkedIn.PrivacyLevel -le $PRIVACY_LEVEL_LOW    ) { $post.NormalizedPost.AuthorId          } else { Get-SMPostDigest $post.NormalizedPost.AuthorId          }
        $post.NormalizedPost.AuthorDisplayName   = if ( $connections.LinkedIn.PrivacyLevel -le $PRIVACY_LEVEL_LOW    ) { $post.NormalizedPost.AuthorDisplayName } else { Get-SMPostDigest $post.NormalizedPost.AuthorDisplayName }

        $post.PostConnections | ForEach-Object {
          $_.UserId                              = if ( $connections.LinkedIn.PrivacyLevel -eq $PRIVACY_LEVEL_NONE   ) { $_.UserId                              } else { Get-SMPostDigest $_.UserId                              }
          $_.UserDisplayName                     = if ( $connections.LinkedIn.PrivacyLevel -eq $PRIVACY_LEVEL_NONE   ) { $_.UserDisplayName                     } else { Get-SMPostDigest $_.UserDisplayName                     }
          $_.UserProfileUrl                      = if ( $connections.LinkedIn.PrivacyLevel -eq $PRIVACY_LEVEL_NONE   ) { $_.UserDisplayName                     } else { Get-SMPostDigest $_.UserDisplayName                     }
          $_.UserProfileApiUrl                   = if ( $connections.LinkedIn.PrivacyLevel -eq $PRIVACY_LEVEL_NONE   ) { $_.UserDisplayName                     } else { Get-SMPostDigest $_.UserDisplayName                     }
        }
      }

      default {
        if ( $post.NormalizedPost.ChannelDataEngine -eq $CHANNEL_DATA_ENGINE_FEED ) {
          $post.NormalizedPost.PermaLink         = if ( $connections.Feeds.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM    ) { $post.NormalizedPost.PermaLink         } else { Get-SMPostDigest $post.NormalizedPost.PermaLink         }
          $post.NormalizedPost.ChannelName       = if ( $connections.Feeds.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM    ) { $post.NormalizedPost.ChannelName       } else { Get-SMPostDigest $post.NormalizedPost.ChannelName       }
          $post.NormalizedPost.SubChannelName    = if ( $connections.Feeds.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM    ) { $post.NormalizedPost.SubChannelName    } else { Get-SMPostDigest $post.NormalizedPost.SubChannelName    }
          $post.NormalizedPost.AuthorDisplayName = if ( $connections.Feeds.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM    ) { $post.NormalizedPost.AuthorDisplayName } else { Get-SMPostDigest $post.NormalizedPost.AuthorDisplayName }
        }
      }
    }
  }

  end {
    $post
  }
}


function ConvertTo-PrivateUserProfiles() {
  <#
    .SYNOPSIS
      Takes an existing normalized user profiles and anonymizes those pieces of information affected by Privacy Levels defined on the connection settings.

    .DESCRIPTION
      Takes an existing normalized user profiles and anonymizes those pieces of information affected by Privacy Levels defined on the connection settings. Connection settings are defined on your current profile.

    .EXAMPLE
      $PrivateProfiles = ContertTo-PrivateTimeLine -from $UserProfiles

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  $UpdatedProfiles = [PSCustomObject[]] @{}

  $i               = 1
  $ExecutionTime   = [Diagnostics.Stopwatch]::StartNew()

  foreach ( $UserProfile in $from ) {
    Write-Progress -Activity "Updating User Profiles ..." -Status "Progress: $i / $($from.Count) - ETC: $( '{0:#0.00}' -f $( $($from.Count) - $i ) * $ExecutionTime.Elapsed.TotalMinutes ) minutes - Time Elapsed: $( '{0:#0.00}' -f $( $i *  $ExecutionTime.Elapsed.TotalMinutes ) ) minutes" -PercentComplete ( ( $i / $($from.Count) ) * 100 )

    Write-Debug "[ConvertTo-PrivateUserProfiles] - CurrentUser:         $i"
    Write-Debug "[ConvertTo-PrivateUserProfiles] - TotalElements:       $($from.Count)"
    Write-Debug "[ConvertTo-PrivateUserProfiles] - ElapsedMinutes:      $($ExecutionTime.Elapsed.TotalMinutes)"

    $ExecutionTime = [Diagnostics.Stopwatch]::StartNew()

    $UpdatedProfiles += $UserProfile | ContertTo-PrivateUserProfileData

    $ExecutionTime.Stop()

    $i++
  }

  $UpdatedProfiles
}


function ConvertTo-PrivateUserProfileData() {
  <#
    .SYNOPSIS
      Takes an existing a normalized user and anonymizes those pieces of information affected by Privacy Levels defined on the connection settings.

    .DESCRIPTION
      Takes an existing a normalized user and anonymizes those pieces of information affected by Privacy Levels defined on the connection settings. Connection settings are defined on your current profile.

    .EXAMPLE
      $PrivateUserProfile = $NormalizedUserProfile | ContertTo-PrivateUserProfileData

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  process {
    $UserProfile                                 = $_

    switch ( $post.NormalizedUser.ChannelName ) {
      $CHANNEL_NAME_TWITTER {
        $UserProfile.NormalizedUser.UserId       = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.NormalizedUser.UserId       } else { Get-SMPostDigest $post.NormalizedUser.UserId       }
        $UserProfile.NormalizedUser.DisplayName  = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.NormalizedUser.DisplayName  } else { Get-SMPostDigest $post.NormalizedUser.DisplayName  }
        $UserProfile.NormalizedUser.PermaLink    = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.NormalizedUser.PermaLink    } else { Get-SMPostDigest $post.NormalizedUser.PermaLink    }
        $UserProfile.NormalizedUser.ContactLinks = if ( $connections.Twitter.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.NormalizedUser.ContactLinks } else { Get-SMPostDigest $post.NormalizedUser.ContactLinks }
      }
    }
  }

  end {
    $UserProfile
  }
}


function Expand-ShortLink() {
  <#
    .SYNOPSIS
      Takes Short Link and returns both the target landing page and the HTTP code returned by that page.

    .DESCRIPTION
      Takes Short Link and returns both the target landing page and the HTTP code returned by that page.

    .EXAMPLE
      $TargetUrl = Expand-ShortLink "https://bitly.com/Yl1zGu"
      $TargetUrl = "https://bitly.com/Yl1zGu" | Expand-ShortLink

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  param(
    [Parameter(
       Mandatory         = $true,
       Position          = 0,
       ValueFromPipeline = $true,
       HelpMessage       = 'Short Link to be expanded.'
    )] [string] $link    = ""
  )


  process {
    [PSObject] $ExpandedShortLink = $null
    $response                     = ""

    if ( ( $link -eq $null ) -or ( $link -eq "" ) ) {
      $ExpandedShortLink = New-Object PSObject -Property @{
        HttpCode         = "000"
        ExpandedUrl      = "N/A"
      }

      return $ExpandedShortLink
    }

    Write-Debug "[Expand-ShortLink] - Requested Link: $link"

    $response            = & $BinDir\curl.exe -sLk -w "%{http_code} %{url_effective}" --user-agent "Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)" -o /dev/null "$link"

    Write-Debug "[Expand-ShortLink] - Expanded Link:  $( $response.Split(" ")[0] ) - $( $response.Split(" ")[1] )"

    New-Object PSObject -Property @{
      HttpCode           = $response.Split(" ")[0]
      ExpandedUrl        = $response.Split(" ")[1]
    }
  }
}


function Get-ShortLinks( [string] $from, [switch] $protocol, [switch] $ForceSSL ) {
  <#
    .SYNOPSIS
      Parses the input string and returns an array of the existing Short Links links.

    .DESCRIPTION
      Parses the input string and returns an array of the existing Short Links links.

    .EXAMPLE
      $ShortLinks += Get-ShortLinks -from $NormalizedTimeLine[0].NormalizedPost.Title

    .NOTES

    .LINK
      N/A
  #>


  [RegEx]    $LinksPattern = "(?<ShortLink>[a-zA-Z0-9]+\.[a-zA-Z0-9]+/[a-zA-Z0-9]*)[ ]*"
  [string[]] $EmbededLinks = @()
  [string[]] $ShortLinks   = @()


  $CurrentMatch    = $LinksPattern.Match( $from )

  if (!$CurrentMatch.Success) {
    return $null
  }

  while ($CurrentMatch.Success) {
    $EmbededLinks += $CurrentMatch.Value -replace "[\.]+$", ""
    $CurrentMatch  = $CurrentMatch.NextMatch()
  }

  $EmbededLinks | ForEach-Object {
    Write-Debug "Get-ShortLinks] - Embeded Link: $_"
    Write-Debug "Get-ShortLinks] -   Protocol:   $protocol"
    Write-Debug "Get-ShortLinks] -   ForceSSL:   $ForceSSL"

    if ( $protocol ) {
      if ( $ForceSSL ) {
        if ( $_ -match "http|https" ) {
          $ShortLinks += $_.Trim() -replace "http:","https:"
        } else {
          $ShortLinks += "https://$_".Trim()
        }
      } else {
        if ( $_ -match "http|https" ) {
          $ShortLinks += $_.Trim() -replace "https:","http:"
        } else {
          $ShortLinks += "http://$_".Trim()
        }
      }
    } else {
      if ( $_ -match "http|https" ) {
        $ShortLinks += $_.Trim() -replace "http://|https://",""
      } else {
        $ShortLinks += "$_".Trim()
      }
    }
  }

  Write-Debug "Get-ShortLinks] - Short Links:  $( [string] $ShortLinks )"

  return $ShortLinks
}


function Get-RawNormalizedPropertyName( [string] $Name ) {
  <#
    .SYNOPSIS
      Normalizes names so that they can be used safely as identifiers on other data structures.

    .DESCRIPTION
      Normalizes names so that they can be used safely as identifiers on other data structures.

    .EXAMPLE
      $NormalizedColumnName = Get-RawNormalizedPropertyName "Campaign Name"

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  $LogFileName      = "CoreModule"

  [string] $KeyName = ""

  Write-Debug "[Get-RawNormalizedPropertyName] - Normalizing name: $Name"

  try {
    $KeyName        = $Name
    $KeyName        = $KeyName -replace "[^a-zA-Z0-9 ]*", ""
    $KeyName        = $KeyName -replace " ", "_"

    while ( $KeyName.SubString(0, 1) -eq "_" )                     { $KeyName = $KeyName.SubString( 1,  ( $KeyName.Length - 1 ) ) }
    while ( $KeyName.SubString(($KeyName.Length - 1), 1) -eq "_" ) { $KeyName = $KeyName.SubString( 0,  ( $KeyName.Length - 1 ) ) }

    $KeyName        = $KeyName.Trim()

    Write-Debug "[Get-RawNormalizedPropertyName] - Normalized name:  $KeyName"

    return $KeyName
  } catch {
    "$(get-date -format u) [Get-RawNormalizedPropertyName] - Unable to normalize name: $Name" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    Write-Debug "[Get-RawNormalizedPropertyName] - Unable to normalize name: $Name"

    return $null
  }
}