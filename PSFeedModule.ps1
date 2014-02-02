<#
-------------------------------------------------------------------------------
Name:    Social Media Scripting Framework
Module:  Feed Module
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


$FEED_FORMAT_NOT_RECOGNIZED     = 0
$FEED_FORMAT_IS_RDF             = 1
$FEED_FORMAT_IS_ATOM            = 2
$FEED_FORMAT_IS_WXR             = 3
$FEED_FORMAT_IS_RSS             = 4
$FEED_FORMAT_HAS_UNKNOWN_ISSUES = 5
$FEED_FORMAT_HAS_NO_COMMENTS    = 6
$FEED_FORMAT_HAS_NO_DATE        = 7
$FEED_FORMAT_HAS_NO_CATEGORIES  = 8
$FEED_FORMAT_HAS_NO_LANGUAGE    = 9
$FEED_FORMAT_HAS_NO_AUTHOR      = 10


function Expand-RawFeedDebugCodes( [int[]] $codes ) {
  <#
    .SYNOPSIS
      Composes a friendlier representation for the especified Debug Codes.

    .DESCRIPTION
      Composes a friendlier representation for the especified Debug Codes.

    .EXAMPLE
      $FriendlyDebugCodes = Expand-RawFeedDebugCodes -codes @(0, 1, 2)

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  $flags = @(
    "FEED_FORMAT_NOT_RECOGNIZED"     ,
    "FEED_FORMAT_IS_RDF"             ,
    "FEED_FORMAT_IS_ATOM"            ,
    "FEED_FORMAT_IS_WXR"             ,
    "FEED_FORMAT_IS_RSS"             ,
    "FEED_FORMAT_HAS_UNKNOWN_ISSUES" ,
    "FEED_FORMAT_HAS_NO_COMMENTS"    ,
    "FEED_FORMAT_HAS_NO_DATE"        ,
    "FEED_FORMAT_HAS_NO_CATEGORIES"  ,
    "FEED_FORMAT_HAS_NO_LANGUAGE"    ,
    "FEED_FORMAT_HAS_NO_AUTHOR"
  )

  [string] $DebugFlags = ""

  $codes | ForEach-Object { $DebugFlags += "$($flags[$_]), " }
  $DebugFlags          = $DebugFlags.Substring(0, ($DebugFlags.Length - 2))

  return $DebugFlags
}


function Import-RawFeeds( [string] $from ) {
  <#
    .SYNOPSIS
      Loads feed sources either from a TXT or from an OPML file.

    .DESCRIPTION
      Loads feed sources either from a TXT or from an OPML file.

    .EXAMPLE
      $MyFeeds = Import-RawFeeds -from MyFeeds.opml
      $MyFeeds = Import-RawFeeds -from MyFeeds.txt
      $MyFeeds = Import-RawFeeds -from FeedSubscriptions.xml
      $MyFeeds = Import-RawFeeds -from $connections.Feeds.DefaultFeedSource

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  $TYPE_XML  = "xml"
  $TYPE_OPML = "opml"

  $FeedsSourceFile = "$CurrentProfileDir\$from"

  if ( Test-Path $FeedsSourceFile ) {
    $FileName      = $from.Split(".")

    if ( ( $FileName[ ( $FileName.Length - 1 ) ] -eq $TYPE_XML ) -or ( $FileName[ ( $FileName.Length - 1 ) ] -eq $TYPE_OPML ) ) {
      [xml] $feeds = Get-Content $FeedsSourceFile

      $feeds.opml.body.outline.outline.xmlUrl | Select-Object -unique
    } else {
      Get-Content $FeedsSourceFile | Select-Object -unique
    }
  }
}


function Backup-RawFeedContent( [string[]] $from ) {
  <#
    .SYNOPSIS
      Downloads content from each of the feeds especified.

    .DESCRIPTION
      Downloads content from each of the feeds especified. Feed sources used are usually the ones previously loaded using Import-RawFeeds.

    .EXAMPLE
      $MyFeeds = Backup-RawFeedContent -from $MyFeeds
      $MyFeeds = Backup-RawFeedContent -from $( Import-RawFeeds -from FeedSubscriptions.xml )
      $MyFeeds = Backup-RawFeedContent -from $( Import-RawFeeds -from $connections.Feeds.DefaultFeedSource )
      $MyFeeds = Backup-RawFeedContent -from "http://domain.com/feed"

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  $LogFileName        = "FeedModule-FailingFeeds"

  $ExecutionTime      = [Diagnostics.Stopwatch]::StartNew()
  $ExecutionTime.Stop()

  $FeedsProcessed     = 1
  $AverageElapsedTime = 0

  $from | ForEach-Object {
    if ( $AverageElapsedTime -eq 0 ) {
      $AverageElapsedTime = $ExecutionTime.Elapsed.TotalMinutes
    } else {
      $AverageElapsedTime = ( $AverageElapsedTime + $ExecutionTime.Elapsed.TotalMinutes ) / 2
    }

    Write-Progress -Activity "Retrieving Feeds ..." -Status "Progress: $FeedsProcessed / $($from.Count) - ETC: $( '{0:#0.00}' -f (( $($from.Count) - $FeedsProcessed ) *  $AverageElapsedTime) ) minutes - Time Elapsed: $( '{0:#0.00}' -f (( $FeedsProcessed - 1 ) * $AverageElapsedTime) ) minutes" -PercentComplete ( ( $FeedsProcessed / $($from.Count) ) * 100 )

    $ExecutionTime    = [Diagnostics.Stopwatch]::StartNew()

    $CurrentFeed      = $_

    Try {
      $CurrentContent = Get-PageSourceCode $CurrentFeed

      $FileName       = $CurrentFeed.Split("/")[2]
      if ( $FileName -imatch "feedburner" ) { $FileName     = $FileName + "-" + $($CurrentFeed.Split("/")[3]) }

      $FileType       = "xml"
      if ( ([xml] $CurrentContent).rdf  -ne $null ) { $FileType = "rdf" }
      if ( ([xml] $CurrentContent).feed -ne $null ) { $FileType = "atom" }
      if ( ([xml] $CurrentContent).rss  -ne $null ) { $FileType = "rss" }

      $CurrentContent | Set-Content "$FeedsCacheDir\$FileName.$FileType" -Encoding UTF8
    } Catch {
      "$(get-date -format u) [$($($_.FullyQualifiedErrorId | Out-String).Trim())] - $CurrentFeed" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    }

    $ExecutionTime.Stop()

    $FeedsProcessed++
  }
}


