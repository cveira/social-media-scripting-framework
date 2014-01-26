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
    LastUpdate  = "&{Get-Date -format 'yyyy/MM/dd'}",  "LastUpdateDate", "OVERWRITE"
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
    LastUpdate  = "&{Get-Date -format 'yyyy/MM/dd'}",  "LastUpdateDate"
  }

#>


$CampaignRules = @{
  KeyProperty = "PermaLink",                           "Post_PermaLink_URL"

  Done         = "@yes",                               "Done"
  Channel      = "ChannelName",                        "Channel"
  Subchannel   = "SubChannelName",                     "Subchannel"
  Scope        = "@global",                            "Scope"
  Interest     = "InterestCount",                      "Likes"
  Interactions = "InteractionsCount",                  "Conversations"
  Audience     = "AudienceCount",                      "Audience"
  Downloads    = "DownloadsCount",                     "Downloads"
  Story        = "Title",                              "Story_Text"
  ShortLink    = "SharedLinks",                        "Short_URL"
  TargetUrls   = "SharedTargetURLs",                   "Target_URL"
  Publisher    = "AuthorDisplayName",                  "Publisher"
  Tags         = "Tags",                               "Tags"
  Categories   = "Categories",                         "Categories"
  keywords     = "Keywords",                           "Keywords"
  Date         = "created",                            "Date"
  LastUpdate   = "&{ Get-Date -format 'yyyy/MM/dd' }", "LastUpdateDate"
}


$EditorialControlRules = @{
  KeyProperty  = "Link",                               "Short_Link"
  Clicks       = "ClickThroughs",                      "Clicks"
  LastUpdate   = "&{ Get-Date -format 'yyyy/MM/dd'} ", "LastUpdateDate"
}