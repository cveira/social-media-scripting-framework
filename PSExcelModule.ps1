<#
-------------------------------------------------------------------------------
Name:    Social Media Scripting Framework
Module:  Microsoft Excel
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


$HEADERS_ROW       = 2
$FIRST_DATA_ROW    = 3
$FIRST_DATA_COLUMN = 2


function New-ExcelInstance() {
  New-Object -COM Excel.Application
}


function Invoke-ExcelComMethod( [object] $instance, [string] $method, $parameters = $null ) {
  # $book = Invoke-ExcelComMethod $excel Open ".\excel.xlsx"

  $CultureInfo = [System.Globalization.CultureInfo]'en-US'

  $instance.Workbooks.PSBase.GetType().InvokeMember( $method, [Reflection.BindingFlags]::InvokeMethod, $null, $instance.Workbooks, $parameters, $CultureInfo )
}


function Open-ExcelFile( [object] $instance, [string] $file ) {
  # $book = Open-ExcelFile $excel ".\excel.xlsx"

  if ( Test-Path $file ) {
    $FullName = ( Get-ChildItem $file ).FullName

    # Invoke-ExcelComMethod $instance Open $file
    $excel.Workbooks.Open( $FullName )
  } else {
    $null
  }
}


function Save-ExcelFile( [object] $book ) {
  # Save-ExcelFile $book

  # Invoke-ExcelComMethod $book Save | Out-Null
  $book.Save()
}


function Save-ExcelFileAs( [object] $instance, [string] $FullFileName ) {
  # Save-ExcelFileAs $book 'D:\FullPath\NewExcelFile.xlsx'

  if ( Test-Path $FullFileName ) {
    $null
  } else {
    # Invoke-ExcelComMethod $instance SaveAs $FullFileName | Out-Null
    $instance.SaveAs( $FullFileName )
  }
}


function Close-ExcelFile( $instance, $book ) {
  # execution pre-condicion: no concurrency!
  # WARNING: no other Excel instances should be running. They could be killed without saving!

  $book.Close()

  $BookClosedOk  = ( [System.Runtime.Interopservices.Marshal]::ReleaseComObject( [System.__ComObject] $book )     -eq 0 )
  $ExcelClosedOk = ( [System.Runtime.Interopservices.Marshal]::ReleaseComObject( [System.__ComObject] $instance ) -eq 0 )

  if ( !( $BookClosedOk -and $ExcelClosedOk ) ) {
    $ExcelProcess = Get-Process Excel
    $ExcelProcess | ForEach-Object { Stop-Process ( $_.id ) }
  }

  [System.GC]::Collect()
  [System.GC]::WaitForPendingFinalizers()
}


function NormalizeKeyName( [string] $KeyName ) {
  $KeyName = $KeyName.Replace(" ", "_")
  $KeyName = $KeyName.Replace("?", "")
  $KeyName = $KeyName.Replace("/", "")

  while ( $KeyName.SubString(0, 1) -eq "_" )                     { $KeyName = $KeyName.SubString( 1,  ( $KeyName.Length - 1 ) ) }
  while ( $KeyName.SubString(($KeyName.Length - 1), 1) -eq "_" ) { $KeyName = $KeyName.SubString( 0,  ( $KeyName.Length - 1 ) ) }

  $KeyName = $KeyName.Trim()

  $KeyName
}


function Get-ExcelHeaders( $sheet ) {
  # $CampaignInfoSchema = Get-ExcelHeaders -sheet $CampaignDataSource

  $header     = @{}
  $HeaderItem = ""
  $column     = $FIRST_DATA_COLUMN

  do {
    $HeaderItem = $sheet.Cells.Item( $HEADERS_ROW, $column ).Text

    if ( $HeaderItem ) {
      $HeaderItem = NormalizeKeyName $HeaderItem

      $header.Add( $HeaderItem, $column )
      $column++
    }
  } until ( !$HeaderItem )

  $header
}


function Load-ExcelDataSet( $sheet, [HashTable] $schema ) {
  # $campaign = Load-ExcelDataSet -sheet $CampaignDataSource -schema $CampaignInfoSchema

  [PSObject[]] $DataSet = @()
  $FirstRow             = $FIRST_DATA_ROW
  $LastRow              = ( Get-ExcelRowCount $sheet ) + $HEADERS_ROW
  $ExecutionTime        = [Diagnostics.Stopwatch]::StartNew()


  for ( $i = $FirstRow ; $i -le $LastRow ; $i++ ) {
    $ExecutionTime.Stop()

    Write-Progress -Activity "Loading data ..." -Status "Progress: $i / $LastRow - ETC: $( '{0:###,##0.00}' -f (( $LastRow - $i ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes - Time Elapsed: $( '{0:###,##0.00}' -f (( $i - 1 ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes" -PercentComplete ( ( $i / $LastRow ) * 100 )

    $ExecutionTime      = [Diagnostics.Stopwatch]::StartNew()


    $ObjectProperties   = @{}

    $ObjectProperties.ObjectId = $i

    $schema.Keys | ForEach-Object {
      $ObjectProperties.$_ =  $sheet.Cells.Item( $i, $schema.$_ ).Text
    }

    $DataSet += New-Object PSObject -Property $ObjectProperties
  }

  $DataSet
}


function Save-ExcelDataSet( $DataSet, $sheet, [HashTable] $schema ) {
  # Save-ExcelDataSet -DataSet $campaign -sheet $CampaignDataSource -schema $CampaignInfoSchema

  $CurrentObjectCount   = 1
  $SourceSchema         = $DataSet[0] | Get-Member -MemberType NoteProperty | Select-Object Name
  $ExecutionTime        = [Diagnostics.Stopwatch]::StartNew()

  foreach ( $object in $DataSet ) {
    $ExecutionTime.Stop()

    Write-Progress -Activity "Saving data ..." -Status "Progress: $CurrentObjectCount / $( $DataSet.Count ) - ETC: $( '{0:###,##0.00}' -f (( $( $DataSet.Count ) - $CurrentObjectCount ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes - Time Elapsed: $( '{0:###,##0.00}' -f (( $CurrentObjectCount - 1 ) *  $ExecutionTime.Elapsed.TotalMinutes) ) minutes" -PercentComplete ( ( $CurrentObjectCount / $( $DataSet.Count ) ) * 100 )

    $ExecutionTime      = [Diagnostics.Stopwatch]::StartNew()


    $SourceSchema | ForEach-Object {
      if ( $schema.ContainsKey( $( $_.Name ) ) ) {
        $sheet.Cells.Item( $object.ObjectId, $schema.$($_.Name) ) = $object.$($_.Name)
      }
    }

    $CurrentObjectCount++
  }
}


function Get-ExcelRowCount( $sheet ) {
	$range   = $sheet.UsedRange
	$rows    = $range.Rows.Count
	$rows    = $rows - $HEADERS_ROW

	return $rows
}


function Get-ExcelColumnCount( $sheet ) {
	$range   = $sheet.UsedRange
	$columns = $range.Columns.Count

	return $columns
}


function Get-ExcelSheetIdByName( $book, [string] $name ) {
  # Get-ExcelSheetIdByName $book 'campaign'

  $SheetId = -1

  for ( $i = 1 ; $i -le $book.Worksheets.Count ; $i++ ) {
    if ( $book.Worksheets.Item($i).Name -eq $name ) { $SheetId = $i }
  }

  $SheetId
}


function Get-ExcelSheet( $book, [int] $id ) {
  # $CampaignData = Get-ExcelSheet $book $CampaignSheetId

  $book.Worksheets.Item( $id )
}