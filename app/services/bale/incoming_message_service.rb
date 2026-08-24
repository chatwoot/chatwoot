class Bale::IncomingMessageService
  include ::FileTypeHelper
  include ::Bale::ParamHelpers
  pattr_initialize [:inbox!, :params!]

  def perform
    return unless private_message?

    set_contact
    update_contact_avatar
    set_conversation
    @message = @conversation.messages.build(
      content: bale_params_message_content,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      content_attributes: bale_params_content_attributes,
      source_id: bale_params_message_id.to_s
    )

    process_message_attachments if message_params?
    @message.save!
  end

  private

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: bale_params_from_id,
      inbox: inbox,
      contact_attributes: contact_attributes
    ).perform
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

    avatar_url = inbox.channel.get_bale_profile_image(bale_params_from_id)
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
      name: "#{bale_params_first_name} #{bale_params_last_name}",
      additional_attributes: additional_attributes
    }
  end

  def additional_attributes
    {
      username: bale_params_username,
      language_code: bale_params_language_code,
      social_bale_user_id: bale_params_from_id,
      social_bale_user_name: bale_params_username
    }
  end

  def conversation_additional_attributes
    {
      chat_id: bale_params_chat_id
    }
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

    file_download_path = inbox.channel.get_bale_file_path(file[:file_id])
    if file_download_path.blank?
      Rails.logger.info "Bale file download path is blank for #{file[:file_id]} : inbox_id: #{inbox.id}"
      return
    end

    attachment_file = Down.download(file_download_path)
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type,
      file: {
        io: attachment_file,
        filename: file[:file_name].presence || attachment_file.original_filename,
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
end
