<#
-------------------------------------------------------------------------------
Name:    Social Media Scripting Framework
Module:  Microsoft Excel
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


$FIRST_DATA_ROW    = 3
$FIRST_DATA_COLUMN = 2

Add-Type -Path "$BinDir\EPPlus.dll"


function Open-RawExcelFile( [string] $file ) {
  <#
    .SYNOPSIS
      Opens an Excel file.

    .DESCRIPTION
      Opens an Excel file.

    .EXAMPLE
      $book = Open-RawExcelFile ".\excel.xlsx"

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  if ( Test-Path $file ) {
    try {
      $FullName = ( Get-ChildItem $file ).FullName

       New-Object OfficeOpenXml.ExcelPackage $( [System.IO.FileInfo] $FullName )
    } catch {
      "$(get-date -format u) [Open-RawExcelFile] - Can't open the Excel file."                    >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Open-RawExcelFile] -   File Name:         $file"                    >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Open-RawExcelFile] -   Exception Details: $( $Error.Exception[0] )" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Open-RawExcelFile] - Can't open the Excel file."
      Write-Debug "[Open-RawExcelFile] -   File Name:         $file"
      Write-Debug "[Open-RawExcelFile] -   Exception Details: $( $Error.Exception[0] )"

      return $null
    }
  } else {
    "$(get-date -format u) [Open-RawExcelFile] - The file doesn't exist." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Open-RawExcelFile] -   File Name: $file"      >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Open-RawExcelFile] - The file doesn't exist."
    Write-Debug "[Open-RawExcelFile] -   File Name: $file"

    return $null
  }
}


function Get-RawExcelHeaders( $sheet, [int[]] $DataStart = @( $FIRST_DATA_ROW, $FIRST_DATA_COLUMN ) ) {
  <#
    .SYNOPSIS
      Extracts the column structure for the especified excel sheet.

    .DESCRIPTION
      Extracts the column structure for the especified excel sheet.

    .EXAMPLE
      $CampaignInfoSchema = Get-RawExcelHeaders -sheet $CampaignDataSource
      $CampaignInfoSchema = Get-RawExcelHeaders -sheet $CampaignDataSource -DataStart 4,2

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  $header     = @{}
  $HeaderItem = ""
  $column     = $DataStart[1]
  $HeadersRow = $DataStart[0] - 1

  # $DebugPreference = "Continue"
  if ( $DebugPreference -eq "Continue" ) { $DebugPreference = "SilentlyContinue" }

  Write-Debug "[Get-RawExcelHeaders] - Headers Row is: $HeadersRow"

  if ( $sheet -ne $null ) {
    do {
      $HeaderItem = $sheet.Cells.Item( $HeadersRow, $column ).Value

      Write-Debug "[Get-RawExcelHeaders] - Discovered Column Name: $HeaderItem"

      if ( $HeaderItem ) {
        $HeaderItem = Get-RawNormalizedPropertyName $HeaderItem

        $header.Add( $HeaderItem, $column )
        $column++
      }
    } until ( !$HeaderItem )

    $header
  } else {
    Write-Debug "[Get-RawExcelHeaders] - Can't discover Schema. Sheet Object is Null"

    return @{}
  }

  # $DebugPreference = "SilentlyContinue"
  if ( $DebugPreference -eq "SilentlyContinue" ) { $DebugPreference = "Continue" }
}


