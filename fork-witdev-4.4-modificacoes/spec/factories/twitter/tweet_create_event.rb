# frozen_string_literal: true

FactoryBot.define do
  factory :tweet_create_event, class: Hash do
    for_user_id { '1' }
    user_has_blocked { false }
    tweet_create_events do
      [
        {
          'created_at' => 'Wed Feb 05 08:39:31 +0000 2020',
          'id' => 1,
          'id_str' => '1',
          'text' => '@chatwootapp Testing a sample tweet with Twitter client',
          'source' => '<a href="http://twitter.com/download/iphone" rel="nofollow">Twitter for iPhone</a>',
          'truncated' => false,
          'in_reply_to_status_id' => nil,
          'in_reply_to_status_id_str' => nil,
          'in_reply_to_user_id' => 1,
          'in_reply_to_user_id_str' => '1',
          'in_reply_to_screen_name' => 'chatwootapp',
          'user' => {
            'id' => 2,
            'name' => 'SurveyJoy',
            'screen_name' => 'surveyjoyHQ',
            'location' => 'Bangalore',
            'url' => 'https://surveyjoy.co?utm_source=twitter',
            'description' => 'Delightful in-product customer satisfaction surveys',
            'followers_count' => 21,
            'friends_count' => 13,
            'profile_image_url' => 'http://pbs.twimg.com/profile_images/1114792399597985792/iHc5Gmez_normal.png',
            'profile_image_url_https' => 'https://pbs.twimg.com/profile_images/1114792399597985792/iHc5Gmez_normal.png',
            'profile_banner_url' => 'https://pbs.twimg.com/profile_banners/1109349707783041024/1554622013'
          },
          'geo' => nil,
          'coordinates' => nil,
          'place' => nil,
          'contributors' => nil,
          'is_quote_status' => false,
          'quote_count' => 0,
          'reply_count' => 0,
          'retweet_count' => 0,
          'favorite_count' => 0
        }
      ]
    end
    initialize_with { attributes }
  end
end