function Get-RawFeedPostMetadata( $from, [int] $format = $FEED_FORMAT_IS_RSS ) {
  <#
    .SYNOPSIS
      Analizes a given post on a certain format and returns all the relevant meta data.

    .DESCRIPTION
      Analizes a given post on a certain format and returns all the relevant meta data.

    .EXAMPLE
      $PostInfo = Get-RawFeedPostMetadata -from $Post -format $FEED_FORMAT_IS_ATOM

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  $LogFileName     = "FeedModule-MetaData"
  $DumpFileName    = "FeedModule-RawDump"
  $XmlPost         = $from
  $IssuesFound     = $false

  $NormalizedPost  = New-Object -Type PSObject -Property @{
    PermaLink      = ""
    SourceDomain   = ""
    Language       = ""
    Title          = ""
    Author         = ""
    PublishingDate = Get-Date -format $DefaultDateFormat
    Categories     = @()
    Tags           = @()
    Keywords       = @()
    CommentsCount  = 0
    SourceFormat   = "Unknown"
    DebugCodes     = @( $FEED_FORMAT_NOT_RECOGNIZED )
  }


  # RDF structure
  if ( $format -eq $FEED_FORMAT_IS_RDF ) {
    Try {
      $NormalizedPost.PermaLink      = $XmlPost.origLink
      $NormalizedPost.SourceDomain   = ""
      $NormalizedPost.Language       = ""
      $NormalizedPost.Title          = $XmlPost.title
      $NormalizedPost.Author         = $XmlPost.creator
      $NormalizedPost.PublishingDate = if ( $XmlPost.date -eq $null) { [datetime] 0 } else { [datetime] $XmlPost.date }
      $NormalizedPost.Categories     = if ( $XmlPost.subject -eq $null ) { @() } else { @( $XmlPost.subject ) }
      $NormalizedPost.Tags           = @()
      $NormalizedPost.Keywords       = @()
      $NormalizedPost.CommentsCount  = 0
      $NormalizedPost.SourceFormat   = "RDF"
      $NormalizedPost.DebugCodes     = @( $FEED_FORMAT_IS_RDF, $FEED_FORMAT_HAS_NO_COMMENTS )
    } catch {
      ( $XmlPost | Out-String ).Trim()                                                                 >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log
      "-------------------------------------------------------------------------------"                >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log

      "$(get-date -format u) [$($($_.FullyQualifiedErrorId | Out-String).Trim())] - $($XmlPost.title)" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      $NormalizedPost.DebugCodes    += $FEED_FORMAT_HAS_UNKNOWN_ISSUES
    }

    if ( $XmlPost.date -eq $null ) {
      "$(get-date -format u) [RDF]   - Post without Date - $($XmlPost.title)" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      $NormalizedPost.DebugCodes    += $FEED_FORMAT_HAS_NO_DATE
    }

    if ( $XmlPost.subject -eq $null ) {
      "$(get-date -format u) [RDF]   - Post without Categories - $($XmlPost.title)" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      $NormalizedPost.DebugCodes    += $FEED_FORMAT_HAS_NO_CATEGORIES
    }
  }


  # Atom structure
  if ( $format -eq $FEED_FORMAT_IS_ATOM ) {
    Try {
      $AtomTitle                     = "Unknown"

      if ( $null -eq $XmlPost.title."#text" ) {
        $AtomTitle                   = $XmlPost.title
      } else {
        $AtomTitle                   = $XmlPost.title."#text"
      }

      $NormalizedPost.PermaLink      = $( $XmlPost.link | Where-Object { $_.rel -eq 'alternate' } ).href
      $NormalizedPost.SourceDomain   = ""
      $NormalizedPost.Language       = ""
      $NormalizedPost.Title          = $AtomTitle
      $NormalizedPost.Author         = $XmlPost.author.name
      $NormalizedPost.PublishingDate = if ( $XmlPost.updated -eq $null ) { [datetime] 0 } else { [datetime] $XmlPost.updated }
      $NormalizedPost.Categories     = if ( $XmlPost.category.term -eq $null ) { @() } else { @( $XmlPost.category.term ) }
      $NormalizedPost.Tags           = @()
      $NormalizedPost.Keywords       = @()
      $NormalizedPost.CommentsCount  = if ( $XmlPost.total -eq $null ) { 0 } else { $XmlPost.total }
      $NormalizedPost.SourceFormat   = "Atom"
      $NormalizedPost.DebugCodes     = @( $FEED_FORMAT_IS_ATOM )
    } Catch {
      ( $XmlPost | Out-String ).Trim()                                                                 >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log
      "-------------------------------------------------------------------------------"                >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log

      "$(get-date -format u) [$($($_.FullyQualifiedErrorId | Out-String).Trim())] - $AtomTitle)"       >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      $NormalizedPost.DebugCodes    += $FEED_FORMAT_HAS_UNKNOWN_ISSUES
    }

    if ( $XmlPost.updated -eq $null ) {
      "$(get-date -format u) [ATOM]  - Post without Date - $AtomTitle" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      $NormalizedPost.DebugCodes    += $FEED_FORMAT_HAS_NO_DATE
    }

    if ( $XmlPost.total -eq $null ) {
      "$(get-date -format u) [ATOM]  - Post without CommentsCount - $AtomTitle" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      $NormalizedPost.DebugCodes    += $FEED_FORMAT_HAS_NO_COMMENTS
    }

    if ( $XmlPost.category.term -eq $null ) {
      "$(get-date -format u) [ATOM]  - Post without Categories - $($XmlPost.title."#text")" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      $NormalizedPost.DebugCodes    += $FEED_FORMAT_HAS_NO_CATEGORIES
    }
  }


  # WXR (WordPress eXtended RSS) structure
  if ( $format -eq $FEED_FORMAT_IS_WXR ) {
    Try {
      $NormalizedPost.PermaLink      = $XmlPost.link
      $NormalizedPost.SourceDomain   = ""
      $NormalizedPost.Language       = ""
      $NormalizedPost.Title          = $XmlPost.title
      $NormalizedPost.Author         = $XmlPost.creator
      $NormalizedPost.PublishingDate = if ( $XmlPost.pubDate -eq $null ) { [datetime] 0 } else { [datetime] $XmlPost.pubDate }
      $NormalizedPost.Categories     = if ( ( $XmlPost.category | Where-Object { $_.domain -eq "category" } ) -eq $null ) { @() } else { @( ( $XmlPost.category | Where-Object { $_.domain -eq "category" } | Select-Object "#cdata-section" )."#cdata-section" ) }
      $NormalizedPost.Tags           = if ( ( $XmlPost.category | Where-Object { $_.domain -ne "category" } ) -eq $null ) { @() } else { @( ( $XmlPost.category | Where-Object { $_.domain -ne "category" } | Select-Object "#cdata-section" )."#cdata-section" ) }
      $NormalizedPost.Keywords       = @()
      $NormalizedPost.CommentsCount  = if ( $XmlPost.comment.Count -eq $null ) { if ( $XmlPost.comment.comment_id -ne $null ) { 1 } else { 0 } } else { $XmlPost.comment.Count }
      $NormalizedPost.SourceFormat   = "WXR"
      $NormalizedPost.DebugCodes     = @( $FEED_FORMAT_IS_WXR )
    } Catch {
      ( $XmlPost | Out-String ).Trim()                                                                 >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log
      "-------------------------------------------------------------------------------"                >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log

      "$(get-date -format u) [$($($_.FullyQualifiedErrorId | Out-String).Trim())] - $($XmlPost.title)" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      $NormalizedPost.DebugCodes    += $FEED_FORMAT_HAS_UNKNOWN_ISSUES
    }

    if ( $XmlPost.pubDate -eq $null ) {
      "$(get-date -format u) [WXR]   - Post without Date - $($XmlPost.title)" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      $NormalizedPost.DebugCodes    += $FEED_FORMAT_HAS_NO_DATE
    }

    if ( $XmlPost.category."#cdata-section" -eq $null ) {
      "$(get-date -format u) [WXR]   - Post without Categories - $($XmlPost.title)" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      $NormalizedPost.DebugCodes    += $FEED_FORMAT_HAS_NO_CATEGORIES
    }
  }


  # Standard RSS structure
  if ( $format -eq $FEED_FORMAT_IS_RSS ) {
    Try {
      $SkipRssCategory               = $true
      $RssCategoryPropertyName       = ""

      if ( ( $XmlPost | Get-Member -MemberType Property | Select-Object Name ).Name -contains "category" ) {
        $SkipRssCategory             = $false

        if ( ( $XmlPost.category | Get-Member -MemberType Property | Select-Object Name ).Name -is [array] ) {
          $RssCategoryPropertyName   = $( $XmlPost.category | Get-Member -MemberType Property | Select-Object Name ).Name[0]
        } else {
          $RssCategoryPropertyName   = $( $XmlPost.category | Get-Member -MemberType Property | Select-Object Name ).Name

          if ( $RssCategoryPropertyName -eq "Length" ) {
            $RssCategoryPropertyName = ""
          }
        }
      }

      $RssAuthorName                 = ""

      if ( ( $XmlPost | Get-Member -MemberType Property | Select-Object Name ).Name -contains "creator" ) {
        if ( ( $XmlPost.creator | Get-Member -MemberType Property | Select-Object Name ).Name -contains "Length" ) {
          if ( $XmlPost.creator.count -gt 1 ) {
            $RssAuthorName           = $XmlPost.creator[0]
          } else {
            $RssAuthorName           = $XmlPost.creator
          }
        } else {
          if ( ( $XmlPost.creator | Get-Member -MemberType Property | Select-Object Name ).Name -is [array] ) {
            if ( ( $XmlPost.creator | Get-Member -MemberType Property | Select-Object Name ).Name[0] -match "#" ) {
              $RssAuthorName         = $XmlPost.creator.$( ( $XmlPost.creator | Get-Member -MemberType Property | Select-Object Name ).Name[0] )
            }
          } else {
            if ( ( $XmlPost.creator | Get-Member -MemberType Property | Select-Object Name ).Name[0] -match "#" ) {
              $RssAuthorName         = $XmlPost.creator.$( ( $XmlPost.creator | Get-Member -MemberType Property | Select-Object Name ).Name )
            }
          }
        }
      } elseif ( ( $XmlPost | Get-Member -MemberType Property | Select-Object Name ).Name -contains "author" ) {
        if ( ( $XmlPost.author | Get-Member -MemberType Property | Select-Object Name ).Name -contains "Length" ) {
          if ( $XmlPost.author.count -gt 1 ) {
            $RssAuthorName           = $XmlPost.author[0]
          } else {
            $RssAuthorName           = $XmlPost.author
          }
        } else {
          if ( ( $XmlPost.author | Get-Member -MemberType Property | Select-Object Name ).Name -is [array] ) {
            if ( ( $XmlPost.author | Get-Member -MemberType Property | Select-Object Name ).Name[0] -match "#" ) {
              $RssAuthorName         = $XmlPost.author.$( ( $XmlPost.author | Get-Member -MemberType Property | Select-Object Name ).Name[0] )
            }
          } else {
            if ( ( $XmlPost.author | Get-Member -MemberType Property | Select-Object Name ).Name[0] -match "#" ) {
              $RssAuthorName         = $XmlPost.author.$( ( $XmlPost.author | Get-Member -MemberType Property | Select-Object Name ).Name )
            }
          }
        }
      }

      $RssPubDate                    = [datetime] 0

      if ( $XmlPost.pubDate -ne $null ) {
        if ( $XmlPost.pubDate."#cdata-section" -is [string] ) {
          if ( $XmlPost.pubDate."#cdata-section" -match "GMT 00:00:00 GMT" ) {
            $RssPubDate                = $( $XmlPost.pubDate."#cdata-section" -replace "00:00:00 GMT", "" )
          } else {
            $RssPubDate                = $XmlPost.pubDate."#cdata-section"
          }

          if ( $RssPubDate -match "ACDT|ACST|ADT|AEDT|AEST|AFT|AKDT|AKST|ALMT|AMST|AMT|ANAST|ANAT|AQTT|ART|AST|AWDT|AWST|AZOST|AZOT|AZST|AZT|BNT|BOT|BRST|BRT|BST|BTT|CAT|CCT|CDT|CEST|CET|CHADT|CHAST|CLST|CLT|COT|CST|CVT|CXT|ChST|DAVT|EASST|EAST|EAT|ECT|EDT|EEST|EET|EGST|EGT|EST|ET|FJST|FJT|FKT|GALT|GAMT|GET|GFT|GILT|GMT|GST|GYT|HAA|HAC|HADT|HAE|HAP|HAR|HAST|HAT|HAY|HKT|HLV|HNA|HNC|HNE|HNR|HNT|HNY|HOVT|ICT|IOT|IRDT|IRKST|IRKT|IRST|IST|JST|KGT|KRAST|KST|KUYT|LHDT|LHST|LINT|MAGST|MAGT|MART|MAWT|MDT|MESZ|MEZ|MHT|MMT|MSD|MSK|MST|MUT|MVT|MYT|NCT|NDT|NFT|NOVST|NOVT|NPT|NUT|NZDT|NZST|OMSST|OMST|PDT|PET|PETST|PETT|PGT|PHOT|PKT|PMDT|PMST|PONT|PST|PWT|PYST|PYT|SAMT|SAST|SBT|SCT|SGT|SRT|SST|TAHT|TFT|TJT|TKT|TLT|TMT|TVT|ULAT|UYST|UYT|UZT|VET|VLAST|VLAT|VUT|WAST|WAT|WEST|WESZ|WET|WFT|WGST|WIB|WIT|WITA|WST|WT|YAKST|YAKT|YAPT|YEKST|YEKT" ) {
            $RssPubDate                = [datetime] $( $RssPubDate -replace $Matches.0, "" )
          }
        } else {
          if ( $XmlPost.pubDate -match "GMT 00:00:00 GMT" ) {
            $RssPubDate                = $( $XmlPost.pubDate -replace "00:00:00 GMT", "" )
          } else {
            $RssPubDate                = $XmlPost.pubDate
          }

          if ( $RssPubDate -match "ACDT|ACST|ADT|AEDT|AEST|AFT|AKDT|AKST|ALMT|AMST|AMT|ANAST|ANAT|AQTT|ART|AST|AWDT|AWST|AZOST|AZOT|AZST|AZT|BNT|BOT|BRST|BRT|BST|BTT|CAT|CCT|CDT|CEST|CET|CHADT|CHAST|CLST|CLT|COT|CST|CVT|CXT|ChST|DAVT|EASST|EAST|EAT|ECT|EDT|EEST|EET|EGST|EGT|EST|ET|FJST|FJT|FKT|GALT|GAMT|GET|GFT|GILT|GMT|GST|GYT|HAA|HAC|HADT|HAE|HAP|HAR|HAST|HAT|HAY|HKT|HLV|HNA|HNC|HNE|HNR|HNT|HNY|HOVT|ICT|IOT|IRDT|IRKST|IRKT|IRST|IST|JST|KGT|KRAST|KST|KUYT|LHDT|LHST|LINT|MAGST|MAGT|MART|MAWT|MDT|MESZ|MEZ|MHT|MMT|MSD|MSK|MST|MUT|MVT|MYT|NCT|NDT|NFT|NOVST|NOVT|NPT|NUT|NZDT|NZST|OMSST|OMST|PDT|PET|PETST|PETT|PGT|PHOT|PKT|PMDT|PMST|PONT|PST|PWT|PYST|PYT|SAMT|SAST|SBT|SCT|SGT|SRT|SST|TAHT|TFT|TJT|TKT|TLT|TMT|TVT|ULAT|UYST|UYT|UZT|VET|VLAST|VLAT|VUT|WAST|WAT|WEST|WESZ|WET|WFT|WGST|WIB|WIT|WITA|WST|WT|YAKST|YAKT|YAPT|YEKST|YEKT" ) {
            $RssPubDate                = [datetime] $( $RssPubDate -replace $Matches.0, "" )
          }
        }
      }

      $NormalizedPost.PermaLink      = if ( $XmlPost.origLink -eq $null ) { $XmlPost.link } else { $XmlPost.origLink }
      $NormalizedPost.SourceDomain   = ""
      $NormalizedPost.Language       = ""
      $NormalizedPost.Title          = if ( $XmlPost.title."#cdata-section" -is [string] ) { $XmlPost.title."#cdata-section" } else { $XmlPost.title }
      $NormalizedPost.Author         = $RssAuthorName
      $NormalizedPost.PublishingDate = $RssPubDate
      $NormalizedPost.Categories     = if ( $SkipRssCategory ) { @() } else { if ( $RssCategoryPropertyName -eq "" ) { @( $XmlPost.category ) } else { @( $XmlPost.category.$RssCategoryPropertyName ) } }
      $NormalizedPost.Tags           = @()
      $NormalizedPost.Keywords       = @()

      try {
        $NormalizedPost.CommentsCount = if ( $XmlPost.comments -eq $null ) { 0 } else { [int] $XmlPost.comments[1] }
      } catch {
        try {
          $NormalizedPost.CommentsCount = if ( $XmlPost.comments -eq $null ) { 0 } else { [int] $XmlPost.comments[0] }
        } catch {
          $NormalizedPost.CommentsCount = 0
        }
      }

      $NormalizedPost.SourceFormat   = "RSS"
      $NormalizedPost.DebugCodes     = @( $FEED_FORMAT_IS_RSS )
    } Catch {
      ( $XmlPost | Out-String ).Trim()                                                                 >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log
      "-------------------------------------------------------------------------------"                >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log

      "$(get-date -format u) [$($($_.FullyQualifiedErrorId | Out-String).Trim())] - $($XmlPost.title)" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      $NormalizedPost.DebugCodes    += $FEED_FORMAT_HAS_UNKNOWN_ISSUES
    }

    if ( $XmlPost.pubDate -eq $null ) {
      "$(get-date -format u) [RSS]   - Post without Date - $($XmlPost.title)" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      $NormalizedPost.DebugCodes    += $FEED_FORMAT_HAS_NO_DATE
    }

    if ( $RssCategoryPropertyName -eq "" ) {
      "$(get-date -format u) [RSS]   - Post without Categories - $($XmlPost.title)" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      $NormalizedPost.DebugCodes    += $FEED_FORMAT_HAS_NO_CATEGORIES
    } elseif ( $XmlPost.category.$RssCategoryPropertyName -eq $null ) {
      "$(get-date -format u) [RSS]   - Post without Categories - $($XmlPost.title)" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      $NormalizedPost.DebugCodes    += $FEED_FORMAT_HAS_NO_CATEGORIES
    }
  }

  return $NormalizedPost
}