function Import-RawExcelDataSet( $sheet, [HashTable] $schema, [int[]] $DataStart = @( $FIRST_DATA_ROW, $FIRST_DATA_COLUMN ), [int] $items = 0 ) {
  <#
    .SYNOPSIS
      Loads data into PowerShell Objects from an Excel sheet taking into account its information schema.

    .DESCRIPTION
      Loads data into PowerShell Objects from an Excel sheet taking into account its information schema.

    .EXAMPLE
      $campaign = Import-RawExcelDataSet -sheet $CampaignDataSource -schema $CampaignInfoSchema
      $campaign = Import-RawExcelDataSet -sheet $CampaignDataSource -schema $CampaignInfoSchema -DataStart 4,2

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  [System.Collections.ArrayList] $DataSet = @()

  $FirstRow             = $DataStart[0]
  $HeadersRow           = $DataStart[0] - 1

  if ( $items -eq 0 ) {
    $LastRow            = ( Get-RawExcelRowCount $sheet $DataStart ) + $HeadersRow
  } else {
    $LastRow            = $items + $HeadersRow
  }

  Write-Debug "[Import-RawExcelDataSet] - Headers Row is:   $HeadersRow"
  Write-Debug "[Import-RawExcelDataSet] - First Column is:  $( $DataStart[1] ) "
  Write-Debug "[Import-RawExcelDataSet] - First Row is:     $HeadersRow"
  Write-Debug "[Import-RawExcelDataSet] - Last Row is:      $LastRow"
  Write-Debug "[Import-RawExcelDataSet] - Items requested:  $items"

  $ExecutionTime        = [Diagnostics.Stopwatch]::StartNew()
  $ExecutionTime.Stop()

  for ( $i = $FirstRow ; $i -le $LastRow ; $i++ ) {
    Write-Progress -Activity "Loading data ..." -Status "Progress: $i / $LastRow - ETC: $( '{0:###,##0.00}' -f (( $LastRow - $i ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes - Time Elapsed: $( '{0:###,##0.00}' -f (( $i - 1 ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes" -PercentComplete ( ( $i / $LastRow ) * 100 )

    $ExecutionTime             = [Diagnostics.Stopwatch]::StartNew()

    $ObjectProperties          = @{}
    $ObjectProperties.ObjectId = $i

    $schema.Keys | ForEach-Object {
      $ObjectProperties.$_     = $sheet.Cells.Item( $i, $schema.$_ ).Value
    }

    $NewItem                   = New-Object PSObject -Property $ObjectProperties
    $DataSet.Add( $NewItem ) | Out-Null

    $ExecutionTime.Stop()
  }

  $DataSet | ForEach-Object { if ( $_ -ne $null ) { $_ } }
}


function Export-RawExcelDataSet( $DataSet, $sheet, [HashTable] $schema ) {
  <#
    .SYNOPSIS
      Saves a PowerShell Dataset into a compatible Excel sheet taking into account both information schemas.

    .DESCRIPTION
      Saves a PowerShell Dataset into a compatible Excel sheet taking into account both information schemas.

    .EXAMPLE
      Export-RawExcelDataSet -DataSet $campaign -sheet $CampaignDataSource -schema $CampaignInfoSchema

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  $ExecutionTime        = [Diagnostics.Stopwatch]::StartNew()
  $ExecutionTime.Stop()

  $CurrentObjectCount   = 1
  $SourceSchema         = $DataSet[0] | Get-Member -MemberType NoteProperty | Select-Object Name

  foreach ( $object in $DataSet ) {
    Write-Progress -Activity "Saving data ..." -Status "Progress: $CurrentObjectCount / $( $DataSet.Count ) - ETC: $( '{0:###,##0.00}' -f (( $( $DataSet.Count ) - $CurrentObjectCount ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes - Time Elapsed: $( '{0:###,##0.00}' -f (( $CurrentObjectCount - 1 ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes" -PercentComplete ( ( $CurrentObjectCount / $( $DataSet.Count ) ) * 100 )

    $ExecutionTime      = [Diagnostics.Stopwatch]::StartNew()

    $SourceSchema | ForEach-Object {
      if ( $schema.ContainsKey( $( $_.Name ) ) ) {
        if ( $object.$($_.Name) -is [array] ) {
          $sheet.Cells.Item( $object.ObjectId, $schema.$($_.Name) ).Value = [string] ( $object.$($_.Name) ) -replace " ", ", "
        } else {
          $sheet.Cells.Item( $object.ObjectId, $schema.$($_.Name) ).Value = $object.$($_.Name)
        }
      }
    }

    $CurrentObjectCount++

    $ExecutionTime.Stop()
  }
}


function Get-RawExcelRowCount( $sheet, [int[]] $DataStart = @( $FIRST_DATA_ROW, $FIRST_DATA_COLUMN ) ) {
  <#
    .SYNOPSIS
      Gets the number of rows for a given Excel sheet.

    .DESCRIPTION
      Gets the number of rows for a given Excel sheet.

    .EXAMPLE
      $rows = Get-RawExcelRowCount $sheet
      $rows = Get-RawExcelRowCount $sheet -DataStart 4,2

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>

  $LogFileName = "ExcelModule"

  $HeadersRow  = $DataStart[0] - 1

	try {
    $LastRow   = $sheet.Dimension.End.Row - 1
    $rows      = $LastRow - $HeadersRow
  } catch {
    "$(get-date -format u) [Get-RawExcelRowCount] - Can't retrieve number of rows" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    Write-Debug "[Get-RawExcelRowCount] - Can't retrieve number of rows."

    return 0
  }

	return $rows
}


