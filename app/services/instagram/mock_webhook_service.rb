class Instagram::MockWebhookService
  def perform
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
    @instagram_inbox = @channel.inbox if @channel.present?
  end

  def inbox_last_message
    @last_message_id = @instagram_inbox.messages.incoming.last.try(:source_id)
  end

  def fetch_conversation_messages(data)
    # we can fetch it till inbox's last message for multiple conversations  but right now we are only considering the last conversation
    fetch_all_messages(data)
  end

  def fetch_all_messages(conversation)
    conversation = conversation.with_indifferent_access

    conversation['messages']['data'].each do |message_entry|
      params = build_instagram_message_entry(conversation, message_entry)
      send_entry_to_endpoint(params)
    end
  end

  def send_entry_to_endpoint(entries)
    @entries = entries
    # ::Webhooks::InstagramEventsJob.perform_later(params)
    @entries.each do |entry|
      entry = entry.with_indifferent_access
      entry[:messaging].each do |messaging|
        ::Instagram::MessageText.new(messaging).perform
      end
    end

    # instangram_endpoint = "#{ENV[FRONTEND_URL]}/webhooks/instagram"
    # instagram_api_key = ENV['IG_VERIFY_TOKEN']
  end

  def build_instagram_message_entry(conversation, message_entry)
    message_entry = message_entry.with_indifferent_access
    [
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
end
