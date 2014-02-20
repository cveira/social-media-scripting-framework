<#
-------------------------------------------------------------------------------
Name:    Social Media Scripting Framework
Module:  Data Sets
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





function Find-ObjectPosition( $value, [PSCustomObject[]] $from, [string] $using ) {
  <#
    .SYNOPSIS
      Returns the position of a given value in the supplied object collection.

    .DESCRIPTION
      Returns the position of a given value in the supplied object collection.

    .EXAMPLE
      Find-ObjectPosition -value "https://twitter.com/cveira/status/275929500183830529" -from $DataSet -using PermaLink
      Find-ObjectPosition "https://twitter.com/cveira/status/275929500183830529" -from $DataSet -using PermaLink

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  # $DebugPreference = "Continue"
  if ( $DebugPreference -eq "Continue" ) { $DebugPreference = "SilentlyContinue" }

  $ObjectId      = -1
  $collection    = $from
  $key           = $using

  for ( $i = 0 ; $i -lt $collection.Length ; $i++ ) {
    Write-Debug "[Find-ObjectPosition] - CurrentPosition:         $i"
    Write-Debug "[Find-ObjectPosition] - CurrentValue:            $($collection[$i].$key)"
    Write-Debug "[Find-ObjectPosition] - TargetValue:             $value"

    if ( $collection[$i].$key -eq $value ) {
      $ObjectId  = $i
      break
    }
  }

  Write-Debug "[Find-ObjectPosition] - SelectedValue:           $($collection[$i].$key)"
  Write-Debug "[Find-ObjectPosition] - SelectedPosition:        $ObjectId"

  # $DebugPreference = "SilentlyContinue"
  if ( $DebugPreference -eq "SilentlyContinue" ) { $DebugPreference = "Continue" }

  return $ObjectId
}


function Test-BelongsTo( $value, $collection) {
  <#
    .SYNOPSIS
      Determines if the especified value belongs to a given collection.

    .DESCRIPTION
      Determines if the especified value belongs to a given collection.

    .EXAMPLE
      Test-BelongsTo -value "https://twitter.com/cveira/status/275929500183830529" -collection $Links
      Test-BelongsTo "https://twitter.com/cveira/status/275929500183830529" -collection $Links

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  $ObjectFound = $false

  if ( ( $collection -match $value ).Count -gt 0 ) {
    $ObjectFound = $true
  }

  $ObjectFound
}


function Get-MatchesCount( $value, $collection) {
  <#
    .SYNOPSIS
      Determines the number of times that a especified value appears to a given collection.

    .DESCRIPTION
      Determines the number of times that a especified value appears to a given collection.

    .EXAMPLE
      $NumberOfMatches = Get-MatchesCount -value "https://twitter.com/cveira/status/275929500183830529" -collection $Links
      $NumberOfMatches = Get-MatchesCount "https://twitter.com/cveira/status/275929500183830529" -collection $Links

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  $ObjectsFound  = -1
  $MatchesFound  = ( $collection -match $value ).Count

  if ( $MatchesFound -gt 0 ) {
    $ObjectsFound = $MatchesFound
  }

  $ObjectsFound
}


function Get-MatchesInCollection ( $value, $collection) {
  <#
    .SYNOPSIS
      Gets every matching instance of a especified value in a given collection.

    .DESCRIPTION
      Gets every matching instance of a especified value in a given collection.

    .EXAMPLE
      $Matches = Get-MatchesInCollection -value "https://twitter.com/cveira/status/275929500183830529" -collection $Links
      $Matches = Get-MatchesInCollection "https://twitter.com/cveira/status/275929500183830529" -collection $Links

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  $ObjectsFound  = ""
  $MatchesFound  = $collection -match $value

  if ( $MatchesFound -gt 0 ) {
    $ObjectsFound = $MatchesFound[0].ToString().Trim()
  }

  $ObjectsFound
}


