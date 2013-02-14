<#
-------------------------------------------------------------------------------
Name:    Social Media Scripting Framework
Module:  Data Sets
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


function Save-DataSet( [string] $SourceType = "twitter", [string] $label = "" ) {
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


function Load-DataSet( [string] $file ) {
  if ( Test-Path $file ) {
    Import-CliXml $file
  } else {
    ""
  }
}


function FindObjectPosition( [PSCustomObject[]] $collection, [string] $key, $value ) {
  # $DebugPreference = "Continue"

  $ObjectId      = -1

  for ( $i = 0 ; $i -lt $collection.Length ; $i++ ) {
    Write-Debug "CurrentPosition:         $i"
    Write-Debug "CurrentValue:            $($collection[$i].$key)"
    Write-Debug "TargetValue:             $value"

    if ( $collection[$i].$key -eq $value ) {
      $ObjectId  = $i
      break
    }
  }

  Write-Debug "SelectedValue:           $($collection[$i].$key)"
  Write-Debug "SelectedPosition:        $ObjectId"

  # $DebugPreference = "SilentlyContinue"

  return $ObjectId
}


function BelongsToCollection( $name, $collection) {
  $ObjectFound = $false

  if ( ( $collection -match $name ).Count -gt 0 ) {
    $ObjectFound = $true
  }

  $ObjectFound
}


function MatchesCollectionMembers( $name, $collection) {
  $ObjectsFound  = -1
  $MatchesFound  = ( $collection -match $name ).Count

  if ( $MatchesFound -gt 0 ) {
    $ObjectsFound = $MatchesFound
  }

  $ObjectsFound
}


function GetMatchesInCollection( $name, $collection) {
  $ObjectsFound  = ""
  $MatchesFound  = $collection -match $name

  if ( $MatchesFound -gt 0 ) {
    $ObjectsFound = $MatchesFound[0].ToString().Trim()
  }

  $ObjectsFound
}


function Update-DataSet( $DataSet, $with, [HashTable] $using = @{}, $BindByName = $false ) {
  <#
    /// Mapping rules structure:

    -using @{
      [KeyProperty    = "SourceProperyNamePattern", "DestinationProperyNamePattern"]

      <PropertyName1> = "SourceProperyNamePattern", "DestinationProperyNamePattern", "<ADD|[OVERWRITE]>"
      <PropertyName2> = "@Literal",                 "DestinationProperyNamePattern", "<ADD|[OVERWRITE]>"
      <PropertyName3> = "&{ScriptBlock}",           "DestinationProperyNamePattern", "<ADD|[OVERWRITE]>"
    }


    /// Basic usage:

    Update-DataSet $DestinationDataSet -with $SourceDataSet -BindByName
    Update-DataSet $DestinationDataSet -with $SourceDataSet -using  $FacebookRules


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

  #>

  # $DebugPreference = "Continue"


  $SourceSchema                = @()
  [PSObject[]] $UpdatedDataSet = @()
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
    Write-Debug ""
    Write-Debug "====================================================================="

    $SourceData                = $_

    if ( $SourceData -eq $null ) { return }

    if ( $SourceSchema.count -eq 0 ) {
      $SourceSchema            = $SourceData | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }

      if ( $SourceDataSet.count -gt $BIG_DATASET ) {
        $ExecutionTime         = [Diagnostics.Stopwatch]::StartNew()
      }
    }


    if ( $SourceDataSet.count -gt $BIG_DATASET ) {
      $ObjectCount++
      $ExecutionTime.Stop()

      Write-Progress -Activity "Updating Data Set ..." -Status "Progress: $ObjectCount / $($SourceDataSet.Count) - ETC: $( '{0:#0.00}' -f (( $SourceDataSet.Count - $ObjectCount ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes - Time Elapsed: $( '{0:#0.00}' -f (( $ObjectCount - 1 ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes" -PercentComplete ( ( $ObjectCount / $SourceDataSet.Count ) * 100 )

      $ExecutionTime           = [Diagnostics.Stopwatch]::StartNew()
    }


    $SourceKeyName            = GetMatchesInCollection $rules.KeyProperty[$SOURCE_PROPERTY]      $SourceSchema
    $DestinationKeyName       = GetMatchesInCollection $rules.KeyProperty[$DESTINATION_PROPERTY] $TargetSchema

    Write-Debug "SourceKeyName:           $SourceKeyName"
    Write-Debug "DestinationKeyName:      $DestinationKeyName"
    Write-Debug "UpdatedDataSet.count:    $($UpdatedDataSet.count)"

    # $position                 = FindObjectPosition -collection $DataSet -key $rules.KeyProperty[$DESTINATION_PROPERTY] -value $SourceData.$($rules.KeyProperty[$SOURCE_PROPERTY])
    $position                 = FindObjectPosition -collection $DataSet -key $DestinationKeyName -value $SourceData.$SourceKeyName


    $NewItem                  = $null

    if ( $position -eq $OBJECT_NOT_FOUND ) {
      if ( $UpdatedDataSet.count -eq 0 ) {
        $NewItem              = New-DataSetItem -dataset $DataSet        -key "ObjectId"
      } else {
        $NewItem              = New-DataSetItem -dataset $UpdatedDataSet -key "ObjectId"
      }
    } else {
      $NewItem                = $DataSet[$position]
    }

    # Binding properties by Name

    if ( $BindByName ) {
      if ( $SourceSchema.Count -lt $TargetSchema.Count ) {
        foreach ( $property in $SourceSchema ) {
          $LazyPropertyName             = GetMatchesInCollection $property $TargetSchema

          Write-Debug "SourcePropertyName:      $property"
          Write-Debug "DestinationPropertyName: $LazyPropertyName"

          if ( $LazyPropertyName -ne "" ) {
            $NewItem.$LazyPropertyName  = $SourceData.$property
          }
        }
      } else {
        foreach ( $property in $TargetSchema ) {
          $LazyPropertyName     = GetMatchesInCollection $property $SourceSchema

          Write-Debug "SourcePropertyName:      $LazyPropertyName"
          Write-Debug "DestinationPropertyName: $property"

          if ( $LazyPropertyName -ne "" ) {
            $NewItem.$property  = $SourceData.$LazyPropertyName
          }
        }
      }
    }

    # Binding properties as defined in Mapping Rules

    if ( $PropertyNames.Count -gt 0 ) {
      foreach ( $PropertyName in $PropertyNames ) {
        $DestinationPropertyName = GetMatchesInCollection $rules.$PropertyName[$DESTINATION_PROPERTY] $TargetSchema

        Write-Debug "DestinationPropertyName: $DestinationPropertyName"

        if ( $rules.$PropertyName[$SOURCE_PROPERTY].SubString(0,1) -eq $DEFINE_LITERAL ) {
          $content = $rules.$PropertyName[$SOURCE_PROPERTY].SubString(1, ($rules.$PropertyName[$SOURCE_PROPERTY].Length - 1))

          Write-Debug "content:                 $content"

          if ( ( $content -ne "" ) -and ( $DestinationPropertyName -ne "" ) ) {
            if ( $rules.$PropertyName[$REQUESTED_OPERATION] -eq $null ) {
              $NewItem.$DestinationPropertyName  = $content
            } elseif ( $rules.$PropertyName[$REQUESTED_OPERATION] -eq $OPERATION_OVERWRITE ) {
              $NewItem.$DestinationPropertyName  = $content
            } elseif ( $rules.$PropertyName[$REQUESTED_OPERATION] -eq $OPERATION_ADD ) {
              $NewItem.$DestinationPropertyName += $content
            }
          } else {
            Write-Debug "SKIPPING RULE: unable to bind $PropertyName"
          }
        } elseif ( $rules.$PropertyName[$SOURCE_PROPERTY].SubString(0,1) -eq $DEFINE_SCRIPTBLOCK ) {
          $content = Invoke-Expression $rules.$PropertyName[$SOURCE_PROPERTY]

          Write-Debug "content:                 $content"

          if ( ( $content -ne "" ) -and ( $DestinationPropertyName -ne "" ) ) {
            if ( $rules.$PropertyName[$REQUESTED_OPERATION] -eq $null ) {
              $NewItem.$DestinationPropertyName  = $content
            } elseif ( $rules.$PropertyName[$REQUESTED_OPERATION] -eq $OPERATION_OVERWRITE ) {
              $NewItem.$DestinationPropertyName  = $content
            } elseif ( $rules.$PropertyName[$REQUESTED_OPERATION] -eq $OPERATION_ADD ) {
              $NewItem.$DestinationPropertyName += $content
            }
          } else {
            Write-Debug "SKIPPING RULE: unable to bind $PropertyName"
          }
        } else {
          $SourcePropertyName      = GetMatchesInCollection $rules.$PropertyName[$SOURCE_PROPERTY] $SourceSchema

          Write-Debug "SourcePropertyName:      $SourcePropertyName"

          if ( ( $SourcePropertyName -ne "" ) -and ( $DestinationPropertyName -ne "" ) ) {
            if ( $rules.$PropertyName[$REQUESTED_OPERATION] -eq $null ) {
              $NewItem.$DestinationPropertyName  = $SourceData.$SourcePropertyName
            } elseif ( $rules.$PropertyName[$REQUESTED_OPERATION] -eq $OPERATION_OVERWRITE ) {
              $NewItem.$DestinationPropertyName  = $SourceData.$SourcePropertyName
            } elseif ( $rules.$PropertyName[$REQUESTED_OPERATION] -eq $OPERATION_ADD ) {
              $NewItem.$DestinationPropertyName += $SourceData.$SourcePropertyName
            }
          } else {
            Write-Debug "SKIPPING RULE: unable to bind $PropertyName"
          }
        }
      }
    }


    $NewItem.$DestinationKeyName = $SourceData.$SourceKeyName
    $UpdatedDataSet             += $NewItem

    Write-Debug "UpdatedDataSet.count:    $($UpdatedDataSet.count)"
  }

  Write-Debug "UpdatedDataSet.count:    $($UpdatedDataSet.count)"

  # $DebugPreference = "SilentlyContinue"

  $UpdatedDataSet
}


function New-DataSetItem( [PSObject[]] $dataset, [string] $key ) {
  # $DebugPreference = "Continue" | "SilentlyContinue"

  $LastItem       = $dataset | Sort-Object $key -descending | Select-Object -first 1
  $schema         = $LastItem | Get-Member -MemberType NoteProperty | Select-Object Name
  $NewItemContent = @{}

  $schema | ForEach-Object {
    if ( $_.Name -eq $key ) {
      Write-Debug "[INFO] Last ObjectId:       $($LastItem.$key)"
      Write-Debug "[INFO] New ObjectId:        $($LastItem.$key + 1)"

      $NewItemContent.Add( $key, $($LastItem.$key + 1) )
    } else {
      $NewItemContent.Add( $_.Name, $empty )
    }
  }

  New-Object PSObject -Property $NewItemContent
}