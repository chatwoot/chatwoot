# Find the various telegram payload samples here: https://core.telegram.org/bots/webhooks#testing-your-bot-with-updates
# https://core.telegram.org/bots/api#available-types

class Telegram::IncomingMessageService
  include ::FileTypeHelper
  pattr_initialize [:inbox!, :params!]

  def perform
    # chatwoot doesn't support group conversations at the moment
    return unless private_message?

    set_contact
    update_contact_avatar
    set_conversation
    @message = @conversation.messages.create(
      content: params[:message][:text],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: (params[:message][:message_id]).to_s
    )
    attach_files
    @message.save!
  end

  private

  def private_message?
    params.dig(:message, :chat, :type) == 'private'
  end

  def set_contact
    contact_inbox = ::ContactBuilder.new(
      source_id: params[:message][:from][:id],
      inbox: inbox,
      contact_attributes: contact_attributes
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def update_contact_avatar
    return if @contact.avatar.attached?

    avatar_url = inbox.channel.get_telegram_profile_image(params[:message][:from][:id])
    ::ContactAvatarJob.perform_later(@contact, avatar_url) if avatar_url
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
      name: "#{params[:message][:from][:first_name]} #{params[:message][:from][:last_name]}",
      additional_attributes: additional_attributes
    }
  end

  def additional_attributes
    {
      username: params[:message][:from][:username],
      language_code: params[:message][:from][:language_code]
    }
  end

  def conversation_additional_attributes
    {
      chat_id: params[:message][:chat][:id]
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
        filename: attachment_file,
        content_type: attachment_file.content_type
      }
    )
  end

  def file
    @file ||= params[:message][:photo].presence&.last || params.dig(:message, :sticker, :thumb).presence || params[:message][:voice].presence || params[:message][:audio].presence ||
              params[:message][:video].presence || params[:message][:document].presence
  end
end