function New-DataSetItem( [PSObject[]] $from, [string] $using ) {
  <#
    .SYNOPSIS
      Creates a new object instance of the especified dataset.

    .DESCRIPTION
      Creates a new object instance of the especified dataset.

    .EXAMPLE
      $NewItem = New-DataSetItem -from $DataSet -using "ObjectId"

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  # $DebugPreference = "Continue"
  if ( $DebugPreference -eq "Continue" ) { $DebugPreference = "SilentlyContinue" }

  $dataset        = $from
  $key            = $using

  $LastItem       = $dataset | Sort-Object $key -descending | Select-Object -first 1
  $schema         = $LastItem | Get-Member -MemberType NoteProperty | Select-Object Name
  $NewItemContent = @{}

  $schema | ForEach-Object {
    if ( $_.Name -eq $key ) {
      Write-Debug "[New-DataSetItem] - Last ObjectId:       $($LastItem.$key)"
      Write-Debug "[New-DataSetItem] - New ObjectId:        $($LastItem.$key + 1)"

      $NewItemContent.Add( $key, $($LastItem.$key + 1) )
    } else {
      $NewItemContent.Add( $_.Name, $empty )
    }
  }

  # $DebugPreference = "SilentlyContinue"
  if ( $DebugPreference -eq "SilentlyContinue" ) { $DebugPreference = "Continue" }

  New-Object PSObject -Property $NewItemContent
}


# --------------------------------------------------------------------------------------------------


function Export-DataSet( [string] $SourceType = "All", [string] $label = "" ) {
  <#
    .SYNOPSIS
      Saves a dataset to disk.

    .DESCRIPTION
      Saves a dataset to disk.

    .EXAMPLE
      $MyCampaign | Export-DataSet
      $MyCampaign | Export-DataSet -SourceType "Facebook" -label "Contest"

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  begin {
    $ObjectState   = @()
    $SourceType    = $SourceType.ToLower().Trim()
    $label         = $label.replace(" ", "_")

		$SessionId     = Get-Date
		$SessionId     = "$($SessionId.Year)$($SessionId.Month)$($SessionId.Day)-$($SessionId.Hour)$($SessionId.Minute)-$($SessionId.Second)-$($SessionId.Millisecond)"

    if ( $label -eq "" ) {
      $StateFile     = ".\DataSet-$SourceType-$SessionId.xml"
    } else {
      $StateFile     = ".\DataSet-$SourceType-$label-$SessionId.xml"
    }
  }

  process {
    $ObjectState += $_
  }

  end {
    Export-CliXml -Path $StateFile -InputObject $ObjectState
  }
}


function Import-DataSet( [string] $file ) {
  <#
    .SYNOPSIS
      Loads a dataset from disk.

    .DESCRIPTION
      Loads a dataset from disk.

    .EXAMPLE
      $MyCampaign       = Load-DataSet ".\DataSet-All-201359-128-45-741.xml"
      $ExpandedTimeLine = Load-DataSet ".\DataSet-All-ExpandedDataset-201359-128-45-741.xml"

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  if ( Test-Path $file ) {
    Import-CliXml $file
  } else {
    ""
  }
}


