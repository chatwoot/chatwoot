# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/

class Whatsapp::IncomingMessageService
  pattr_initialize [:inbox!, :params!]

  def perform
    set_contact
    return unless @contact

    set_conversation

    return if params[:messages].blank?

    @message = @conversation.messages.build(
      content: params[:messages].first.dig(:text, :body),
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: params[:messages].first[:id].to_s
    )
    attach_files
    @message.save!
  end

  private

  def account
    @account ||= inbox.account
  end

  def set_contact
    contact_params = params[:contacts]&.first
    return if contact_params.blank?

    contact_inbox = ::ContactBuilder.new(
      source_id: contact_params[:wa_id],
      inbox: inbox,
      contact_attributes: { name: contact_params.dig(:profile, :name), phone_number: "+#{params[:messages].first[:from]}" }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    }
  end

  def set_conversation
    @conversation = @contact_inbox.conversations.last
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def file_content_type(file_type)
    return :image if %w[image sticker].include?(file_type)
    return :audio if %w[audio voice].include?(file_type)
    return :video if ['video'].include?(file_type)

    'document'
  end

  def attach_files
    message_type = params[:messages].first[:type]
    return if message_type == 'text'

    attachment_payload = params[:messages].first[message_type.to_sym]
    attachment_file = Down.download(inbox.channel.media_url(attachment_payload[:id]), headers: inbox.channel.api_headers)

    @message.content ||= attachment_payload[:caption]
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      file: {
        io: attachment_file,
        filename: attachment_file,
        content_type: attachment_file.content_type
      }
    )
  end
end
