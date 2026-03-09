# frozen_string_literal: true

FactoryBot.define do
  factory :incoming_ig_text_message, class: Hash do
    messaging do
      [
        {
          'id': 'instagram-message-id-123',
          'time': '2021-09-08T06:34:04+0000',
          'messaging': [
            {
              'sender': {
                'id': 'Sender-id-1'
              },
              'recipient': {
                'id': 'chatwoot-app-user-id-1'
              },
              'timestamp': '2021-09-08T06:34:04+0000',
              'message': {
                'mid': 'message-id-1',
                'text': 'This is the first message from the customer'
              }
            }
          ]
        }
      ]
    end

    initialize_with { attributes }
  end
end
