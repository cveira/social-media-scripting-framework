<#
-------------------------------------------------------------------------------
Name:    Social Media Scripting Framework
Module:  Bitly.com
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


function Get-BLClicksFromPage( [ref] $PageSourceCode ) {
  # $source = Get-PageSourceCode https://bitly.com/Vk1V37+
  # Get-BLClicksFromPage ([ref] $source)

  [string] $ClicksContentPattern = '(?s)<li[^>]*clicks orange[^>]*>(?<ClickThroughStats>.*?)</li>.*?'
  [string] $ClicksCountPattern   = '(?s)<span[^>]*global_info[^>]*>(?<ClickCountStats>.*?)</span>.*?'

  
  $ClickThroughCount             = 0

  if ( $PageSourceCode.Value -match $ClicksContentPattern ) {
    if ( $Matches.ClickThroughStats -match $ClicksCountPattern ) {
      $ClickThroughCount = [int] $Matches.ClickCountStats.Trim()
    }
  }

  $ClickThroughCount
}