function Get-RawExcelColumnCount( $sheet ) {
  <#
    .SYNOPSIS
      Gets the number of columns for a given Excel sheet.

    .DESCRIPTION
      Gets the number of columns for a given Excel sheet.

    .EXAMPLE
      $rows = Get-RawExcelColumnCount $sheet

    .NOTES
      Low-level function.

    .LINK
      N/A
  #>


  $LogFileName  = "ExcelModule"

  $StartColumn  = $DataStart[1]

	try {
    $LastColumn = $sheet.Dimension.End.Column - 1
    $columns    = $LastColumn - $StartColumn
  } catch {
    "$(get-date -format u) [Get-RawExcelColumnCount] - Can't retrieve number of columns" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    Write-Debug "[Get-RawExcelColumnCount] - Can't retrieve number of columns."

    return 0
  }

	return $columns
}


# --------------------------------------------------------------------------------------------------


function Import-ExcelDataSet( [string] $file = "", [string] $sheet = "", [int[]] $DataStart = @( $FIRST_DATA_ROW, $FIRST_DATA_COLUMN ), [int] $items = 0 ) {
  <#
    .SYNOPSIS
      Loads the Excel dataset contained on the especified sheet into a PowerShell dataset.

    .DESCRIPTION
      Loads the Excel dataset contained on the especified sheet into a PowerShell dataset.

    .EXAMPLE
      $CampaignDataSet = Import-ExcelDataSet -file .\campaign.xls -sheet "campaign"
      $CampaignDataSet = Import-ExcelDataSet -file .\campaign.xls -sheet "campaign" -DataStart 4,2
      $CampaignDataSet = Import-ExcelDataSet -file .\campaign.xls -sheet "campaign" -DataStart 4,2 -items 10

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  $LogFileName      = "ExcelModule"

  $HeadersRow       = $DataStart[0] - 1


  if ( $file -eq "" ) {
    "$(get-date -format u) [Import-ExcelDataSet] - Aborting execution. File name hasn't been specified." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    Write-Debug "[Import-ExcelDataSet] - Aborting execution. File name hasn't been specified."

    return $null
  }

  if ( $sheet -eq "" ) {
    "$(get-date -format u) [Import-ExcelDataSet] - Aborting execution. Sheet name hasn't been specified." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    Write-Debug "[Import-ExcelDataSet] - Aborting execution. Sheet name hasn't been specified."

    return $null
  }


  if ( Test-Path $file ) {
    $excel          = Open-RawExcelFile         -file $file

    if ( $excel -ne $null ) {
      Write-Debug "[Import-ExcelDataSet] - Opening Selected Excel Sheet"

      if ( $excel.Workbook -ne $null ) {
        try {
          if ( $excel.Workbook.Worksheets.Count -ne 0 ) {
            if ( $excel.Workbook.Worksheets[$sheet] -ne $null ) {

              Write-Debug "[Import-ExcelDataSet] - Discovering Information Schema"

              $DataSource   = $excel.Workbook.Worksheets[$sheet]
              $InfoSchema   = Get-RawExcelHeaders       -sheet $DataSource -DataStart $DataStart

              Write-Debug "[Import-ExcelDataSet] -   Sheet Inforation Schema Elements: $( $InfoSchema.Count )"

              if ( $items -eq 0 ) {
                $TotalItems = Get-RawExcelRowCount $DataSource $DataStart

                Write-Debug "[Import-ExcelDataSet] - Reading all the content in the Sheet."
                Write-Debug "[Import-ExcelDataSet] -   TotalItems: $TotalItems"

                $DataSet    = Import-RawExcelDataSet    -sheet $DataSource -schema $InfoSchema -DataStart $DataStart -items $TotalItems
              } else {
                Write-Debug "[Import-ExcelDataSet] - Reading only partial content of the Sheet."
                Write-Debug "[Import-ExcelDataSet] -   TotalItems: $items"

                $DataSet    = Import-RawExcelDataSet    -sheet $DataSource -schema $InfoSchema -DataStart $DataStart -items $items
              }

              $excel.Dispose()

              $DataSet
            } else {
              "$(get-date -format u) [Import-ExcelDataSet] - Can't open the specified sheet. Sheet Name incorrect." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
              "$(get-date -format u) [Import-ExcelDataSet] -   Sheet Name: $name"                                   >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

              Write-Debug "[Import-ExcelDataSet] - Can't open the specified sheet. Sheet Name incorrect."
              Write-Debug "[Import-ExcelDataSet] -   Sheet Name: $name"

              return $null
            }
          } else {
            "$(get-date -format u) [Import-ExcelDataSet] - Can't open the specified sheet. Worksheets are null." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
            "$(get-date -format u) [Import-ExcelDataSet] -   Sheet Name: $name"                                  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

            Write-Debug "[Import-ExcelDataSet] - Can't open the specified sheet. Worksheets are null."
            Write-Debug "[Import-ExcelDataSet] -   Sheet Name: $name"

            return $null
          }
        } catch {
          "$(get-date -format u) [Import-ExcelDataSet] - Can't open the specified sheet. Unexpected Error." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
          "$(get-date -format u) [Import-ExcelDataSet] -   Sheet Name: $name"                               >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

          Write-Debug "[Import-ExcelDataSet] - Can't open the specified sheet. Unexpected Error."
          Write-Debug "[Import-ExcelDataSet] -   Sheet Name: $name"

          return $null
        }
      } else {
        "$(get-date -format u) [Import-ExcelDataSet] - Can't open the specified sheet. Workbook is null." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) [Import-ExcelDataSet] -   Sheet Name: $sheet"                              >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

        Write-Debug "[Import-ExcelDataSet] - Can't open the specified sheet. Workbook is null."
        Write-Debug "[Import-ExcelDataSet] -   Sheet Name: $sheet"

        return $null
      }
    } else {
      "$(get-date -format u) [Import-ExcelDataSet] - Unable to open excel file." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Import-ExcelDataSet] -   File Name: $file"         >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Import-ExcelDataSet] - Unable to open excel file."
      Write-Debug "[Import-ExcelDataSet] -   File Name: $file"

      return $null
    }
  } else {
    "$(get-date -format u) [Import-ExcelDataSet] - File doesn't exists" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Import-ExcelDataSet] -   File Name: $file"  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Import-ExcelDataSet] - File doesn't exists."
    Write-Debug "[Import-ExcelDataSet] -   File Name: $file"

    return $null
  }
}


