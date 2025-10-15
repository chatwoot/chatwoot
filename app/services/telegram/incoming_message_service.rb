# Find the various telegram payload samples here: https://core.telegram.org/bots/webhooks#testing-your-bot-with-updates
# https://core.telegram.org/bots/api#available-types

class Telegram::IncomingMessageService
  include ::FileTypeHelper
  include ::Telegram::ParamHelpers
  pattr_initialize [:inbox!, :params!]

  def perform
    # chatwoot doesn't support group conversations at the moment
    transform_business_message!
    return unless private_message?

    set_contact
    update_contact_avatar
    set_conversation
    # TODO: Since the recent Telegram Business update, we need to explicitly mark messages as read using an additional request.
    # Otherwise, the client will see their messages as unread.
    # Chatwoot defines a 'read' status in its enum but does not currently update this status for Telegram conversations.
    # We have two options:
    # 1. Send the read request to Telegram here, immediately when the message is created.
    # 2. Properly update the read status in the Chatwoot UI and trigger the Telegram request when the agent actually reads the message.
    # See: https://core.telegram.org/bots/api#readbusinessmessage
    @message = @conversation.messages.build(
      content: telegram_params_message_content,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: message_type,
      sender: message_sender,
      content_attributes: telegram_params_content_attributes,
      source_id: telegram_params_message_id.to_s
    )

    process_message_attachments if message_params?
    @message.save!
  end

  private

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: telegram_params_from_id,
      inbox: inbox,
      contact_attributes: contact_attributes
    ).perform

    # TODO: Should we update contact_attributes when the user changes their first or last name?
    # In business chats, when our Telegram bot initiates the conversation,
    # the message does not include a language code.
    # This is critical for AI assistants and translation plugins.

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def process_message_attachments
    attach_location
    attach_files
    attach_contact
  end

  def update_contact_avatar
    return if @contact.avatar.attached?

    avatar_url = inbox.channel.get_telegram_profile_image(telegram_params_from_id)
    ::Avatar::AvatarFromUrlJob.perform_later(@contact, avatar_url) if avatar_url
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: conversation_additional_attributes
    }
  end

  def set_conversation
    # if lock to single conversation is disabled, we will create a new conversation if previous conversation is resolved
    @conversation = if @inbox.lock_to_single_conversation
                      @contact_inbox.conversations.last
                    else
                      @contact_inbox.conversations
                                    .where.not(status: :resolved).last
                    end
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def contact_attributes
    {
      name: "#{telegram_params_first_name} #{telegram_params_last_name}",
      additional_attributes: additional_attributes
    }
  end

  def additional_attributes
    {
      # TODO: Remove this once we show the social_telegram_user_name in the UI instead of the username
      username: telegram_params_username,
      language_code: telegram_params_language_code,
      social_telegram_user_id: telegram_params_from_id,
      social_telegram_user_name: telegram_params_username
    }
  end

  def conversation_additional_attributes
    {
      chat_id: telegram_params_chat_id,
      business_connection_id: telegram_params_business_connection_id
    }
  end

  def message_type
    business_message_outgoing? ? :outgoing : :incoming
  end

  def message_sender
    business_message_outgoing? ? nil : @contact
  end

  def file_content_type
    return :image if image_message?
    return :audio if audio_message?
    return :video if video_message?

    file_type(params[:message][:document][:mime_type])
  end

  def image_message?
    params[:message][:photo].present? || params.dig(:message, :sticker, :thumb).present?
  end

  def audio_message?
    params[:message][:voice].present? || params[:message][:audio].present?
  end

  def video_message?
    params[:message][:video].present? || params[:message][:video_note].present?
  end

  def attach_files
    return unless file

    file_download_path = inbox.channel.get_telegram_file_path(file[:file_id])
    if file_download_path.blank?
      Rails.logger.info "Telegram file download path is blank for #{file[:file_id]} : inbox_id: #{inbox.id}"
      return
    end

    attachment_file = Down.download(
      inbox.channel.get_telegram_file_path(file[:file_id])
    )

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type,
      file: {
        io: attachment_file,
        filename: attachment_file.original_filename,
        content_type: attachment_file.content_type
      }
    )
  end

  def attach_location
    return unless location

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: :location,
      fallback_title: location_fallback_title,
      coordinates_lat: location['latitude'],
      coordinates_long: location['longitude']
    )
  end

  def attach_contact
    return unless contact_card

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: :contact,
      fallback_title: contact_card['phone_number'].to_s,
      meta: {
        first_name: contact_card['first_name'],
        last_name: contact_card['last_name']
      }
    )
  end

  def file
    @file ||= visual_media_params || params[:message][:voice].presence || params[:message][:audio].presence || params[:message][:document].presence
  end

  def location_fallback_title
    return '' if venue.blank?

    venue[:title] || ''
  end

  def venue
    @venue ||= params.dig(:message, :venue).presence
  end

  def location
    @location ||= params.dig(:message, :location).presence
  end

  def contact_card
    @contact_card ||= params.dig(:message, :contact).presence
  end

  def visual_media_params
    params[:message][:photo].presence&.last ||
      params.dig(:message, :sticker, :thumb).presence ||
      params[:message][:video].presence ||
      params[:message][:video_note].presence
  end

  def transform_business_message!
    params[:message] = params[:business_message] if params[:business_message] && !params[:message]
  end
end
