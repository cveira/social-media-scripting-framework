$SCHEMA_VERSION_01               = "0.1"

$ENGAGEMENT_TYPE_UNKNOWN         = "Unknown"
$ENGAGEMENT_TYPE_INTERACTION     = "Interaction"
$ENGAGEMENT_TYPE_INTEREST        = "Interest"
$ENGAGEMENT_TYPE_DOWNLOAD        = "Download"
$ENGAGEMENT_TYPE_CLICKTHROUGH    = "Click"
$ENGAGEMENT_TYPE_VISITOR         = "Visitor"

$POST_TYPE_UNKNOWN               = "Unknown"
$POST_TYPE_MESSAGE               = "Message"
$POST_TYPE_ARTICLE               = "Article"
$POST_TYPE_PICTURE               = "Picture"
$POST_TYPE_VIDEO                 = "Video"
$POST_TYPE_LINK                  = "Link"
$POST_TYPE_EVENT                 = "Event"

$CHANNEL_TYPE_UNKNOWN            = "Unknown"
$CHANNEL_TYPE_CMS                = "Content Management System"
$CHANNEL_TYPE_BLOG               = "Blog"
$CHANNEL_TYPE_MICROBLOG          = "Microblog"
$CHANNEL_TYPE_FORUM              = "Forum"
$CHANNEL_TYPE_SUPPORT            = "Customer Support"
$CHANNEL_TYPE_SN                 = "Social Network"
$CHANNEL_TYPE_ESN                = "Enterprise Social Network"

$CHANNEL_NAME_UNKNOWN            = "Unknown"
$CHANNEL_NAME_TWITTER            = "Twitter"
$CHANNEL_NAME_FACEBOOK           = "Facebook"
$CHANNEL_NAME_LINKEDIN           = "LinkedIn"

$DATA_FORMAT_UNKNOWN             = "Unknown"
$DATA_FORMAT_RDF                 = "RDF"
$DATA_FORMAT_ATOM                = "ATOM"
$DATA_FORMAT_WXR                 = "WXR"
$DATA_FORMAT_RSS                 = "RSS"
$DATA_FORMAT_JSON                = "JSON"
$DATA_FORMAT_ODATA               = "OData"

$CHANNEL_DATA_ENGINE_UNKOWN      = "Unknown"
$CHANNEL_DATA_ENGINE_RESTAPI     = "REST API"
$CHANNEL_DATA_ENGINE_SOAPAPI     = "SOAP API"
$CHANNEL_DATA_ENGINE_XMLRPC      = "XML-RPC"
$CHANNEL_DATA_ENGINE_FEED        = "Feed subscription"
$CHANNEL_DATA_ENGINE_WEBSCRAPING = "Web scraping"


$ChangeLogTemplate        = @{
  TimeStamp               = Get-Date -format $DefaultDateFormat
  PropertyName            = ""
  OriginalValue           = ""
  NewValue                = ""
}


$RawObjectTemplate        = @{
  TimeStamp               = Get-Date -format $DefaultDateFormat
  FunctionCallName        = ""
  RawOutput               = [PSCustomObject] @{}
}


$UserConnectionsTemplate  = @{
  UserId                  = ""
  UserDisplayName         = ""
  UserDescription         = ""
  UserProfileUrl          = ""
  UserProfileApiUrl       = ""
  Location                = ""
  EngagementType          = $ENGAGEMENT_TYPE_UNKNOWN # $ENGAGEMENT_TYPE_<XXX>
  CompoundReputationIndex = 0
  KloutScore              = 0
  KredInfluenceScore      = 0
  KredOutreachScore       = 0
  PeerIndex               = 0
  TrustCloudScore         = 0
}


$NormalizedPostTemplate   = @{
  PostId                  = ""
  PostDigest              = "" # PostContent Hash
  PermaLink               = ""
  SourceDomain            = ""
  SourceFormat            = $DATA_FORMAT_UNKNOWN        # $DATA_FORMAT_<XXX>
  ChannelType             = $CHANNEL_TYPE_UNKNOWN       # CHANNEL_TYPE_<XXX>
  ChannelDataEngine       = $CHANNEL_DATA_ENGINE_UNKOWN # $CHANNEL_DATA_ENGINE_<XXX>
  ChannelName             = ""
  SubChannelName          = ""
  SourceApplication       = ""
  Language                = ""
  Location                = ""
  Title                   = ""
  AuthorId                = ""
  AuthorDisplayName       = ""
  PostType                = ""
  PostContent             = ""
  PublishingDate          = [datetime] 0
  Categories              = @()
  Tags                    = @()
  Keywords                = @()
  SharedLinks             = @() # Shortened URLs
  SharedTargetURLs        = @() # URLs behind a shortened link
  UsersRating             = 0
  InteractionsCount       = 0 # Comments + Answers/Mentions + Retweets + Shares + Other interactions
  InterestCount           = 0 # Likes + Favorites + Bookmarks/Taggings + Clicks to read the full post
  AudienceCount           = 0
  DownloadsCount          = 0 # A type of conversion
  ClickThroughsCount      = 0 # A type of conversion
  Virality                = 0 # Interactions / Audience
}


