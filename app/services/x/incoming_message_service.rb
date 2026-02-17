class X::IncomingMessageService
  pattr_initialize [:channel!, :dm_event, :tweet_data, :users]

  def perform
    return if outgoing_dm?
    return if message_exists?

    create_message
  end

  private

  def outgoing_dm?
    direct_message? && sender_id == channel.profile_id
  end

  def outgoing_tweet?
    tweet_message? && sender_id == channel.profile_id
  end

  def message_exists?
    Message.exists?(source_id: message_source_id)
  end

  def contact_inbox
    @contact_inbox ||= ::ContactInboxWithContactBuilder.new(
      source_id: sender_id,
      inbox: channel.inbox,
      contact_attributes: contact_attributes
    ).perform
  end

  def contact
    contact_inbox.contact
  end

  def conversation
    @conversation ||= find_existing_conversation || create_conversation
  end

  def find_existing_conversation
    if tweet_message?
      find_tweet_conversation
    else
      find_dm_conversation
    end
  end

  def find_tweet_conversation
    parent_id = parent_tweet_id

    tweet_conv = Conversation.where(inbox_id: channel.inbox.id)
                             .where("additional_attributes ->> 'tweet_id' = ?", parent_id)
                             .first
    return tweet_conv if tweet_conv

    parent_message = channel.inbox.messages.find_by(source_id: parent_id)
    return parent_message.conversation if parent_message

    nil
  end

  def find_dm_conversation
    contact_inbox.conversations.where("additional_attributes ->> 'type' = 'direct_message'").first
  end

  def create_conversation
    ::Conversation.create!(
      account_id: channel.inbox.account_id,
      inbox_id: channel.inbox.id,
      contact_id: contact.id,
      contact_inbox_id: contact_inbox.id,
      additional_attributes: conversation_additional_attributes
    )
  end

  def conversation_additional_attributes
    if tweet_message?
      {
        type: 'tweet',
        tweet_id: parent_tweet_id
      }
    else
      {
        type: 'direct_message'
      }
    end
  end

  def parent_tweet_id
    @tweet_data[:in_reply_to_status_id_str].presence || @tweet_data[:id_str]
  end

  def create_message
    msg = conversation.messages.build(
      content: message_content,
      account_id: channel.inbox.account_id,
      inbox_id: channel.inbox.id,
      message_type: message_type,
      source_id: message_source_id,
      content_attributes: message_content_attributes,
      created_at: message_timestamp,
      updated_at: message_timestamp
    )

    msg.sender = contact unless outgoing_tweet?

    create_attachments(msg)
    msg.save!

    update_conversation_tweet_id if tweet_message?
  end

  def message_type
    outgoing_tweet? ? :outgoing : :incoming
  end

  def update_conversation_tweet_id
    attrs = conversation.additional_attributes || {}
    attrs['tweet_id'] = parent_tweet_id
    conversation.update!(additional_attributes: attrs)
  end

  def contact_attributes
    user_data = fetch_user_profile
    username = user_data['screen_name'] || user_data['username']

    {
      name: user_data['name'] || username,
      avatar_url: user_data['profile_image_url'] || user_data['profile_image_url_https'],
      additional_attributes: {
        screen_name: username,
        username: username,
        social_profiles: { x: username },
        social_x_user_id: sender_id,
        description: user_data['description'],
        location: user_data['location']
      }
    }
  end

  def fetch_user_profile
    return @users[sender_id].with_indifferent_access if @users.present? && @users[sender_id].present?
    return @tweet_data[:user].with_indifferent_access if @tweet_data&.[](:user).present?

    channel.client.user(sender_id)['data']
  rescue StandardError => e
    Rails.logger.error("Failed to fetch X user profile for #{sender_id}: #{e.message}")
    { 'username' => sender_id, 'name' => sender_id }
  end

  def create_attachments(msg)
    dm_attachment = @dm_event&.dig(:message_create, :message_data, :attachment)
    create_dm_attachment(msg, dm_attachment) if direct_message? && dm_attachment.present?
    create_tweet_attachments(msg) if tweet_message? && @tweet_data&.[](:extended_entities).present?
  end

  def create_dm_attachment(msg, attachment)
    return unless attachment[:type] == 'media'

    media_data = attachment[:media]
    url = media_data[:url]
    att = msg.attachments.new(account_id: msg.account_id, file_type: determine_dm_file_type(media_data), external_url: url)
    attach_file(att, url)
  end

  def determine_dm_file_type(media)
    content_type = media[:content_type] || ''
    return :image if content_type.start_with?('image/')
    return :video if content_type.start_with?('video/')
    return :audio if content_type.start_with?('audio/')

    :file
  end

  def create_tweet_attachments(msg)
    @tweet_data[:extended_entities][:media]&.each do |media|
      url = media_url_for_tweet(media)
      att = msg.attachments.new(
        account_id: msg.account_id,
        file_type: determine_tweet_file_type(media[:type]),
        external_url: url
      )
      attach_file(att, url)
    end
  end

  def determine_tweet_file_type(media_type)
    case media_type
    when 'photo' then :image
    when 'animated_gif' then :video
    when 'video' then :video
    else :file
    end
  end

  def attach_file(attachment, url)
    file = Down.download(url)
    attachment.file.attach(io: file, filename: file.original_filename, content_type: file.content_type)
  rescue Down::Error, StandardError => e
    Rails.logger.warn "Failed to download X media attachment: #{e.message}"
  end

  def media_url_for_tweet(media)
    if media[:type] == 'video' || media[:type] == 'animated_gif'
      best_variant = media.dig(:video_info, :variants)&.select { |v| v[:content_type] == 'video/mp4' }&.max_by { |v| v[:bitrate].to_i }
      best_variant&.dig(:url) || media[:media_url_https]
    else
      media[:media_url_https]
    end
  end

  def message_content
    return @dm_event.dig(:message_create, :message_data, :text) if direct_message?
    return clean_tweet_text if tweet_message?

    ''
  end

  def clean_tweet_text
    text = @tweet_data[:truncated] ? @tweet_data.dig(:extended_tweet, :full_text) : @tweet_data[:text]
    display_range = @tweet_data[:display_text_range]
    text = text[display_range[0]..display_range[1] - 1] if display_range.present?
    text&.strip || ''
  end

  def message_content_attributes
    return {} unless tweet_message?

    { 'in_reply_to_external_id' => @tweet_data[:in_reply_to_status_id_str] || @tweet_data[:id_str] }
  end

  def sender_id
    return @dm_event.dig(:message_create, :sender_id) if direct_message?

    @tweet_data&.dig(:user, :id_str)
  end

  def message_source_id
    return @dm_event[:id] if direct_message?

    @tweet_data&.[](:id_str)
  end

  def message_timestamp
    return Time.zone.at(@dm_event[:created_timestamp].to_i / 1000).utc if direct_message?
    return Time.zone.parse(@tweet_data[:created_at]).utc if tweet_message?

    Time.current.utc
  end

  def direct_message?
    @dm_event.present?
  end

  def tweet_message?
    @tweet_data.present?
  end
end