function Get-RawFeedMetadata( [string[]] $from = $( ( Get-ChildItem $FeedsCacheDir\*.* -include *.rss,*.atom,*.rdf,*.xml ).name ) ) {
  <#
    .SYNOPSIS
      Analizes a given feed file(s) and returns all the relevant meta data.

    .DESCRIPTION
      Analizes a given feed file(s) and returns all the relevant meta data. Feed sources used are usually the ones previously loaded using Backup-RawFeedContent.

    .EXAMPLE
      $PostsInfo = Get-RawFeedMetadata
      $PostsInfo = Get-RawFeedMetadata -from MyBlog.xml

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  $LogFileName        = "FeedModule-MetaData"
  $DumpFileName       = "FeedModule-RawDump"

  $ExecutionTime      = [Diagnostics.Stopwatch]::StartNew()
  $ExecutionTime.Stop()

  $FeedsProcessed     = 1
  $AverageElapsedTime = 0
  $ElapsedTime        = 0

  $GlobalIssuesCount  = 0
  $FeedIssuesCount    = 0

  [PSObject[]] $posts = @()

  # $DebugPreference = "Continue"


  foreach ( $CurrentFeed in $from ) {
    if ( $AverageElapsedTime -eq 0 ) {
      $AverageElapsedTime = $ExecutionTime.Elapsed.TotalMinutes
    } else {
      $AverageElapsedTime = ( $AverageElapsedTime + $ExecutionTime.Elapsed.TotalMinutes ) / 2
    }

    $ElapsedTime         += $ExecutionTime.Elapsed.TotalMinutes

    Write-Progress -Activity "Processing Feeds ..." -Status "Progress: $FeedsProcessed / $($from.Count) - ETC: $( '{0:#0.00}' -f (( $($from.Count) - $FeedsProcessed ) *  $AverageElapsedTime) ) minutes - Time Elapsed: $( '{0:#0.00}' -f $ElapsedTime ) minutes" -PercentComplete ( ( $FeedsProcessed / $($from.Count) ) * 100 ) -currentOperation $CurrentFeed -Id 0

    $ExecutionTime        = [Diagnostics.Stopwatch]::StartNew()

    Write-Debug ""
    Write-Debug "Current Feed:           $CurrentFeed"

    "$(get-date -format u) [START] - $CurrentFeed" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    $CurrentContent       = Get-Content $FeedsCacheDir\$CurrentFeed
    $CurrentSourceDomain  = ""
    $CurrentLanguage      = ""
    $PostsProcessed       = 1

    # Content is an RSS or WXR feed
    if ( ([xml] $CurrentContent).rss -ne $null ) {
      Write-Debug "Feed Type:              RSS or WXR"

      Try {
        if ( ([xml] $CurrentContent).rss.channel.link.href -eq $null ) {
          $CurrentSourceDomain         = ([xml] $CurrentContent).rss.channel.link.Split("/")[2]
        } else {
          $CurrentSourceDomain         = ([xml] $CurrentContent).rss.channel.link.href.Split("/")[2]
        }

        $CurrentPostsCount             = ([xml] $CurrentContent).rss.channel.item.count

        $CurrentFeedAuthor             = "Unknown"
        "$(get-date -format u) [RSS]   - Feed Metadata:          FEED_FORMAT_HAS_NO_AUTHOR - $CurrentFeed"     >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "Feed Metadata:          FEED_FORMAT_HAS_NO_AUTHOR"

        if ( ([xml] $CurrentContent).rss.channel.language ) {
          $CurrentFeedLanguage         = ([xml] $CurrentContent).rss.channel.language
        } else {
          $CurrentFeedLanguage         = "Unknown"

          "$(get-date -format u) [RSS]   - Feed Metadata:          FEED_FORMAT_HAS_NO_LANGUAGE - $CurrentFeed" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
          Write-Debug "Feed Metadata:          FEED_FORMAT_HAS_NO_LANGUAGE"
        }

        "$(get-date -format u) [RSS]   - Feed Metadata:          OK - $CurrentFeed"                            >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "Feed Metadata:          OK"
      } Catch {
        "$(get-date -format u) [RSS]   - Feed Metadata:          UNKNOWN_FEED_ERRORS_FOUND - $CurrentFeed"     >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log
        ( ([xml] $CurrentContent).rss | Out-String ).Trim()                                                    >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log
        ( ([xml] $CurrentContent).rss.channel | Out-String ).Trim()                                            >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log
        "-------------------------------------------------------------------------------"                      >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log

        "$(get-date -format u) [RSS]   - Feed Metadata:          UNKNOWN_FEED_ERRORS_FOUND - $CurrentFeed"     >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) [$($($_.FullyQualifiedErrorId | Out-String).Trim())] - $CurrentFeed"            >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "Feed Metadata:          UNKNOWN_FEED_ERRORS_FOUND"
      }

      if ( ([xml] $CurrentContent).rss.wp -ilike "*wordpress.org/export/*" ) {
        $RssDialect = $FEED_FORMAT_IS_WXR
      } else {
        $RssDialect = $FEED_FORMAT_IS_RSS
      }

      ([xml] $CurrentContent).rss.channel.item | ForEach-Object {
        $CurrentBlogPost               = Get-RawFeedPostMetadata -from $_ -format $RssDialect

        Write-Progress -Activity "Parsing Posts ..." -Id 1 -ParentId 0 -Status "Progress: $PostsProcessed / $CurrentPostsCount" -PercentComplete ( ( $PostsProcessed / $CurrentPostsCount ) * 100 ) -currentOperation $CurrentBlogPost.Title

        # Write-Debug "Post Metadata not NULL: $($CurrentBlogPost -ne $null)"

        if ( ( "" -eq $CurrentBlogPost.Author ) -or ( $null -eq $CurrentBlogPost.Author ) ) {
          $CurrentBlogPost.Author      = $CurrentFeedAuthor
          if ( $CurrentFeedAuthor -eq "Unknown" ) { $CurrentBlogPost.DebugCodes += $FEED_FORMAT_HAS_NO_AUTHOR }
        }

        if ( ( "" -eq $CurrentBlogPost.Language ) -or ( $null -eq $CurrentBlogPost.Language ) ) {
          $CurrentBlogPost.Language    = $CurrentFeedLanguage
          if ( $CurrentFeedLanguage -eq "Unknown" ) { $CurrentBlogPost.DebugCodes += $FEED_FORMAT_HAS_NO_LANGUAGE }
        }

        if ( ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_NOT_RECOGNIZED    ) -or ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_HAS_UNKNOWN_ISSUES ) -or
             ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_HAS_NO_COMMENTS   ) -or ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_HAS_NO_DATE        ) -or
             ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_HAS_NO_CATEGORIES ) -or ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_HAS_NO_LANGUAGE    ) -or
             ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_HAS_NO_AUTHOR     ) ) {
          "$(get-date -format u) [RSS]   - Post with issues:       $( Expand-RawFeedDebugCodes $CurrentBlogPost.DebugCodes ) - $CurrentFeed" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
          Write-Debug "Post with issues:       $( Expand-RawFeedDebugCodes $CurrentBlogPost.DebugCodes )"
          $FeedIssuesCount++
        }

        $CurrentBlogPost.SourceDomain  = $CurrentSourceDomain

        $posts                        += $CurrentBlogPost

        $PostsProcessed++
      }
    }

    # Content is an Atom feed
    if ( ([xml] $CurrentContent).feed -ne $null ) {
      Write-Debug "Feed Type:              ATOM"

      Try {
        $CurrentSourceDomain           = ([xml] $CurrentContent).feed.link.href.Split("/")[2]
        $CurrentPostsCount             = ([xml] $CurrentContent).feed.entry.count

        $CurrentFeedLanguage           = "Unknown"
        "$(get-date -format u) [ATOM]  - Feed Metadata:          FEED_FORMAT_HAS_NO_LANGUAGE - $CurrentFeed" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "Feed Metadata:          FEED_FORMAT_HAS_NO_LANGUAGE"

        if ( $null -ne ([xml] $CurrentContent).feed.author.name ) {
          $CurrentFeedAuthor           = ([xml] $CurrentContent).feed.author.name
        } else {
          $CurrentFeedAuthor           = "Unknown"

          "$(get-date -format u) [ATOM]  - Feed Metadata:          FEED_FORMAT_HAS_NO_AUTHOR - $CurrentFeed" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
          Write-Debug "Feed Metadata:          FEED_FORMAT_HAS_NO_AUTHOR"
        }

        "$(get-date -format u) [ATOM]  - Feed Metadata:          OK - $CurrentFeed"                          >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "Feed Metadata:          OK"
      } Catch {
        "$(get-date -format u) [ATOM]  - Feed Metadata:          UNKNOWN_FEED_ERRORS_FOUND - $CurrentFeed"   >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log
        ( ([xml] $CurrentContent).feed | Out-String ).Trim()                                                 >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log
        "-------------------------------------------------------------------------------"                    >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log

        "$(get-date -format u) [ATOM]  - Feed Metadata:          UNKNOWN_FEED_ERRORS_FOUND - $CurrentFeed"   >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) [$($($_.FullyQualifiedErrorId | Out-String).Trim())] - $CurrentFeed"          >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "Feed Metadata:          UNKNOWN_FEED_ERRORS_FOUND"
      }

      ([xml] $CurrentContent).feed.entry | ForEach-Object {
        $CurrentBlogPost               = Get-RawFeedPostMetadata -from $_ -format $FEED_FORMAT_IS_ATOM

        Write-Progress -Activity "Parsing Posts ..." -Id 1 -ParentId 0 -Status "Progress: $PostsProcessed / $CurrentPostsCount" -PercentComplete ( ( $PostsProcessed / $CurrentPostsCount ) * 100 ) -currentOperation $CurrentBlogPost.Title

        # Write-Debug "Post Metadata not NULL: $($CurrentBlogPost -ne $null)"

        if ( ( "" -eq $CurrentBlogPost.Author ) -or ( $null -eq $CurrentBlogPost.Author ) ) {
          $CurrentBlogPost.Author      = $CurrentFeedAuthor
          if ( $CurrentFeedAuthor -eq "Unknown" ) { $CurrentBlogPost.DebugCodes += $FEED_FORMAT_HAS_NO_AUTHOR }
        }

        if ( ( "" -eq $CurrentBlogPost.Language ) -or ( $null -eq $CurrentBlogPost.Language ) ) {
          $CurrentBlogPost.Language    = $CurrentFeedLanguage
          if ( $CurrentFeedLanguage -eq "Unknown" ) { $CurrentBlogPost.DebugCodes += $FEED_FORMAT_HAS_NO_LANGUAGE }
        }

        if ( ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_NOT_RECOGNIZED    ) -or ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_HAS_UNKNOWN_ISSUES ) -or
             ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_HAS_NO_COMMENTS   ) -or ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_HAS_NO_DATE        ) -or
             ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_HAS_NO_CATEGORIES ) -or ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_HAS_NO_LANGUAGE    ) -or
             ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_HAS_NO_AUTHOR ) ) {
          "$(get-date -format u) [ATOM]  - Post with issues:       $( Expand-RawFeedDebugCodes $CurrentBlogPost.DebugCodes ) - $CurrentFeed" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
          Write-Debug "Post with issues:       $( Expand-RawFeedDebugCodes $CurrentBlogPost.DebugCodes )"
          $FeedIssuesCount++
        }

        $CurrentBlogPost.SourceDomain  = $CurrentSourceDomain

        $posts                        += $CurrentBlogPost

        $PostsProcessed++
      }
    }

    # Content is an RDF feed
    if ( ([xml] $CurrentContent).rdf -ne $null ) {
      Write-Debug "Feed Type:              RDF"

      Try {
        $CurrentSourceDomain           = ( ([xml] $CurrentContent).GetEnumerator().childnodes | Where-Object { !$_.encoded } ).about.Split("/")[2]
        $CurrentPostsCount             = ( ([xml] $CurrentContent).GetEnumerator().childnodes | Where-Object { $_.encoded } ).count

        $CurrentFeedAuthor             = "Unknown"
        "$(get-date -format u) [RDF]   - Feed Metadata:          FEED_FORMAT_HAS_NO_AUTHOR - $CurrentFeed"     >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "Feed Metadata:          FEED_FORMAT_HAS_NO_AUTHOR"

        if ( $null -ne ( ([xml] $CurrentContent).GetEnumerator().childnodes | Where-Object { !$_.encoded } ).language ) {
          $CurrentFeedLanguage         = ( ([xml] $CurrentContent).GetEnumerator().childnodes | Where-Object { !$_.encoded } ).language
        } else {
          $CurrentFeedLanguage         = "Unknown"

          "$(get-date -format u) [RDF]   - Feed Metadata:          FEED_FORMAT_HAS_NO_LANGUAGE - $CurrentFeed" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
          Write-Debug "Feed Metadata:          FEED_FORMAT_HAS_NO_LANGUAGE"
        }

        "$(get-date -format u) [RDF] - Feed Metadata:          OK - $CurrentFeed"                              >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "Feed Metadata:          OK"
      } Catch {
        "$(get-date -format u) [RDF] - Feed Metadata:          UNKNOWN_FEED_ERRORS_FOUND - $CurrentFeed"       >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log
        ( ([xml] $CurrentContent).GetEnumerator().childnodes | Where-Object { !$_.encoded } | Out-String ).Trim() >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log
        ( ([xml] $CurrentContent).rdf | Out-String ).Trim()                                                    >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log
        "-------------------------------------------------------------------------------"                      >> $CurrentLogsDir\$DumpFileName-$CurrentSessionId.log

        "$(get-date -format u) [RDF] - Feed Metadata:          UNKNOWN_FEED_ERRORS_FOUND - $CurrentFeed"       >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) [$($($_.FullyQualifiedErrorId | Out-String).Trim())] - $CurrentFeed"            >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "Feed Metadata:          UNKNOWN_FEED_ERRORS_FOUND"
      }

      ([xml] $CurrentContent).GetEnumerator().childnodes | Where-Object { $_.encoded } | ForEach-Object {
        $CurrentBlogPost               = Get-RawFeedPostMetadata -from $_ -format $FEED_FORMAT_IS_RDF

        Write-Progress -Activity "Parsing Posts ..." -Id 1 -ParentId 0 -Status "Progress: $PostsProcessed / $CurrentPostsCount" -PercentComplete ( ( $PostsProcessed / $CurrentPostsCount ) * 100 ) -currentOperation $CurrentBlogPost.Title

        # Write-Debug "Post Metadata not NULL: $($CurrentBlogPost -ne $null)"

        if ( ( "" -eq $CurrentBlogPost.Author ) -or ( $null -eq $CurrentBlogPost.Author ) ) {
          $CurrentBlogPost.Author      = $CurrentFeedAuthor
          if ( $CurrentFeedAuthor -eq "Unknown" ) { $CurrentBlogPost.DebugCodes += $FEED_FORMAT_HAS_NO_AUTHOR }
        }

        if ( ( "" -eq $CurrentBlogPost.Language ) -or ( $null -eq $CurrentBlogPost.Language ) ) {
          $CurrentBlogPost.Language    = $CurrentFeedLanguage
          if ( $CurrentFeedLanguage -eq "Unknown" ) { $CurrentBlogPost.DebugCodes += $FEED_FORMAT_HAS_NO_LANGUAGE }
        }

        if ( ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_NOT_RECOGNIZED    ) -or ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_HAS_UNKNOWN_ISSUES ) -or
             ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_HAS_NO_COMMENTS   ) -or ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_HAS_NO_DATE        ) -or
             ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_HAS_NO_CATEGORIES ) -or ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_HAS_NO_LANGUAGE    ) -or
             ( $CurrentBlogPost.DebugCodes -contains $FEED_FORMAT_HAS_NO_AUTHOR     ) ) {
          "$(get-date -format u) [RDF] - Post with issues:       $( Expand-RawFeedDebugCodes $CurrentBlogPost.DebugCodes ) - $CurrentFeed" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
          Write-Debug "Post with issues:       $( Expand-RawFeedDebugCodes $CurrentBlogPost.DebugCodes )"
          $FeedIssuesCount++
        }

        $CurrentBlogPost.SourceDomain  = $CurrentSourceDomain

        $posts                        += $CurrentBlogPost

        $PostsProcessed++
      }
    }

    "$(get-date -format u) [Feed]  - Posts in the Feed:      $CurrentPostsCount - $CurrentFeed" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Feed]  - Feed Issues identified: $FeedIssuesCount - $CurrentFeed"   >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "Posts in the Feed:      $CurrentPostsCount"
    Write-Debug "Feed Issues identified: $FeedIssuesCount"

    "$(get-date -format u) [END]   - $CurrentFeed"                                              >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    $GlobalIssuesCount += $FeedIssuesCount
    $FeedIssuesCount    = 0

    $ExecutionTime.Stop()

    $FeedsProcessed++
  }

  "$(get-date -format u) [FeedMetaData] - Total posts processed:    $($posts.count)"            >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
  "$(get-date -format u) [FeedMetaData] - Global Issues identified: $GlobalIssuesCount"         >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

  Write-Debug ""
  Write-Debug "Total posts processed:    $($posts.count)"
  Write-Debug "Global Issues identified: $GlobalIssuesCount"

  # $DebugPreference = "SilentlyContinue"

  $posts
}


