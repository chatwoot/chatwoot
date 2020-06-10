class Twitter::DirectMessageParserService < Twitter::WebhooksBaseService
  pattr_initialize [:payload]

  def perform
    return if source_app_id == parent_app_id

    set_inbox
    ensure_contacts
    set_conversation
    @conversation.messages.create(
      content: message_create_data['message_data']['text'],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: outgoing_message? ? :outgoing : :incoming,
      sender: @contact,
      source_id: direct_message_data['id']
    )
  end

  private

  def direct_message_events_params
    payload['direct_message_events']
  end

  def direct_message_data
    direct_message_events_params.first
  end

  def message_create_data
    direct_message_data['message_create']
  end

  def source_app_id
    message_create_data['source_app_id']
  end

  def parent_app_id
    ENV.fetch('TWITTER_APP_ID', '')
  end

  def users
    payload[:users]
  end

  def ensure_contacts
    users.each do |key, user|
      next if key == profile_id

      find_or_create_contact(user)
    end
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: {
        type: 'direct_message'
      }
    }
  end

  def set_conversation
    @conversation = @contact_inbox.conversations.where("additional_attributes ->> 'type' = 'direct_message'").first
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def outgoing_message?
    message_create_data['sender_id'] == @inbox.channel.profile_id
  end
end
