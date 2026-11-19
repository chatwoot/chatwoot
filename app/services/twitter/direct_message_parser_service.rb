class Twitter::DirectMessageParserService < Twitter::WebhooksBaseService
  MEDIA_HOSTS = %w[ton.twitter.com pbs.twimg.com].freeze

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

  def media_url
    (media['media_url_https'].presence || media['media_url']).to_s
  end

  def twitter_media_url?
    uri = URI.parse(media_url)
    uri.is_a?(URI::HTTPS) && uri.userinfo.nil? && uri.port == 443 && MEDIA_HOSTS.include?(uri.host.to_s.downcase)
  rescue URI::InvalidURIError
    false
  end

  def media_authorization_header
    uri = URI.parse(media_url)
    consumer = OAuth::Consumer.new(ENV.fetch('TWITTER_CONSUMER_KEY', nil), ENV.fetch('TWITTER_CONSUMER_SECRET', nil),
                                   { site: "https://#{uri.host}" })
    token = { oauth_token: @inbox.channel.twitter_access_token, oauth_token_secret: @inbox.channel.twitter_access_token_secret }
    request = Net::HTTP::Get.new(uri)
    OAuth::AccessToken.from_hash(consumer, token).sign!(request)
    request['Authorization']
  end

  def save_media
    save_media_urls(media)
    return unless media['type'] == 'photo' && twitter_media_url?

    SafeFetch.fetch(media_url, headers: { 'Authorization' => media_authorization_header }) do |result|
      @message.attachments.new(
        account_id: @inbox.account_id,
        file_type: 'image',
        file: {
          io: result.tempfile,
          filename: 'twitter_attachment',
          content_type: result.content_type
        }
      )
      @message.save!
    end
  rescue SafeFetch::Error => e
    Rails.logger.warn("[TWITTER] skipping media download: #{e.class}")
  end
end