function Get-RawFeedsTimeLine( $source = $connections.Feeds.DefaultFeedSource ) {
  <#
    .SYNOPSIS
      Composes a Time Line with every post from all the Feed Sources especified.

    .DESCRIPTION
      Composes a Time Line with every post from all the Feed Sources especified. If local data cache is still valid, it will use it as the data source.

    .EXAMPLE
      $FeedRawTimeLine = Get-RawFeedsTimeLine
      $FeedRawTimeLine = Get-RawFeedsTimeLine -source FeedSubscriptions.xml
      $FeedRawTimeLine = Get-RawFeedsTimeLine -source $connections.Feeds.DefaultFeedSource

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  $CacheFile       = "$CurrentCacheDir\FeedsTimeLineCache.xml"

  if ( Test-Path $CacheFile ) {
    [int] $CacheAge = -( Get-ChildItem $CacheFile ).LastWriteTime.Subtract( $( Get-Date ) ).TotalHours

    Write-Debug "[Get-RawFeedsTimeLine] - Current Cache Age: $CacheAge"

    if ( $CacheAge -gt $connections.Feeds.PostsCacheExpiration ) {
      Write-Debug "[Get-RawFeedsTimeLine] - Cache expired. Loading content from the original sources."

      Backup-RawFeedContent -from $( Import-RawFeeds -from $source )
      $TimeLine   += Get-RawFeedMetadata

      $TimeLine | Export-CliXml $CacheFile

      Write-Debug "[Get-RawFeedsTimeLine] - Local cache has been refreshed."
    } else {
      $TimeLine    = Import-CliXml $CacheFile

      Write-Debug "[Get-RawFeedsTimeLine] - Content loaded from Local Cache."
    }
  } else {
    Write-Debug "[Get-RawFeedsTimeLine] - Loading content from the original sources."

    Backup-RawFeedContent -from $( Import-RawFeeds -from $source )
    $TimeLine   += Get-RawFeedMetadata

    $TimeLine | Export-CliXml $CacheFile

    Write-Debug "[Get-RawFeedsTimeLine] - Local cache has been created."
  }

  $TimeLine
}


