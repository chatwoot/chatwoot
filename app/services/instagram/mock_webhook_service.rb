class Instagram::MockWebhookService
  def intialize
    find_instagram_inbox
    fetch_messages
  end

  def fetch_messages
    return unless @instagram_inbox.present?

    k = Koala::Facebook::API.new(@channel.page_access_token)
    conversations = k.get_object('me/conversations',
                                 { fields: 'messages.limit(3){message,from,id},name,updated_time', platform: 'instagram', limit: 3 })

    fetch_conversation_messages(conversations['data'])
  end

  private

  def find_instagram_inbox
    @channel = Channel::FacebookPage.where.not(instagram_id: nil).last
    @instagram_inbox = channel.inbox unless @channel.present?
  end

  def inbox_last_message
    @last_message_id = @instagram_inbox.messages.incoming.last.try(:source_id)
  end

  def fetch_conversation_messages(conversations)
    if inbox_last_message.empty?
      fetch_first_message(conversations[0]['messages'])
    else
      fetch_all_messages(conversations)
    end
  end

  def fetch_all_messages(conversations)
    conversations.each do |conversation|
      conversation[:message]
      conversation[:from][:id]
      conversation[:id]
    end
  end

  def build_instagram_message_entry(conversation); end
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
