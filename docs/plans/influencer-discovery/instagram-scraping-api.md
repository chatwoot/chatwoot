Instagram Scraping API

Here are endpoints to get information on influencer's profile directly from Instagram website. We do scraping in realtime and return information to you.

Sample use cases:

Detecting when influencer made a new post
Tracking performance of individual social media posts
Tracking influencers performance on your schedule (e.g., daily follower growth history)
Showing most fresh data in the UI
For everyone with valid credits we give base package for free - API is limited to 5 RPS and 0.02 credits per successful* request. Contact your manager for subscription options.

Successful means we got some non-500 response from TikTok. For example, if you have passed an invalid keyword and TikTok returned empty results list, then it counts as one request. If there are some problems on our side, then you would not be charged.
Instagram Audio Feed

Returns Instagram audio feed starting from the latest one. To get the next page pass content of end_cursor to the after query parameter.

$ Paid request

Every successfully made request costs 0.02 credits.
AUTHORIZATIONS:
header
QUERY PARAMETERS

audio_id
required
integer
Instagram audio ID.
after	
string
Pass content of end_cursor field from the last response to get next page
Responses

200
RESPONSE HEADERS
X-Credits-Cost	
number
The number of spent credits
RESPONSE SCHEMA: application/json

items	
Array of objects (InstagramAudioFeedItem)
music_canonical_id	
string or null (Music canonical id) non-empty
audio_page_reporting_id	
string or null (Audio page reporting id) non-empty
formatted_media_count	
string or null (Formatted media count)
metadata	
object or null (MusicMetadata)
audio_ranking_info	
object or null (AudioRankingInfo)
is_music_page_restricted	
boolean or null (Is music page restricted)
audio_page_segments	
Array of objects or null
available_tabs	
Array of strings or null
media_count	
object or null (MediaCount)
auto_created_reels_preview_metadata	
Array of objects or null
status
required
string (Status)
Enum: "ok" "fail"
end_cursor	
string or null (End cursor)

GET
/api/raw/ig/audio/feed/
Response samples

200
Content type
application/json

Copy
Expand all Collapse all
{
"items": [
{}
],
"music_canonical_id": "string",
"audio_page_reporting_id": "string",
"formatted_media_count": "string",
"metadata": {
"music_info": {},
"original_sound_info": { },
"creative_config_info": { },
"additional_audio_info": { }
},
"audio_ranking_info": {
"best_audio_cluster_id": "string"
},
"is_music_page_restricted": true,
"audio_page_segments": [
{ }
],
"available_tabs": [
"string"
],
"media_count": {
"clips_count": 0,
"photos_count": 0
},
"auto_created_reels_preview_metadata": [
{ }
],
"status": "ok",
"end_cursor": "string"
}
Instagram Hashtag Feed

Returns Instagram hashtag feed starting from the latest one. Up to 30 posts on the page for "recent posts" feed and up to 9 for "top posts" feed. To get the next page pass content of end_cursor to the after query parameter.

$ Paid request

Every successfully made request costs 0.02 credits.
AUTHORIZATIONS:
header
QUERY PARAMETERS

