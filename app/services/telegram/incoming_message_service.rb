# Find the various telegram payload samples here: https://core.telegram.org/bots/webhooks#testing-your-bot-with-updates
# https://core.telegram.org/bots/api#available-types

class Telegram::IncomingMessageService
  include ::FileTypeHelper
  include ::Telegram::ParamHelpers
  pattr_initialize [:inbox!, :params!]

  def perform
    # chatwoot doesn't support group conversations at the moment
    return unless private_message?

    set_contact
    update_contact_avatar
    set_conversation
    @message = @conversation.messages.build(
      content: telegram_params_message_content,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
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

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def process_message_attachments
    attach_location
    attach_files
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
    @conversation = @contact_inbox.conversations.first
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
      username: telegram_params_username,
      language_code: telegram_params_language_code
    }
  end

  def conversation_additional_attributes
    {
      chat_id: telegram_params_chat_id
    }
  end

  def file_content_type
    return :image if params[:message][:photo].present? || params.dig(:message, :sticker, :thumb).present?
    return :audio if params[:message][:voice].present? || params[:message][:audio].present?
    return :video if params[:message][:video].present?

    file_type(params[:message][:document][:mime_type])
  end

  def attach_files
    return unless file

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
      coordinates_lat: location['latitude'],
      coordinates_long: location['longitude']
    )
  end

  def file
    @file ||= visual_media_params || params[:message][:voice].presence || params[:message][:audio].presence || params[:message][:document].presence
  end

  def location
    @location ||= params.dig(:message, :location).presence
  end

  def visual_media_params
    params[:message][:photo].presence&.last || params.dig(:message, :sticker, :thumb).presence || params[:message][:video].presence
  end
end