function Search-RawFeedPost( [string] $text, [ref] $on, [string] $by = "digest" ) {
  <#
    .SYNOPSIS
      Composes a Time Line with every post from all the Feed Sources especified.

    .DESCRIPTION
      Composes a Time Line with every post from all the Feed Sources especified. If local data cache is still valid, it will use it as the data source.

    .EXAMPLE
      $PostFromFeed = Search-RawFeedPost -text $post.NormalizedPost.PermaLink  -on ([ref] $TimeLine) -by PermaLink
      $PostFromFeed = Search-RawFeedPost -text $post.NormalizedPost.PostId     -on ([ref] $TimeLine) -by Id
      $PostFromFeed = Search-RawFeedPost -text $post.NormalizedPost.PostDigest -on ([ref] $TimeLine) -by Digest
      $PostFromFeed = Search-RawFeedPost -text $post.NormalizedPost.PostDigest -on ([ref] $TimeLine)

    .NOTES
      Low-level function. TimeLine is not normalized (is in Raw format)

    .LINK
      N/A
  #>


  $post = $null

  switch ( $by.ToLower() ) {
    "permalink" {
      $on.Value | ForEach-Object {
        if ( $text -eq $_.PermaLink ) {
          $post = $_

          break
        }
      }
    }

    "id" {
      $on.Value | ForEach-Object {
        if ( $text -eq $_.PostId ) {
          $post = $_

          break
        }
      }
    }

    default {
      $on.Value | ForEach-Object {
        if ( $text -eq $_.PostDigest ) {
          $post = $_

          break
        }
      }
    }
  }

  $post
}