hashtag
required
string
Instagram hashtag (without # at the beginning)
type	
string
Default: "recent"
Enum: ["recent","Recent posts"] ["top","Top posts"]
What kind of feed to return
after	
string
Pass content of end_cursor field from the last response to get next page
Responses

200
RESPONSE HEADERS
X-Credits-Cost	
number
The number of spent credits
RESPONSE SCHEMA: application/json

items	
Array of objects or null (InstagramPostData)
more_available	
boolean (More available)
end_cursor	
string or null (End cursor)
status
required
string (Status)
Enum: "ok" "fail"

GET
/api/raw/ig/hashtag/feed/
Response samples

200
Content type
application/json

Copy
Expand all Collapse all
{
"items": [
{}
],
"more_available": true,
"end_cursor": "string",
"status": "ok"
}
Instagram Hashtag Info

Returns Instagram hashtag info.

$ Paid request

Every successfully made request costs 0.02 credits.
AUTHORIZATIONS:
header
QUERY PARAMETERS

hashtag
required
string
Instagram hashtag (without # at the beginning)
Responses

200
RESPONSE HEADERS
X-Credits-Cost	
number
The number of spent credits
RESPONSE SCHEMA: application/json

id
required
integer (Id)
name
required
string (Name) non-empty
media_count
required
integer (Media count)
status
required
string (Status)
Enum: "ok" "fail"

GET
/api/raw/ig/hashtag/info/
Response samples

200
Content type
application/json

Copy
{
"id": 0,
"name": "string",
"media_count": 0,
"status": "ok"
}
Instagram Comments

Get comments for Instagram post with pagination. We can't guarantee the order of the comments, so don't rely on it. To get the next page pass content of end_cursor to the after query parameter.

$ Paid request

Every successfully made request costs 0.02 credits.
AUTHORIZATIONS:
header
QUERY PARAMETERS

code
required
string
Instagram post shortcode (digits and letters after https://www.instagram.com/p/)
after	
string
Pass content of end_cursor field from the last response to get next page
Responses

200
RESPONSE HEADERS
X-Credits-Cost	
number
The number of spent credits
RESPONSE SCHEMA: application/json

status
required
string (Status)
Enum: "ok" "fail"
comments_disabled	
boolean (Comments disabled)
comments	
Array of objects (InstagramComment)
comment_count	
integer (Comment count)
has_more_comments	
boolean or null (Has more comments)
end_cursor	
string or null (End cursor)

GET
/api/raw/ig/media/comments/
Response samples

200
Content type
application/json

Copy
Expand all Collapse all
{
"status": "ok",
"comments_disabled": true,
"comments": [
{}
],
"comment_count": 0,
"has_more_comments": true,
"end_cursor": "string"
}
Instagram Comments Replies

⚠️ Due to recent changes on Instagram's side, this API method has been affected. As a result, when paging comments, you may encounter duplicate comments.

We need some time to fix it. If you have any questions or need further assistance, please feel free to contact us. We appreciate your patience and understanding.
Get replies to the specific comment of the post with pagination. We can't guarantee the order of the replies and how much replies returned per page, so don't rely on it. To get the next page pass content of end_cursor to the after query parameter.

$ Paid request

Every successfully made request costs 0.02 credits.
AUTHORIZATIONS:
header
QUERY PARAMETERS

code
required
string
Instagram post shortcode (digits and letters after https://www.instagram.com/p/)
comment_id
required
string
comment id, you can get it from pk field in the comment info
after	
string
Pass content of end_cursor field from the last response to get next page
Responses

200
RESPONSE HEADERS
X-Credits-Cost	
number
The number of spent credits
RESPONSE SCHEMA: application/json

status
required
string (Status)
Enum: "ok" "fail"
child_comments	
Array of objects (InstagramComment)
end_cursor	
string or null (End cursor)

GET
/api/raw/ig/media/comments/replies/
Response samples

200
Content type
application/json

Copy
Expand all Collapse all
{
"status": "ok",
"child_comments": [
{}
],
"end_cursor": "string"
}
Instagram Media Info

Returns information about social media post (as well as reel and IGTV), i.e. post content, likes/comments/views numbers, mentions and geo tags.

$ Paid request

Every successfully made request costs 0.02 credits.
AUTHORIZATIONS:
header
QUERY PARAMETERS

code
required
string
Instagram post shortcode (digits and letters after https://www.instagram.com/p/)
Responses

200
RESPONSE HEADERS
X-Credits-Cost	
number
The number of spent credits
RESPONSE SCHEMA: application/json

items	
Array of objects or null (InstagramPostData)
status
required
string (Status)
Enum: "ok" "fail"

GET
/api/raw/ig/media/info/
Response samples

200
Content type
application/json

Copy
Expand all Collapse all
{
"items": [
{}
],
"status": "ok"
}
Instagram Search Users

Returns Instagram users search result by the keyword.

$ Paid request

Every successfully made request costs 0.02 credits.
AUTHORIZATIONS:
header
QUERY PARAMETERS

keyword
required
string
Keyword to search for.
Responses

200
RESPONSE HEADERS
X-Credits-Cost	
number
The number of spent credits
RESPONSE SCHEMA: application/json

num_results
required
integer (Num results)
users	
Array of objects (InstagramSerpUser)
has_more	
boolean (Has more)

GET
/api/raw/ig/search/users/
Response samples

200
Content type
application/json

Copy
Expand all Collapse all
{
"num_results": 0,
"users": [
{}
],
"has_more": true
}
Instagram User Feed

Returns Instagram user feed starting from the latest one. 12 posts on the page. To get the next page pass content of end_cursor to the after query parameter.

$ Paid request

Every successfully made request costs 0.02 credits.
AUTHORIZATIONS:
header
QUERY PARAMETERS

url
required
string
Instagram username, userId or link to user's profile page.
after	
string
Pass content of end_cursor field from the last response to get next page
Responses

200
RESPONSE HEADERS
X-Credits-Cost	
number
The number of spent credits
RESPONSE SCHEMA: application/json

items	
Array of objects or null (InstagramPostData)
more_available	
boolean (More available)
end_cursor	
string or null (End cursor)
status
required
string (Status)
Enum: "ok" "fail"

GET
/api/raw/ig/user/feed/
Response samples

200
Content type
application/json

Copy
Expand all Collapse all
{
"items": [
{}
],
"more_available": true,
"end_cursor": "string",
"status": "ok"
}
Instagram User IGTV

Returns Instagram user IGTV videos starting from the latest one. Up to 10 items on the page. To get the next page pass content of end_cursor to the after query parameter.

$ Paid request

Every successfully made request costs 0.02 credits.
AUTHORIZATIONS:
header
QUERY PARAMETERS

url
required
string
Instagram username, userId or link to user's profile page.
after	
string
Pass content of end_cursor field from the last response to get next page
Responses

200
RESPONSE HEADERS
X-Credits-Cost	
number
The number of spent credits
RESPONSE SCHEMA: application/json

items	
Array of objects or null (InstagramPostData)
more_available	
boolean (More available)
end_cursor	
string or null (End cursor)
status
required
string (Status)
Enum: "ok" "fail"

GET
/api/raw/ig/user/igtv/
Response samples

200
Content type
application/json

Copy
Expand all Collapse all
{
"items": [
{}
],
"more_available": true,
"end_cursor": "string",
"status": "ok"
}
Instagram User Info

Returns Instagram user information by his ID or username.

$ Paid request

Every successfully made request costs 0.02 credits.
AUTHORIZATIONS:
header
QUERY PARAMETERS

url
required
string
Instagram username, userId or link to user's profile page.
Responses

200
RESPONSE HEADERS
X-Credits-Cost	
number
The number of spent credits
RESPONSE SCHEMA: application/json

status
required
string (Status)
Enum: "ok" "not_found"
user	
object (InstagramUserInfoData)

GET
/api/raw/ig/user/info/
Response samples

200
Content type
application/json

Copy
Expand all Collapse all
{
"status": "ok",
"user": {
"pk": 0,
"username": "string",
"full_name": "string",
"profile_pic_url": "string",
"profile_pic_url_hd": "string",
"is_business": true,
"is_private": true,
"is_verified": true,
"media_count": 0,
"follower_count": 0,
"following_count": 0,
"gating": {},
"is_regulated_c18": true,
"fbid": "string",
"biography": "string",
"external_url": "string",
"has_highlight_reels": false,
"category": "string",
"has_clips": "string",
"has_guides": true,
"has_channel": "string",
"total_igtv_videos": 0,
"bio_links": [ ]
}
}
Instagram User Reels

Returns Instagram user reels starting from the latest one. Up to 12 items on the page. To get the next page pass content of end_cursor to the after query parameter.

$ Paid request

Every successfully made request costs 0.02 credits.
AUTHORIZATIONS:
header
QUERY PARAMETERS

url
required
string
Instagram username, userId or link to user's profile page.
after	
string
Pass content of end_cursor field from the last response to get next page
Responses

200
RESPONSE HEADERS
X-Credits-Cost	
number
The number of spent credits
RESPONSE SCHEMA: application/json

items	
Array of objects (InstagramReelData)
more_available	
string or null (More available)
end_cursor	
string or null (End cursor)
status
required
string (Status)
Enum: "ok" "fail"

GET
/api/raw/ig/user/reels/
Response samples

200
Content type
application/json

Copy
Expand all Collapse all
{
"items": [
{}
],
"more_available": "string",
"end_cursor": "string",
"status": "ok"
}
Instagram User Tags Feed

Returns Instagram user tags feed starting from the latest one. Up to 21 posts on the page. To get the next page pass content of end_cursor to the after query parameter.

$ Paid request

Every successfully made request costs 0.02 credits.
AUTHORIZATIONS:
header
QUERY PARAMETERS

url
required
string
Instagram username, userId or link to user's profile page.
after	
string
Pass content of end_cursor field from the last response to get next page
Responses

200
RESPONSE HEADERS
X-Credits-Cost	
number
The number of spent credits
RESPONSE SCHEMA: application/json

items	
Array of objects or null (InstagramPostData)
more_available	
boolean (More available)
end_cursor	
string or null (End cursor)
status
required
string (Status)
Enum: "ok" "fail"
