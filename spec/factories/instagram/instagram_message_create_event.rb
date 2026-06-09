FactoryBot.define do
  factory :instagram_message_create_event, class: Hash do
    transient do
      ig_entry_id { SecureRandom.uuid }
      sender_id { "Sender-id-#{SecureRandom.hex(4)}" }
    end
    entry do
      [
        {
          'id': ig_entry_id,
          'time': '2021-09-08T06:34:04+0000',
          'messaging': [
            {
              'sender': {
                'id': sender_id
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

  factory :instagram_message_standby_event, class: Hash do
    transient do
      ig_entry_id { SecureRandom.uuid }
      sender_id { "Sender-id-#{SecureRandom.hex(4)}" }
    end
    entry do
      [
        {
          'time': '2021-09-08T06:34:04+0000',
          'id': ig_entry_id,
          'standby': [
            {
              'sender': {
                'id': sender_id
              },
              'recipient': {
                'id': 'chatwoot-app-user-id-1'
              },
              'timestamp': '2021-09-08T06:34:04+0000',
              'message': {
                'mid': 'message-id-1',
                'text': 'This is the first standby message from the customer, after 24 hours.'
              }
            }
          ]
        }
      ]
    end
    initialize_with { attributes }
  end

  factory :instagram_story_reply_event, class: Hash do
    transient do
      ig_entry_id { SecureRandom.uuid }
      sender_id { "Sender-id-#{SecureRandom.hex(4)}" }
    end
    entry do
      [
        {
          'id': ig_entry_id,
          'time': '2021-09-08T06:34:04+0000',
          'messaging': [
            {
              'sender': {
                'id': sender_id
              },
              'recipient': {
                'id': 'chatwoot-app-user-id-1'
              },
              'timestamp': '2021-09-08T06:34:04+0000',
              'message': {
                'mid': 'message-id-1',
                'text': 'This is the story reply',
                'reply_to': {
                  'story': {
                    'id': 'chatwoot-app-user-id-1',
                    'url': 'https://chatwoot-assets.local/sample.png'
                  }
                }
              }
            }
          ]
        }
      ]
    end
    initialize_with { attributes }
  end

  factory :instagram_message_reply_event, class: Hash do
    transient do
      ig_entry_id { SecureRandom.uuid }
      sender_id { "Sender-id-#{SecureRandom.hex(4)}" }
    end
    entry do
      [
        {
          'id': ig_entry_id,
          'time': '2021-09-08T06:35:04+0000',
          'messaging': [
            {
              'sender': {
                'id': sender_id
              },
              'recipient': {
                'id': 'chatwoot-app-user-id-1'
              },
              'timestamp': '2021-09-08T06:34:04+0000',
              'message': {
                'mid': 'message-id-2',
                'text': 'This is message with replyto mid',
                'reply_to': {
                  'mid': 'message-id-1'
                }
              }
            }
          ]
        }
      ]
    end
    initialize_with { attributes }
  end

  factory :instagram_test_text_event, class: Hash do
    transient do
      ig_entry_id { SecureRandom.uuid }
    end
    entry do
      [
        {
          'time' => 1_661_141_837_537,
          'id' => ig_entry_id,
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
    transient do
      ig_entry_id { SecureRandom.uuid }
      sender_id { "Sender-id-#{SecureRandom.hex(4)}" }
    end
    entry do
      [
        {
          'id': ig_entry_id,
          'time': '2021-09-08T06:34:04+0000',
          'messaging': [
            {
              'sender': {
                'id': sender_id
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
    transient do
      ig_entry_id { SecureRandom.uuid }
      sender_id { "Sender-id-#{SecureRandom.hex(4)}" }
    end
    entry do
      [
        {
          'id': ig_entry_id,
          'time': '2021-09-08T06:34:04+0000',
          'messaging': [
            {
              'sender': {
                'id': sender_id
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

  factory :instagram_shared_reel_event, class: Hash do
    transient do
      ig_entry_id { SecureRandom.uuid }
      sender_id { "Sender-id-#{SecureRandom.hex(4)}" }
    end
    entry do
      [
        {
          'id': ig_entry_id,
          'time': '2021-09-08T06:34:04+0000',
          'messaging': [
            {
              'sender': {
                'id': sender_id
              },
              'recipient': {
                'id': 'chatwoot-app-user-id-1'
              },
              'timestamp': '2021-09-08T06:34:04+0000',
              'message': {
                'mid': 'message-id-1',
                'attachments': [
                  {
                    'type': 'ig_reel',
                    'payload': {
                      'reel_video_id': '1234',
                      'title': 'Reel title',
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
    transient do
      ig_entry_id { SecureRandom.uuid }
      sender_id { "Sender-id-#{SecureRandom.hex(4)}" }
    end
    entry do
      [
        {
          'id': ig_entry_id,
          'time': '2021-09-08T06:34:04+0000',
          'messaging': [
            {
              'sender': {
                'id': sender_id
              },
              'recipient': {
                'id': 'chatwoot-app-user-id-1'
              },
              'timestamp': '2021-09-08T06:34:04+0000',
              'message': {
                'mid': 'mention-message-id-1',
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

  factory :instagram_story_mention_event_with_echo, class: Hash do
    transient do
      ig_entry_id { SecureRandom.uuid }
      sender_id { "Sender-id-#{SecureRandom.hex(4)}" }
    end
    entry do
      [
        {
          'id': ig_entry_id,
          'time': '2021-09-08T06:34:04+0000',
          'messaging': [
            {
              'sender': {
                'id': sender_id
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
                ],
                'is_echo': true
              }
            }
          ]
        }
      ]
    end
    initialize_with { attributes }
  end

  factory :instagram_ig_story_event, class: Hash do
    transient do
      ig_entry_id { SecureRandom.uuid }
      sender_id { "Sender-id-#{SecureRandom.hex(4)}" }
    end
    entry do
      [
        {
          'id': ig_entry_id,
          'time': '2021-09-08T06:34:04+0000',
          'messaging': [
            {
              'sender': {
                'id': sender_id
              },
              'recipient': {
                'id': 'chatwoot-app-user-id-1'
              },
              'timestamp': '2021-09-08T06:34:04+0000',
              'message': {
                'mid': 'ig-story-message-id-1',
                'attachments': [
                  {
                    'type': 'ig_story',
                    'payload': {
                      'story_media_id': '17949487764033669',
                      'story_media_url': 'https://lookaside.fbsbx.com/ig_messaging_cdn/?asset_id=17949487764033669&signature=test'
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

  factory :instagram_ig_post_event, class: Hash do
    transient do
      ig_entry_id { SecureRandom.uuid }
      sender_id { "Sender-id-#{SecureRandom.hex(4)}" }
    end
    entry do
      [
        {
          'id': ig_entry_id,
          'time': '2021-09-08T06:34:04+0000',
          'messaging': [
            {
              'sender': {
                'id': sender_id
              },
              'recipient': {
                'id': 'chatwoot-app-user-id-1'
              },
              'timestamp': '2021-09-08T06:34:04+0000',
              'message': {
                'mid': 'ig-post-message-id-1',
                'attachments': [
                  {
                    'type': 'ig_post',
                    'payload': {
                      'ig_post_media_id': '18091626484740369',
                      'title': 'Shared Instagram post',
                      'url': 'https://lookaside.fbsbx.com/ig_messaging_cdn/?asset_id=18091626484740369&signature=test'
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

  factory :instagram_message_unsupported_event, class: Hash do
    transient do
      ig_entry_id { SecureRandom.uuid }
      sender_id { "Sender-id-#{SecureRandom.hex(4)}" }
    end
    entry do
      [
        {
          'id': ig_entry_id,
          'time': '2021-09-08T06:34:04+0000',
          'messaging': [
            {
              'sender': {
                'id': sender_id
              },
              'recipient': {
                'id': 'chatwoot-app-user-id-1'
              },
              'timestamp': '2021-09-08T06:34:04+0000',
              'message': {
                'mid': 'unsupported-message-id-1',
                'is_unsupported': true
              }
            }
          ]
        }
      ]
    end
    initialize_with { attributes }
  end

  factory :messaging_seen_event, class: Hash do
    transient do
      ig_entry_id { SecureRandom.uuid }
      sender_id { "Sender-id-#{SecureRandom.hex(4)}" }
    end
    entry do
      [
        {
          'id': ig_entry_id,
          'time': '2021-09-08T06:34:04+0000',
          'messaging': [
            {
              'sender': {
                'id': sender_id
              },
              'recipient': {
                'id': 'chatwoot-app-user-id-1'
              },
              'timestamp': '2021-09-08T06:34:04+0000',
              'read': {
                'mid': 'message-id-1'
              }
            }
          ]
        }
      ]
    end
    initialize_with { attributes }
  end

  factory :instagram_test_event, class: Hash do
    entry do
      [
        {
          'id': '0',
          'time': '2021-09-08T06:34:04+0000',
          'changes': [
            {
              'field': 'messages',
              'value': {
                'sender': {
                  'id': '12334'
                },
                'recipient': {
                  'id': '23245'
                },
                'timestamp': '1527459824',
                'message': {
                  'mid': 'random_mid',
                  'text': 'random_text'
                }
              }
            }
          ]
        }
      ]
    end
    initialize_with { attributes }
  end
end
