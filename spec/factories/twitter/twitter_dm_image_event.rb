# frozen_string_literal: true

FactoryBot.define do
  factory :twitter_dm_image_event, class: Hash do
    for_user_id { '1' }
    direct_message_events do
      [{
        'type' => 'message_create',
        'id' => '123',
        'message_create' => {
          'target' => { 'recipient_id' => '1' },
          'sender_id' => '2',
          'source_app_id' => '268278',
          'message_data' => {
            'text' => 'Blue Bird',
            'attachment' => {
              'media' => {
                'display_url' => 'pic.twitter.com/5J1WJSRCy9',
                'expanded_url' => 'https://twitter.com/nolan_test/status/930077847535812610/photo/1',
                'id' => 9.300778475358126e17,
                'id_str' => '930077847535812610',
                'indices' => [
                  13,
                  36
                ],
                'media_url' => 'http://pbs.twimg.com/media/DOhM30VVwAEpIHq.jpg',
                'media_url_https' => 'https://pbs.twimg.com/media/DOhM30VVwAEpIHq.jpg',
                'sizes' => {
                  'thumb' => {
                    'h' => 150,
                    'resize' => 'crop',
                    'w' => 150
                  },
                  'large' => {
                    'h' => 1366,
                    'resize' => 'fit',
                    'w' => 2048
                  },
                  'medium' => {
                    'h' => 800,
                    'resize' => 'fit',
                    'w' => 1200
                  },
                  'small' => {
                    'h' => 454,
                    'resize' => 'fit',
                    'w' => 680
                  }
                },
                'type' => 'photo',
                'url' => 'https://t.co/5J1WJSRCy9'
              }
            }.with_indifferent_access
          }
        }
      }.with_indifferent_access]
    end
    users do
      {
        '1' => {
          id: '1',
          name: 'person 1',
          profile_image_url: 'https://chatwoot-assets.local/sample.png'
        },
        '2' => {
          id: '1',
          name: 'person 1',
          profile_image_url: 'https://chatwoot-assets.local/sample.png'
        }
      }
    end

    initialize_with { attributes }
  end
end
