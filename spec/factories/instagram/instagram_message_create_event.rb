FactoryBot.define do
  factory :instagram_message_create_event, class: Hash do
    entry do
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

  factory :instagram_test_text_event, class: Hash do
    entry do
      [
        {
          'time' => 1_661_141_837_537,
          'id' => '0',
          'messaging' => [
            {
              'sender' => {
                'id' => '12334'
              },
              'recipient' => {
                'id' => '23245'
              },
              'timestamp' => '1527459824',
              'message' => {
                'mid' => 'random_mid',
                'text' => 'random_text'
              }
            }
          ]
        }
      ]
    end
    initialize_with { attributes }
  end

  factory :instagram_message_unsend_event, class: Hash do
    entry do
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
                'mid': 'message-id-to-delete',
                'is_deleted': true
              }
            }
          ]
        }
      ]
    end
    initialize_with { attributes }
  end

  factory :instagram_message_attachment_event, class: Hash do
    entry do
      [
        {
          'id': 'instagram-message-id-1234',
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
                'attachments': [
                  {
                    'type': 'share',
                    'payload': {
                      'url': 'https://www.example.com/test.jpeg'
                    }
                  }
                ]
              }
            }
          ]
        }
      ]
    end
    initialize_with { attributes }
  end

  factory :instagram_story_mention_event, class: Hash do
    entry do
      [
        {
          'id': 'instagram-message-id-1234',
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
                'attachments': [
                  {
                    'type': 'story_mention',
                    'payload': {
                      'url': 'https://www.example.com/test.jpeg'
                    }
                  }
                ]
              }
            }
          ]
        }
      ]
    end
    initialize_with { attributes }
  end
end
