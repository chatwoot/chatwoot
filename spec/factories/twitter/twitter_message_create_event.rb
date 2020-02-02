# frozen_string_literal: true

FactoryBot.define do
  factory :twitter_message_create_event, class: Hash do
    for_user_id { '1' }
    direct_message_events do
      [{
        'type' => 'message_create',
        'id' => '123',
        'message_create' => {
          target: { 'recipient_id' => '1' },
          'sender_id' => '2',
          'source_app_id' => '268278',
          'message_data' => {
            'text' => 'Blue Bird'
          }
        }
      }]
    end
    users do
      {
        '1' => {
          id: '1',
          name: 'person 1',
          profile_image_url: 'https://via.placeholder.com/250x250.png'
        },
        '2' => {
          id: '1',
          name: 'person 1',
          profile_image_url: 'https://via.placeholder.com/250x250.png'
        }
      }
    end

    initialize_with { attributes }
  end
end
