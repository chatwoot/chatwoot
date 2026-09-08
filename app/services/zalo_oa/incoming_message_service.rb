class ZaloOa::IncomingMessageService
  pattr_initialize [:inbox!, :params!]

  TEXT_EVENTS = %w[user_send_text user_send_link oa_send_text].freeze
  IMAGE_EVENTS = %w[user_send_image user_send_gif user_send_sticker oa_send_image].freeze
  FILE_EVENTS = %w[user_send_file oa_send_file].freeze
  CAPTIONABLE_EVENTS = (IMAGE_EVENTS + FILE_EVENTS).freeze
  NO_CONTENT_EVENTS = %w[user_send_location user_send_audio user_send_video].freeze

  def perform
    return if user_id.blank? || source_id.blank?
    return if already_imported?

    set_contact
    set_conversation
    build_message
    attach_media
    @message.save!
  end

  private

  delegate :channel, to: :inbox

  # An outbound reply with several attachments produces several Zalo ids. SendOnZaloOaService
  # records each one in Redis as it sends, so any echo can be recognised — not just the first,
  # which is the only one stored in source_id.
  def already_imported?
    return true if inbox.messages.exists?(source_id: source_id)

    ::Redis::Alfred.exists?(format(::Redis::Alfred::ZALO_OA_SENT_MESSAGE, inbox_id: inbox.id, zalo_message_id: source_id))
  end

  def event_name
    @event_name ||= params[:event_name].to_s
  end

  def outgoing_event?
    event_name.start_with?('oa_')
  end

  # The conversation thread is always the user: they are the sender inbound,
  # and the recipient on OA-side events.
  def user_id
    @user_id ||= (outgoing_event? ? params.dig(:recipient, :id) : params.dig(:sender, :id)).to_s
  end

  def source_id
    @source_id ||= params.dig(:message, :msg_id).to_s
  end

  def message_text
    params.dig(:message, :text).to_s
  end

  def attachment_payload
    @attachment_payload ||= params.dig(:message, :attachments)&.first&.dig(:payload) || {}
  end

  def attachment_url
    @attachment_url ||= attachment_payload[:url].to_s
  end

  def set_contact
    @contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: user_id,
      inbox: inbox,
      contact_attributes: contact_attributes
    ).perform
    @contact = @contact_inbox.contact
  end

  def contact_attributes
    profile = fetch_profile
    { name: profile&.dig(:name).presence || "Zalo User #{user_id}" }
  end

  def fetch_profile
    @fetch_profile ||= ZaloOa::Client.fetch_user_profile(channel.valid_access_token, user_id)
  rescue ZaloOa::Client::Error => e
    Rails.logger.warn("Zalo OA user profile lookup failed for #{user_id}: #{e.message}")
    nil
  end

  def set_conversation
    @conversation = if inbox.lock_to_single_conversation
                      @contact_inbox.conversations.last
                    else
                      @contact_inbox.conversations.where.not(status: :resolved).last
                    end
    return if @conversation

    @conversation = ::Conversation.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    )
  end

  def build_message
    @message = @conversation.messages.build(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      message_type: outgoing_event? ? :outgoing : :incoming,
      sender: outgoing_event? ? nil : @contact,
      content: message_content,
      source_id: source_id,
      content_attributes: content_attributes
    )
  end

  def message_content
    return message_text if TEXT_EVENTS.include?(event_name)
    return message_text.presence if CAPTIONABLE_EVENTS.include?(event_name)
    return nil if NO_CONTENT_EVENTS.include?(event_name)

    "[#{event_name.presence || 'unknown'}] #{message_text}".strip
  end

  def content_attributes
    quoted = params.dig(:message, :quote_msg_id)
    quoted.present? ? { in_reply_to_external_id: quoted.to_s } : {}
  end

  def attach_media
    return attach_location if event_name == 'user_send_location'
    return if attachment_url.blank? || !attachment_url.match?(%r{\Ahttps?://}i)

    file = Down.download(attachment_url, max_size: 40.megabytes, open_timeout: 10, read_timeout: 30)
    @message.attachments.new(
      account_id: inbox.account_id,
      file_type: media_file_type,
      file: { io: file, filename: media_filename(file), content_type: file.content_type }
    )
  rescue Down::Error => e
    Rails.logger.warn("Zalo OA attachment download failed for #{source_id}: #{e.message}")
  end

  def media_file_type
    return :image if IMAGE_EVENTS.include?(event_name)
    return :audio if event_name == 'user_send_audio'
    return :video if event_name == 'user_send_video'

    :file
  end

  def media_filename(file)
    attachment_payload[:name].presence || file.original_filename.presence || "zalo-#{source_id}"
  end

  def attach_location
    coordinates = attachment_payload[:coordinates] || {}
    return if coordinates[:latitude].blank? || coordinates[:longitude].blank?

    @message.attachments.new(
      account_id: inbox.account_id,
      file_type: :location,
      coordinates_lat: coordinates[:latitude],
      coordinates_long: coordinates[:longitude],
      fallback_title: message_text
    )
  end
end
