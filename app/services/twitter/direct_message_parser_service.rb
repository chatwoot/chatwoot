class Twitter::DirectMessageParserService < Twitter::WebhooksBaseService
  pattr_initialize [:payload]

  def perform
    return if source_app_id == parent_app_id

    set_inbox
    ensure_contacts
    set_conversation
    @message = @conversation.messages.create!(
      content: message_create_data['message_data']['text'],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: outgoing_message? ? :outgoing : :incoming,
      sender: @contact,
      source_id: direct_message_data['id']
    )
    attach_files
  end

  private

  def attach_files
    return if message_create_data['message_data']['attachment'].blank?

    save_media
    @message
  end

  def save_media_urls(file)
    @message.content_attributes[:media_url] = file['media_url']
    @message.content_attributes[:display_url] = file['display_url']
    @message.save!
  end

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

  def media
    message_create_data['message_data']['attachment']['media']
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

  def api_client
    @api_client ||= begin
      consumer = OAuth::Consumer.new(ENV.fetch('TWITTER_CONSUMER_KEY', nil), ENV.fetch('TWITTER_CONSUMER_SECRET', nil),
                                     { site: 'https://api.twitter.com' })
      token = { oauth_token: @inbox.channel.twitter_access_token, oauth_token_secret: @inbox.channel.twitter_access_token_secret }
      OAuth::AccessToken.from_hash(consumer, token)
    end
  end

  def save_media
    save_media_urls(media)
    response = api_client.get(media['media_url'], [])

    temp_file = Tempfile.new('twitter_attachment')
    temp_file.binmode
    temp_file << response.body
    temp_file.rewind

    return unless media['type'] == 'photo'

    @message.attachments.new(
      account_id: @inbox.account_id,
      file_type: 'image',
      file: {
        io: temp_file,
        filename: 'twitter_attachment',
        content_type: media['type']
      }
    )
    @message.save!
  end
end