# --------------------------------------------------------------------------------------------------


function Get-FeedTimeLine( [string] $from = $connections.Feeds.DefaultFeedSource ) {
  <#
    .SYNOPSIS
      Composes a Time Line with every post from all the Feed Sources especified.

    .DESCRIPTION
      Composes a Time Line with every post from all the Feed Sources especified. If local data cache is still valid, it will use it as the data source.

    .EXAMPLE
      $FeedTimeLine = Get-FeedTimeLine -quick

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  # $DebugPreference = "Continue"

  [PSObject[]] $RawTimeLine                = @()
  [System.Collections.ArrayList] $TimeLine = @()

  $RawTimeLine        += Get-RawFeedsTimeLine -source $from
  $results             = $RawTimeLine.Count

  if ( $quick ) {
    $i                 = 1
    $ExecutionTime     = [Diagnostics.Stopwatch]::StartNew()
    $ExecutionTime.Stop()

    foreach ( $post in $RawTimeLine ) {
      Write-Progress -Activity "Normalizing Information (QuickMode) ..." -Status "Progress: $i / $results - ETC: $( '{0:#0.00}' -f (( $results - $i ) * $ExecutionTime.Elapsed.TotalMinutes ) ) minutes - Time Elapsed: $( '{0:#0.00}' -f (( $i - 1 ) * $ExecutionTime.Elapsed.TotalMinutes ) ) minutes" -PercentComplete ( ( $i / $results ) * 100 )

      $ExecutionTime   = [Diagnostics.Stopwatch]::StartNew()

      $NormalizedPost  = $post | ConvertTo-FeedNormalizedPost

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

      $NormalizedPost  = $post | ConvertTo-FeedNormalizedPost -IncludeAll

      $TimeLine.Add( $( $NormalizedPost | ConvertTo-JSON -Compress ) ) | Out-Null

      $ExecutionTime.Stop()

      $i++
    }
  }

  $TimeLine | ForEach-Object { ConvertFrom-JSON $_ }

  # $DebugPreference = "SilentlyContinue"
}