function Export-ExcelDataSet( [PSObject[]] $data, [string] $file = "", [string] $sheet = "", [int[]] $DataStart = @( $FIRST_DATA_ROW, $FIRST_DATA_COLUMN ), [int] $items = 0  ) {
  <#
    .SYNOPSIS
      Saves an existing PowerShell dataset into the especified Excel sheet.

    .DESCRIPTION
      Saves an existing PowerShell dataset into the especified Excel sheet. For this operation to succeed,
      both elements, the source dataset and the excel sheet, must have the same structure.

    .EXAMPLE
      Export-ExcelDataSet $UpdatedCampaignDataSet -file .\campaign.xls -sheet "campaign"
      Export-ExcelDataSet $UpdatedCampaignDataSet -file .\campaign.xls -sheet "campaign" -DataStart 4,2
      Export-ExcelDataSet $UpdatedCampaignDataSet -file .\campaign.xls -sheet "campaign" -DataStart 4,2 -items 10

    .NOTES
      High-level function.

    .LINK
      N/A
  #>


  $LogFileName  = "ExcelModule"

  $HeadersRow       = $DataStart[0] - 1


  if ( $data -eq $null ) {
    "$(get-date -format u) [Export-ExcelDataSet] - Aborting execution. Input data hasn't been specified." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    Write-Debug "[Export-ExcelDataSet] - Aborting execution. Input data hasn't been specified."

    return $null
  }

  if ( $file -eq "" ) {
    "$(get-date -format u) [Export-ExcelDataSet] - Aborting execution. File name hasn't been specified." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    Write-Debug "[Export-ExcelDataSet] - Aborting execution. File name hasn't been specified."

    return $null
  }

  if ( $sheet -eq "" ) {
    "$(get-date -format u) [Export-ExcelDataSet] - Aborting execution. Sheet name hasn't been specified." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    Write-Debug "[Export-ExcelDataSet] - Aborting execution. Sheet name hasn't been specified."

    return $null
  }


  if ( Test-Path $file ) {
    $excel          = Open-RawExcelFile         -file $file

    if ( $excel -ne $null ) {
      Write-Debug "[Export-ExcelDataSet] - Opening Selected Excel Sheet"

      if ( $excel.Workbook -ne $null ) {
        try {
          if ( $excel.Workbook.Worksheets.Count -ne 0 ) {
            if ( $excel.Workbook.Worksheets[$sheet] -ne $null ) {

              Write-Debug "[Export-ExcelDataSet] - Discovering Information Schema"

              $DataSource   = $excel.Workbook.Worksheets[$sheet]
              $InfoSchema   = Get-RawExcelHeaders       -sheet $DataSource -DataStart $DataStart

              Write-Debug "[Export-ExcelDataSet] -   Sheet Inforation Schema Elements: $( $InfoSchema.Count )"

              if ( $items -eq 0 ) {
                Write-Debug "[Export-ExcelDataSet] - Saving all the content in the source Dataset."
                Write-Debug "[Export-ExcelDataSet] -   TotalItems: $( $data.Count )"

                Export-RawExcelDataSet    -DataSet $data -sheet $DataSource -schema $InfoSchema
              } else {
                if ( $items -lt $data.Count ) {
                  Write-Debug "[Export-ExcelDataSet] - Saving only partial content of the source Dataset."
                  Write-Debug "[Export-ExcelDataSet] -   TotalItems: $items"

                  Export-RawExcelDataSet    -DataSet $data[0..$items] -sheet $DataSource -schema $InfoSchema
                } else {
                  Write-Debug "[Export-ExcelDataSet] - Saving all the content in the source Dataset."
                  Write-Debug "[Export-ExcelDataSet] -   TotalItems: $( $data.Count )"

                  Export-RawExcelDataSet    -DataSet $data -sheet $DataSource -schema $InfoSchema
                }
              }

              try {
                $excel.Save()
              } catch {
                "$(get-date -format u) [Export-ExcelDataSet] - Can't save Excel file. Unexpected error." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
                "$(get-date -format u) [Export-ExcelDataSet] -   Error: $( $Error[0].Exception )"        >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

                Write-Debug "[Export-ExcelDataSet] - Can't save Excel file. Unexpected error."
                Write-Debug "[Export-ExcelDataSet] -   Error: $( $Error[0].Exception )"
              }

              $excel.Dispose()
            } else {
              "$(get-date -format u) [Export-ExcelDataSet] - Can't open the specified sheet. Sheet Name incorrect." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
              "$(get-date -format u) [Export-ExcelDataSet] -   Sheet Name: $name"                                   >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

              Write-Debug "[Export-ExcelDataSet] - Can't open the specified sheet. Sheet Name incorrect."
              Write-Debug "[Export-ExcelDataSet] -   Sheet Name: $name"

              return $null
            }
          } else {
            "$(get-date -format u) [Export-ExcelDataSet] - Can't open the specified sheet. Worksheets are null." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
            "$(get-date -format u) [Export-ExcelDataSet] -   Sheet Name: $name"                                  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

            Write-Debug "[Export-ExcelDataSet] - Can't open the specified sheet. Worksheets are null."
            Write-Debug "[Export-ExcelDataSet] -   Sheet Name: $name"

            return $null
          }
        } catch {
          "$(get-date -format u) [Export-ExcelDataSet] - Can't open the specified sheet. Unexpected Error." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
          "$(get-date -format u) [Export-ExcelDataSet] -   Sheet Name: $name"                               >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

          Write-Debug "[Export-ExcelDataSet] - Can't open the specified sheet. Unexpected Error."
          Write-Debug "[Export-ExcelDataSet] -   Sheet Name: $name"

          return $null
        }
      } else {
        "$(get-date -format u) [Export-ExcelDataSet] - Can't open the specified sheet. Workbook is null." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
        "$(get-date -format u) [Export-ExcelDataSet] -   Sheet Name: $sheet"                              >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

        Write-Debug "[Export-ExcelDataSet] - Can't open the specified sheet. Workbook is null."
        Write-Debug "[Export-ExcelDataSet] -   Sheet Name: $sheet"

        return $null
      }
    } else {
      "$(get-date -format u) [Export-ExcelDataSet] - Unable to open excel file." >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
      "$(get-date -format u) [Export-ExcelDataSet] -   File Name: $file"         >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

      Write-Debug "[Export-ExcelDataSet] - Unable to open excel file."
      Write-Debug "[Export-ExcelDataSet] -   File Name: $file"

      return $null
    }
  } else {
    "$(get-date -format u) [Export-ExcelDataSet] - File doesn't exists" >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log
    "$(get-date -format u) [Export-ExcelDataSet] -   File Name: $file"  >> $CurrentLogsDir\$LogFileName-$CurrentSessionId.log

    Write-Debug "[Export-ExcelDataSet] - File doesn't exists."
    Write-Debug "[Export-ExcelDataSet] -   File Name: $file"

    return $null
  }
}