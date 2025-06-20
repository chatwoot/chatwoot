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

  factory :incoming_comment_ig_message, class: Hash do
    initialize_with do
      {
        from: { id: 'Sender-id-1', username: 'Jane Dae' },
        media: { id: 'media-id-1' },
        text: 'This is a comment message',
        id: 'comment-id-1',
        timestamp: '2025-06-23T08:05:43+0000'
      }
    end
  end

  factory :mocked_ig_post_content, class: Hash do
    caption { 'This is a post caption' }
    media_type { 'IMAGE' }
    media_url { 'https://example.com/image.jpg' }
    permalink { 'https://example.com/post/123' }
    timestamp { '2025-06-23T08:05:43+0000' }

    initialize_with { attributes }
  end
end