$UserRelevanceTemplate     = @{
  CompoundReputationIndex  = 0
  AKloutScore              = 0
  AKredInfluenceScore      = 0
  AKredOutreachScore       = 0
  APeerIndex               = 0
  ATrustCloudScore         = 0
  SearchResultsCount       = 0 # Google search by "UserId" or "Full Display Name"
}


$PostRelevanceTemplate          = @{
  PostUserVotes                 = 0
  SourceContentDomainVotes      = 0
  AuthorCompoundReputationIndex = 0
  AuthorKloutScore              = 0
  AuthorKredInfluenceScore      = 0
  AuthorKredOutreachScore       = 0
  AuthorPeerIndex               = 0
  AuthorTrustCloudScore         = 0
  SentimentScore                = 0
  SitePageRankIndex             = 0
  SiteAlexaScore                = 0
  IncomingLinksCount            = 0
  SearchResultsCount            = 0 # Google search by "exact title"
}



$NormalizedSNUserTemplate = @{
  PermaLink               = "" # URI: an e-mail address is also a PermaLink
  ChannelName             = ""
  UserId                  = ""
  DisplayName             = ""
  Description             = ""
  Language                = ""
  Location                = ""
  CreationDate            = [datetime] 0
  LastPublishingDate      = [datetime] 0
  Categories              = @()
  Tags                    = @()
  Keywords                = @()
  Groups                  = @()
  ContactLinks            = @()
  ContactEmails           = @()
  PostsCount              = 0
  FollowersCount          = 0
  FollowingCount          = 0
  CommentsCount           = 0
  BookmarksCount          = 0 # Bookmarks, Favorites
  GroupsCount             = 0 # Groups, Lists, etc.
  PrivateProfile          = $false
}


$ReferencesTemplate       = @{
  PermaLink               = ""
  Title                   = ""
  SourceDomain            = ""
  PageRankIndex           = 0
  AlexaScore              = 0
}


$ContextTagsTemplate      = @{
  BelongsToConcept        = "" # ParentConcept[.ChildConcept.[...]] - Semantic Aggregation
  TrackingTag             = "" # ParentConcept[.ChildConcept.[...]] - For long-term topic tracking
  SourceGroup             = "" # ParentConcept[.ChildConcept.[...]] - Data Sources aggregation
  SourceType              = "" # ParentConcept[.ChildConcept.[...]] - Data Source categories
  InterestingTo           = "" # ParentConcept[.ChildConcept.[...]] - Potential target audience
  NotifyTo                = "" # ParentConcept[.ChildConcept.[...]]
  SubmittedBy             = "" # ParentConcept[.ChildConcept.[...]] - To support crowdsourcing Data Sources
  OtherBusinessTag        = "" # ParentConcept[.ChildConcept.[...]]
}


$IdentitiesTemplate       = @{
  Profile                 = New-Object PSObject -Property $NormalizedSNUserTemplate
  MatchingRank            = 0
}


$SNPostTemplate_v01       = @{
  Version                 = $SCHEMA_VERSION_01

  NormalizedPost          = New-Object PSObject -Property $NormalizedPostTemplate
  PostConnections         = @() # $UserConnectionsTemplate
  PostRelevance           = New-Object PSObject -Property $PostRelevanceTemplate
  PostReferences          = @() # $ReferencesTemplate
  ContextTags             = New-Object PSObject -Property $ContextTagsTemplate

  DebugCodes              = @()
  CreationDate            = Get-Date -format $DefaultDateFormat
  LastUpdateDate          = Get-Date -format $DefaultDateFormat
  RetainUntilDate         = Get-Date -format $DefaultDateFormat

  ChangeLog               = @() # $ChangeLogTemplate
  RawObject               = @() # $RawObjectTemplate
}


$SNUserTemplate_v01       = @{
  Version                 = $SCHEMA_VERSION_01

  NormalizedUser          = New-Object PSObject -Property $NormalizedSNUserTemplate

  DebugCodes              = @()
  CreationDate            = Get-Date -format $DefaultDateFormat
  LastUpdateDate          = Get-Date -format $DefaultDateFormat
  RetainUntilDate         = Get-Date -format $DefaultDateFormat

  ChangeLog               = @() # $ChangeLogTemplate
  RawObject               = @() # $RawObjectTemplate
}


$DigitalProfileTemplate_v01 = @{
  Version                 = $SCHEMA_VERSION_01

  DisplayName             = ""

  Identities              = @() # $IdentitiesTemplate
  Reputation              = New-Object PSObject -Property $UserRelevanceTemplate
  References              = @() # $ReferencesTemplate

  DebugCodes              = @()
  CreationDate            = Get-Date -format $DefaultDateFormat
  LastUpdateDate          = Get-Date -format $DefaultDateFormat
  RetainUntilDate         = Get-Date -format $DefaultDateFormat

  ChangeLog               = @() # $ChangeLogTemplate
  RawObject               = @() # $RawObjectTemplate
}