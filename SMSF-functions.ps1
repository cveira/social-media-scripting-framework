$COLOR_PROMPT    = 'Magenta'
$COLOR_BRIGHT    = 'Yellow'
$COLOR_DARK      = 'DarkGray'
$COLOR_RESULT    = 'Green' # 'DarkCyan'
$COLOR_NORMAL    = 'White'
$COLOR_ERROR     = 'Red'
$COLOR_ENPHASIZE = 'Magenta'


function Test-SMSFSettings() {

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


  if ( ( $TwitterConsumerKey -eq "" ) -or ( $TwitterConsumerSecret    -eq "" ) -or
       ( $TwitterAccessToken -eq "" ) -or ( $TwitterAccessTokenSecret -eq "" ) )    {

    Write-Host -foregroundcolor $COLOR_ERROR  "    + ERROR: Twitter credentials are not defined correctly."
    Write-Host -foregroundcolor $COLOR_NORMAL $TwitterSettingsHelp
  }


  if ( ( Get-Command -Module Facebook ) -eq $null ) {
    Write-Host -foregroundcolor $COLOR_ERROR  "    + ERROR: the 'Facebook PowerShell Module' is not installed correctly."
    Write-Host -foregroundcolor $COLOR_NORMAL $FacebookSettingsHelp
  }

  if ( $FBAccessToken -eq "" ) {
    Write-Host -foregroundcolor $COLOR_ERROR  "    + ERROR: Facebook credentials are not defined correctly."
    Write-Host -foregroundcolor $COLOR_NORMAL $FacebookSettingsHelp
  }
}