function ConvertTo-FeedNormalizedPost( [switch] $IncludeAll, [string] $schema = $SCHEMA_DEFAULT ) {
  <#
    .SYNOPSIS
      Normalizes post information by mapping different data structures into a normalized one. Additionally, it also gathers additional relevant information about that post.

    .DESCRIPTION
      Normalizes post information by mapping different data structures into a normalized one. Additionally, it also gathers additional relevant information about that post.

    .EXAMPLE
      $NormalizedPosts  = $FeedPost  | ConvertTo-FeedNormalizedPost -IncludeAll
      $NormalizedPosts += $FeedPosts | ConvertTo-FeedNormalizedPost -IncludeAll

    .NOTES
      High-level function. However, under normal circumstances, an end user shouldn't feel the need to use this function: other high-level functions use of it in order to make this details transparent to the end user.

    .LINK
      N/A
  #>


  begin {
    # $DebugPreference = "Continue"

    $LogFileName              = "FeedModule"

    [PSObject[]] $NewTimeLine = @()
    $TimeToWait               = $connections.Feeds.ApiDelay
  }

  process {
    $post                                               = $_
    $NewPost                                            = New-SMPost -schema $schema
    $NewPost.RetainUntilDate                            = "{0:$DefaultDateFormat}" -f [datetime] ( ( [datetime] $NewPost.RetainUntilDate ).AddDays( $connections.Feeds.DataRetention ) )

    $NewPost.NormalizedPost.PostId                      = Get-SMPostDigest $post.PermaLink
    $NewPost.NormalizedPost.PostDigest                  = Get-SMPostDigest $post.Title

    $NewPost.NormalizedPost.PermaLink                   = if ( $connections.Feeds.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.PermaLink    } else { Get-SMPostDigest $post.PermaLink    }

    $NewPost.NormalizedPost.ChannelName                 = if ( $connections.Feeds.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.SourceDomain } else { Get-SMPostDigest $post.SourceDomain }

    if ( $connections.Feeds.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) {
      if ( $post.SourceDomain -match "feedburner|feedblitz" ) {
        $NewPost.NormalizedPost.SubChannelName          = $post.PermaLink.Split("/")[2]
        $NewPost.NormalizedPost.SourceDomain            = $post.PermaLink.Split("/")[2]
      } else {
        $NewPost.NormalizedPost.SubChannelName          = $VALUE_NA
        $NewPost.NormalizedPost.SourceDomain            = $post.SourceDomain
      }
    } else {
      if ( $post.SourceDomain -match "feedburner|feedblitz" ) {
        $NewPost.NormalizedPost.SubChannelName          = Get-SMPostDigest $post.PermaLink.Split("/")[2]
        $NewPost.NormalizedPost.SourceDomain            = Get-SMPostDigest $post.PermaLink.Split("/")[2]
      } else {
        $NewPost.NormalizedPost.SubChannelName          = $VALUE_NA
        $NewPost.NormalizedPost.SourceDomain            = Get-SMPostDigest $post.SourceDomain
      }
    }

    $NewPost.NormalizedPost.PostType                    = $POST_TYPE_ARTICLE
    $NewPost.NormalizedPost.ChannelType                 = $CHANNEL_TYPE_BLOG
    $NewPost.NormalizedPost.ChannelDataEngine           = $CHANNEL_DATA_ENGINE_FEED
    $NewPost.NormalizedPost.SourceFormat                = $post.SourceFormat
    $NewPost.NormalizedPost.Language                    = $post.Language

    $NewPost.NormalizedPost.AuthorId                    = Get-SMPostDigest $post.Author
    $NewPost.NormalizedPost.AuthorDisplayName           = if ( $connections.Feeds.PrivacyLevel -le $PRIVACY_LEVEL_MEDIUM ) { $post.Author       } else { Get-SMPostDigest $post.Author       }

    try {
      $NewPost.NormalizedPost.PublishingDate            = "{0:$DefaultDateFormat}" -f [datetime] $post.PublishingDate
    } catch {
      $NewPost.NormalizedPost.PublishingDate            = ( $post.PublishingDate | Out-String ).Trim()

      "$(get-date -format u) [ConvertTo-FeedNormalizedPost] - Invalid DateTime format."                                            >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [ConvertTo-FeedNormalizedPost] -   PostId:         $($NewPost.NormalizedPost.PostId)"                 >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [ConvertTo-FeedNormalizedPost] -   PostDigest:     $($NewPost.NormalizedPost.PostDigest)"             >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [ConvertTo-FeedNormalizedPost] -   ChannelName:    $($NewPost.NormalizedPost.ChannelName)"            >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [ConvertTo-FeedNormalizedPost] -   PublishingDate: $( ( $post.PublishingDate | Out-String ).Trim() )" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[ConvertTo-FeedNormalizedPost] - Invalid DateTime format."
      Write-Debug "[ConvertTo-FeedNormalizedPost] -   PostId:         $($NewPost.NormalizedPost.PostId)"
      Write-Debug "[ConvertTo-FeedNormalizedPost] -   PostDigest:     $($NewPost.NormalizedPost.PostDigest)"
      Write-Debug "[ConvertTo-FeedNormalizedPost] -   ChannelName:    $($NewPost.NormalizedPost.ChannelName)"
      Write-Debug "[ConvertTo-FeedNormalizedPost] -   PublishingDate: $( ( $post.PublishingDate | Out-String ).Trim() )"
    }

    $NewPost.NormalizedPost.Title                       = $post.Title
    $NewPost.NormalizedPost.PostContent                 = $post.Title

    $NewPost.NormalizedPost.SourceApplication           = $VALUE_NA

    $NewPost.NormalizedPost.Categories                  = @()
    $NewPost.NormalizedPost.Tags                        = @()
    $NewPost.NormalizedPost.keywords                    = @()

    $NewPost.NormalizedPost.Categories                  = if ( $post.Categories -eq $null ) { @() } else { if ( $post.Categories.Count -eq 1 ) { @( $post.Categories ) } else { $post.Categories } }
    $NewPost.NormalizedPost.Tags                        = if ( $post.Tags       -eq $null ) { @() } else { if ( $post.Tags.Count       -eq 1 ) { @( $post.Tags       ) } else { $post.Tags       } }
    $NewPost.NormalizedPost.keywords                    = if ( $post.keywords   -eq $null ) { @() } else { if ( $post.keywords.Count   -eq 1 ) { @( $post.keywords   ) } else { $post.keywords   } }

    $NewPost.NormalizedPost.InterestCount               = 0
    $NewPost.NormalizedPost.InteractionsCount           = $post.CommentsCount
    $NewPost.NormalizedPost.AudienceCount               = 0


    $NewPost.DebugCodes                                 = $post.DebugCodes
    $NewPost.RawObject                                  = $post

    Start-Sleep -Seconds $TimeToWait

    $NewPost

    # $DebugPreference = "SilentlyContinue"
  }
}


