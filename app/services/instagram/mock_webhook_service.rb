class Instagram::MockWebhookService
  def intialize
    find_instagram_inbox
    fetch_messages
  end

  def fetch_messages
    return unless @instagram_inbox.present?

    k = Koala::Facebook::API.new(@channel.page_access_token)
    conversations = k.get_object('me/conversations',
                                 { fields: 'messages.limit(3){message,from,to,id,created_time},name,updated_time', platform: 'instagram', limit: 3 })

    fetch_conversation_messages(conversations[0])
  end

  private

  def find_instagram_inbox
    @channel = Channel::FacebookPage.where.not(instagram_id: nil).last
    @instagram_inbox = channel.inbox if @channel.present?
  end

  def inbox_last_message
    @last_message_id = @instagram_inbox.messages.incoming.last.try(:source_id)
  end

  def fetch_conversation_messages(data)
    if inbox_last_message.empty?
      fetch_first_message(data['messages']['data'][0])
    else
      fetch_all_messages(data)
    end
  end

  def fetch_all_messages(conversation)
    conversation = conversation.with_indifferent_access

    conversation['messages']['data'].each do |message_entry|
      build_instagram_message_entry(conversation, message_entry)
    end
  end

  def send_entry_to_endpoint
    instangram_endpoint = "#{ENV[FRONTEND_URL]}/webhooks/instagram"
  end

  def build_instagram_message_entry(conversation, message_entry)
    message_entry = message_entry.with_indifferent_access
    entry = [
      {
        'id': conversation[:id],
        'time': conversation[:updated_time],
        'messaging': [
          {
            'sender': {
              'id': message_entry[:from][:id]
            },
            'recipient': {
              'id': message_entry[:to][:data][0][:id]
            },
            'timestamp': message_entry[:created_time],
            'message': {
              'mid': message_entry[:id],
              'text': message_entry[:message]
            }
          }
        ]
      }
    ]
  end

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
