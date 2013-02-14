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


$FacebookRules = @{
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
  Date        = "created",                           "Date"
  LastUpdate  = "&{(Get-Date).ToShortDateString()}", "LastUpdateDate"
}


$TwitterRules = @{
  Done        = "@yes",                              "Done"
  Channel     = "@twitter",                          "Channel"
  Subchannel  = "@MyTwitterUser",                    "Subchannel"
  Scope       = "@global",                           "Scope"
  Favorites   = "favorites_count",                   "Likes"
  Retweets    = "retweet_count",                     "Conversations"
  Story       = "text",                              "Story"
  Title       = "Name",                              "Title"
  ShortLink   = "Link",                              "Short"
  HashTag     = "HashTags",                          "Tags"
  Date        = "created",                           "Date"
  LastUpdate  = "&{(Get-Date).ToShortDateString()}", "LastUpdateDate"
}


$LinkedInRules = @{
  Done        = "@yes",                              "Done"
  Channel     = "@LinkedIn",                         "Channel"
  Subchannel  = "@MyLinkedInGroup",                  "Subchannel"
  Scope       = "@global",                           "Scope"
  Likes       = "likes_count",                       "Likes"
  Comments    = "comments_count",                    "Conversations"
  LastUpdate  = "&{(Get-Date).ToShortDateString()}", "LastUpdateDate"
}