function Update-DataSet( $DataSet, $with, [HashTable] $using = @{}, $BindByName = $false ) {
  function Update-DataSet2( $DataSet, $with, [HashTable] $using = @{}, $BindByName = $false ) {
    <#
      .SYNOPSIS
        Updates a dataset using a set of predefined updating rules.

      .DESCRIPTION
        Updates a dataset using a set of predefined updating rules.

        The default mapping rules are stored on "update-rules.ps1" under your current profile.

        /// Mapping rules structure:

        -using @{
          [KeyProperty    = "SourceProperyNamePattern", "DestinationProperyNamePattern"]

          <PropertyName1> = "SourceProperyNamePattern", "DestinationProperyNamePattern", "<ADD|[OVERWRITE]>"
          <PropertyName2> = "@Literal",                 "DestinationProperyNamePattern", "<ADD|[OVERWRITE]>"
          <PropertyName3> = "&{ScriptBlock}",           "DestinationProperyNamePattern", "<ADD|[OVERWRITE]>"
        }

        EXAMPLES:

        /// For Facebook TimeLines:

        Update-DataSet $campaign -with $FBTimeLine -using @{
          KeyProperty = "PermaLink",                         "PermaLink"

          Done        = "@yes",                              "Done",           "OVERWRITE"
          Channel     = "@facebook",                         "Channel",        "OVERWRITE"
          Subchannel  = "@MyFacebookPage",                   "Subchannel",     "OVERWRITE"
          Scope       = "@global",                           "Scope",          "OVERWRITE"
          Likes       = "likes_count",                       "Likes",          "OVERWRITE"
          Comments    = "comments_count",                    "Conversations",  "OVERWRITE"
          Shares      = "shares_count",                      "Conversations",  "ADD"
          Audience    = "audience_count",                    "Audience",       "OVERWRITE"
          Story       = "Message",                           "Story",          "OVERWRITE"
          Title       = "Name",                              "Title",          "OVERWRITE"
          Description = "Description",                       "Description",    "OVERWRITE"
          ShortLink   = "Link",                              "Short",          "OVERWRITE"
          Date        = "created",                           "Date",           "OVERWRITE"
          LastUpdate  = "&{(Get-Date).ToShortDateString()}", "LastUpdateDate", "OVERWRITE"
        }

        Update-DataSet $campaign -with $FBTimeLine -using @{
          Done        = "@yes",                              "Done"
          Channel     = "@facebook",                         "Channel"
          Subchannel  = "@MyFacebookPage",                   "Subchannel"
          Scope       = "@global",                           "Scope"
          Likes       = "likes_count",                       "Likes"
          Comments    = "comments_count",                    "Conversations"
          Shares      = "shares_count",                      "Conversations",  "ADD"
          Audience    = "audience_count",                    "Audience"
          Story       = "Message",                           "Story"
          Title       = "Name",                              "Title"
          Description = "Description",                       "Description"
          ShortLink   = "Link",                              "Short"
          Date        = "created",                           "Publishing_Date"
          LastUpdate  = "&{(Get-Date).ToShortDateString()}", "LastUpdateDate"
        }

      .EXAMPLE
        $UpdatedCampaign = Update-DataSet $campaign -with $SourceDataSet -BindByName
        $UpdatedCampaign = Update-DataSet $campaign -with $SourceDataSet -using $FacebookRules
        $UpdatedCampaign = $(Update-DataSet $campaign -with $FBTimeLine -using $MappingRules) -ne $null

      .NOTES
        High-level function.

      .LINK
        N/A
    #>


    # $DebugPreference = "Continue"

    $LogFileName                 = "DataSetModule"

    $SourceSchema                = @()
    [System.Collections.ArrayList] $UpdatedDataSet = @()
    [PSObject]   $NewItem

    [PSObject[]] $SourceDataSet  = $with


    $BIG_DATASET                 = 200
    $ObjectCount                 = 0

    $OBJECT_NOT_FOUND            = -1
    $SOURCE_PROPERTY             = 0
    $DESTINATION_PROPERTY        = 1
    $REQUESTED_OPERATION         = 2

    $OPERATION_OVERWRITE         = "OVERWRITE"
    $OPERATION_ADD               = "ADD"
    $OPERATION_DEFAULT           = $OPERATION_OVERWRITE

    $DEFINE_LITERAL              = "@"
    $DEFINE_SCRIPTBLOCK          = "&"

    if ( $using.count -eq 0 ) {
      $rules                     = @{ KeyProperty = "PermaLink", "PermaLink" }
      $BindByName                = $true
    } else {
      $rules                     = $using
      $BindByName                = $false

      if ( !$rules.ContainsKey("KeyProperty") ) {
        $rules.Add( "KeyProperty", @("PermaLink", "PermaLink") )
      }
    }

    [string[]] $PropertyNames    = @()
    $DataOnlyRules               = $rules.Keys | Select-String -NotMatch "KeyProperty"
    $DataOnlyRules | ForEach-Object { $PropertyNames += $_.ToString().Trim() }

    $TargetSchema                = $DataSet | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }


    $SourceDataSet | ForEach-Object {
      Write-Debug "[Update-DataSet] - New Item"

      $SourceData                = $_

      if ( $SourceData -eq $null ) { return }

      if ( $SourceSchema.count -eq 0 ) {
        $SourceSchema            = $SourceData | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }

        if ( $SourceDataSet.count -gt $BIG_DATASET ) {
          $ExecutionTime         = [Diagnostics.Stopwatch]::StartNew()
          $ExecutionTime.Stop()
        }
      }


      if ( $SourceDataSet.count -gt $BIG_DATASET ) {
        $ObjectCount++

        Write-Progress -Activity "Updating Data Set ..." -Status "Progress: $ObjectCount / $($SourceDataSet.Count) - ETC: $( '{0:#0.00}' -f (( $SourceDataSet.Count - $ObjectCount ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes - Time Elapsed: $( '{0:#0.00}' -f (( $ObjectCount - 1 ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes" -PercentComplete ( ( $ObjectCount / $SourceDataSet.Count ) * 100 )

        $ExecutionTime           = [Diagnostics.Stopwatch]::StartNew()
      }


      $SourceKeyName            = Get-MatchesInCollection  $rules.KeyProperty[$SOURCE_PROPERTY]      $SourceSchema
      $DestinationKeyName       = Get-MatchesInCollection  $rules.KeyProperty[$DESTINATION_PROPERTY] $TargetSchema

      Write-Debug "[Update-DataSet] -   SourceKeyName:           $SourceKeyName"
      Write-Debug "[Update-DataSet] -   DestinationKeyName:      $DestinationKeyName"
      Write-Debug "[Update-DataSet] -   UpdatedDataSet.count:    $($UpdatedDataSet.count)"
      Write-Debug "[Update-DataSet]"

      # $position                 = Find-ObjectPosition -value $SourceData.$($rules.KeyProperty[$SOURCE_PROPERTY]) -from $DataSet -using $rules.KeyProperty[$DESTINATION_PROPERTY]
      $position                 = Find-ObjectPosition -value $SourceData.$SourceKeyName -from $DataSet -using $DestinationKeyName

      Write-Debug "[Update-DataSet] -   position:                $position"

      $NewItem                  = $null

      if ( $position -eq $OBJECT_NOT_FOUND ) {
        Write-Debug "[Update-DataSet] -     Object not found. Creating new object."

        if ( $UpdatedDataSet.count -eq 0 ) {
          $NewItem              = New-DataSetItem -from $DataSet        -using "ObjectId"
        } else {
          $NewItem              = New-DataSetItem -from $UpdatedDataSet -using "ObjectId"
        }
      } else {
        Write-Debug "[Update-DataSet] -     Object found. Cloning existing object."

        $NewItem                = $DataSet[$position]
      }

      Write-Debug "[Update-DataSet]"


      # Binding properties by Name

      if ( $BindByName ) {
        Write-Debug "[Update-DataSet] -   Binding by Name."

        if ( $SourceSchema.Count -lt $TargetSchema.Count ) {
          foreach ( $property in $SourceSchema ) {
            $LazyPropertyName             = Get-MatchesInCollection  $property $TargetSchema

            Write-Debug "[Update-DataSet] -     SourcePropertyName:      $property"
            Write-Debug "[Update-DataSet] -     DestinationPropertyName: $LazyPropertyName"

            if ( $LazyPropertyName -ne "" ) {
              $NewItem.$LazyPropertyName  = $SourceData.$property
            }
          }
        } else {
          foreach ( $property in $TargetSchema ) {
            $LazyPropertyName     = Get-MatchesInCollection  $property $SourceSchema

            Write-Debug "[Update-DataSet] -     SourcePropertyName:      $LazyPropertyName"
            Write-Debug "[Update-DataSet] -     DestinationPropertyName: $property"

            if ( $LazyPropertyName -ne "" ) {
              $NewItem.$property  = $SourceData.$LazyPropertyName
            }
          }
        }

        Write-Debug "[Update-DataSet]"
      }

      # Binding properties as defined in Mapping Rules

      if ( $PropertyNames.Count -gt 0 ) {
        Write-Debug "[Update-DataSet] -   Binding by Mapping Rules."

        foreach ( $PropertyName in $PropertyNames ) {
          $DestinationPropertyName = Get-MatchesInCollection  $rules.$PropertyName[$DESTINATION_PROPERTY] $TargetSchema

          Write-Debug "[Update-DataSet] -     DestinationPropertyName: $DestinationPropertyName"

          if ( $rules.$PropertyName[$SOURCE_PROPERTY].SubString(0,1) -eq $DEFINE_LITERAL ) {
            $content = $rules.$PropertyName[$SOURCE_PROPERTY].SubString(1, ($rules.$PropertyName[$SOURCE_PROPERTY].Length - 1))

            Write-Debug "[Update-DataSet] -     Rule contains a Literal"
            Write-Debug "[Update-DataSet] -       Content:               $content"

            if ( ( $content -ne "" ) -and ( $DestinationPropertyName -ne "" ) ) {
              if ( $rules.$PropertyName[$REQUESTED_OPERATION] -eq $null ) {
                $NewItem.$DestinationPropertyName  = $content
              } elseif ( $rules.$PropertyName[$REQUESTED_OPERATION] -eq $OPERATION_OVERWRITE ) {
                $NewItem.$DestinationPropertyName  = $content
              } elseif ( $rules.$PropertyName[$REQUESTED_OPERATION] -eq $OPERATION_ADD ) {
                $NewItem.$DestinationPropertyName += $content
              }
            } else {
              "$(get-date -format u) [Update-DataSet] - SKIPPING RULE: unable to bind $PropertyName" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

              Write-Debug "[Update-DataSet] -     SKIPPING RULE: unable to bind $PropertyName"
            }
          } elseif ( $rules.$PropertyName[$SOURCE_PROPERTY].SubString(0,1) -eq $DEFINE_SCRIPTBLOCK ) {
            $content = Invoke-Expression $rules.$PropertyName[$SOURCE_PROPERTY]

            Write-Debug "[Update-DataSet] -     Rule contains a ScriptBlog"
            Write-Debug "[Update-DataSet] -       Content:               $content"

            if ( ( $content -ne "" ) -and ( $DestinationPropertyName -ne "" ) ) {
              if ( $rules.$PropertyName[$REQUESTED_OPERATION] -eq $null ) {
                $NewItem.$DestinationPropertyName  = $content
              } elseif ( $rules.$PropertyName[$REQUESTED_OPERATION] -eq $OPERATION_OVERWRITE ) {
                $NewItem.$DestinationPropertyName  = $content
              } elseif ( $rules.$PropertyName[$REQUESTED_OPERATION] -eq $OPERATION_ADD ) {
                $NewItem.$DestinationPropertyName += $content
              }
            } else {
              "$(get-date -format u) [Update-DataSet] - SKIPPING RULE: unable to bind $PropertyName" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

              Write-Debug "[Update-DataSet] -     SKIPPING RULE: unable to bind $PropertyName"
            }
          } else {
            $SourcePropertyName      = Get-MatchesInCollection  $rules.$PropertyName[$SOURCE_PROPERTY] $SourceSchema

            Write-Debug "[Update-DataSet] -     Standard Rule: mapping content from Source Property"
            Write-Debug "[Update-DataSet] -       SourcePropertyName:    $SourcePropertyName"
            Write-Debug "[Update-DataSet] -       Content:               $( $SourceData.$SourcePropertyName )"

            if ( ( $SourcePropertyName -ne "" ) -and ( $DestinationPropertyName -ne "" ) ) {
              if ( $rules.$PropertyName[$REQUESTED_OPERATION] -eq $null ) {
                $NewItem.$DestinationPropertyName  = $SourceData.$SourcePropertyName
              } elseif ( $rules.$PropertyName[$REQUESTED_OPERATION] -eq $OPERATION_OVERWRITE ) {
                $NewItem.$DestinationPropertyName  = $SourceData.$SourcePropertyName
              } elseif ( $rules.$PropertyName[$REQUESTED_OPERATION] -eq $OPERATION_ADD ) {
                $NewItem.$DestinationPropertyName += $SourceData.$SourcePropertyName
              }
            } else {
              "$(get-date -format u) [Update-DataSet] - SKIPPING RULE: unable to bind $PropertyName" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

              Write-Debug "[Update-DataSet] -     SKIPPING RULE: unable to bind $PropertyName"
            }
          }

          Write-Debug "[Update-DataSet]"
        }
      }


      $NewItem.$DestinationKeyName = $SourceData.$SourceKeyName
      $UpdatedDataSet.Add( $NewItem ) | Out-Null


      if ( $SourceDataSet.count -gt $BIG_DATASET ) {
        $ExecutionTime.Stop()
      }

      Write-Debug "[Update-DataSet] -   UpdatedDataSet.count:    $($UpdatedDataSet.count)"
      Write-Debug "[Update-DataSet]"
    }

    Write-Debug "[Update-DataSet] - UpdatedDataSet.count:    $($UpdatedDataSet.count)"

    # $DebugPreference = "SilentlyContinue"

    $UpdatedDataSet | ForEach-Object { if ( $_ -ne $null ) { $_ } }
  }


  # Workaround to avoid $null value that gets appended by the assignment operator

  $OutPut = Update-DataSet2 $DataSet -with $with -using $using $BindByName

  return $OutPut -ne $null
}