function Update-FeedPosts( [PSObject[]] $from ) {
  <#
    .SYNOPSIS
      Updates information about a collection of posts. Unlike Update-FeedPost, this function doesn't accept data from the pipeline. Howerver, it does provide feedback about the progress of the update process.

    .DESCRIPTION
      Updates information about a collection of posts. Unlike Update-FeedPost, this function doesn't accept data from the pipeline. Howerver, it does provide feedback about the progress of the update process.

    .EXAMPLE
      $UpdatedFeedTimeLine = Update-FeedPosts -from $NormalizedTimeLine
      $UpdatedFeedTimeLine = Update-FeedPosts -from $PermaLinksList

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

    Write-Debug "[Update-FeedPosts] - CurrentElement:      $i"
    Write-Debug "[Update-FeedPosts] - TotalElements:       $($from.Count)"
    Write-Debug "[Update-FeedPosts] - ElapsedMinutes:      $($ExecutionTime.Elapsed.TotalMinutes)"

    $ExecutionTime = [Diagnostics.Stopwatch]::StartNew()

    $UpdatedPosts.Add( $( $post | Update-FeedPost -IncludeAll | ConvertTo-JSON ) ) | Out-Null

    $ExecutionTime.Stop()

    $i++
  }

  $UpdatedPosts | ForEach-Object { if ( $_ -ne $null ) { ConvertFrom-JSON $_ } }
}


function Update-FeedPost( [switch] $IncludeAll, [string] $schema = $SCHEMA_DEFAULT ) {
  <#
    .SYNOPSIS
      Updates information about a collection of posts. Unlike Update-FeedPosts, this function accepts data from the pipeline. Howerver, it doesn't provide feedback about the progress of the update process.

    .DESCRIPTION
      Updates information about a collection of posts. Unlike Update-FeedPosts, this function accepts data from the pipeline. Howerver, it doesn't provide feedback about the progress of the update process.

    .EXAMPLE
      $UpdatedFeedPost     = $NormalizedFeedPost       | Update-FeedPost -IncludeAll
      $UpdatedFeedTimeLine = $NormalizedFeedTimeLine   | Update-FeedPost -IncludeAll

      $UpdatedFeedPost     = $PermaLink                | Update-FeedPost -IncludeAll
      $UpdatedFeedTimeLine = $PermaLinksList           | Update-FeedPost -IncludeAll

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  begin {
    $LogFileName = "FeedModule"
    $TimeToWait  = $connections.Feeds.ApiDelay
  }

  process {
    $UpdatedPost                             = [PSCustomObject] @{}
    $SearchByPermalink                       = $true # PermaLink Search enforced. Currently, cached is not notrmalized and it lacks a "PostDigest" property

    if ( $_ -is [string] ) {
      $post                                  = New-SMPost -schema $schema
      $post.NormalizedPost.PermaLink         = $_
      $post.NormalizedPost.ChannelDataEngine = $CHANNEL_DATA_ENGINE_FEED

      $SearchByPermalink                     = $true
    } else {
      $post                                  = $_
    }


    if ( $post.NormalizedPost.ChannelDataEngine -eq $CHANNEL_DATA_ENGINE_FEED ) {
      $UpdatedTimeLine               = Get-RawFeedsTimeLine

      if ( $SearchByPermalink ) {
        Write-Debug "[Update-FeedPost] - Searching by PermaLink."

        $PostFromFeed            = Search-RawFeedPost -text $post.NormalizedPost.PermaLink  -on ([ref] $UpdatedTimeLine) -by permalink
      } else {
        Write-Debug "[Update-FeedPost] - Searching by Digest."

        $PostFromFeed            = Search-RawFeedPost -text $post.NormalizedPost.PostDigest -on ([ref] $UpdatedTimeLine)
      }

      if ( $PostFromFeed -eq $null ) {
        "$(get-date -format u) [Update-FeedPost] - Unable to retrieve post: $( $post.NormalizedPost.PermaLink )" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        Write-Debug "[Update-FeedPost] - Unable to retrieve post: $( $post.NormalizedPost.PermaLink )"

        return $null
      } else {
        $PostFromFeed            = $PostFromFeed | ConvertTo-FeedNormalizedPost -IncludeAll
      }
    } else {
      Write-Debug "[Update-FeedPost] - Skipping post not comming from Feeds: $($_.ChannelName)"

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
      Write-Debug "[Update-FeedPost] - Current Property Name: $_"

      if ( $post.NormalizedPost.$_ -ne $null ) {
        $CurrentChanges            = Compare-Object $post.NormalizedPost.$_ $PostFromFeed.NormalizedPost.$_

        if ( $CurrentChanges.Count -ne 0 ) {
          $ChangeLog.TimeStamp     = $UpdatedPost.LastUpdateDate
          $ChangeLog.PropertyName  = $_
          $ChangeLog.OriginalValue = $post.NormalizedPost.$_
          $ChangeLog.NewValue      = $PostFromFeed.NormalizedPost.$_

          [PSObject[]] $UpdatedPost.ChangeLog += $ChangeLog
        }
      }
    }

    $UpdatedPost.NormalizedPost  = $PostFromFeed.NormalizedPost
    [PSObject[]] $UpdatedPost.RawObject += $PostFromFeed.RawObject

    $UpdatedPost
  }
}