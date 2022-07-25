# Mostly modeled after the intial implementation of the service based on 360 Dialog
# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/
class Whatsapp::IncomingMessageBaseService
  pattr_initialize [:inbox!, :params!]

  def perform
    processed_params

    perform_statuses

    set_contact
    return unless @contact

    set_conversation

    perform_messages
  end

  private

  def perform_statuses
    return if @processed_params[:statuses].blank?

    state = @processed_params[:statuses].first
    @message = Message.find_by!(source_id: state[:id])
    ActiveRecord::Base.transaction do
      if state[:status] == 'failed'
        error = state[:errors].first
        Message.create!(
          conversation_id: @message.conversation_id,
          content: "#{error[:code]}: #{error[:title]}",
          account_id: @inbox.account_id,
          inbox_id: @inbox.id,
          message_type: :activity,
          sender: @message.sender,
          source_id: @message.source_id
        )
      end
      @message.status = state[:status]
      @message.save!
    end
  end

  def perform_messages
    return if @processed_params[:messages].blank?

    @message = @conversation.messages.build(
      content: message_content(@processed_params[:messages].first),
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: @processed_params[:messages].first[:id].to_s
    )
    attach_files
    @message.save!
  end

  def processed_params
    @processed_params ||= params
  end

  def message_content(message)
    # TODO: map interactive messages back to button messages in chatwoot
    message.dig(:text, :body) ||
      message.dig(:button, :text) ||
      message.dig(:interactive, :button_reply, :title) ||
      message.dig(:interactive, :list_reply, :title)
  end

  def account
    @account ||= inbox.account
  end

  def set_contact
    contact_params = @processed_params[:contacts]&.first
    return if contact_params.blank?

    contact_inbox = ::ContactBuilder.new(
      source_id: contact_params[:wa_id],
      inbox: inbox,
      contact_attributes: { name: contact_params.dig(:profile, :name), phone_number: "+#{@processed_params[:messages].first[:from]}" }
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

    :file
  end

  def message_type
    @processed_params[:messages].first[:type]
  end

  def attach_files
    return if %w[text button interactive].include?(message_type)

    attachment_payload = @processed_params[:messages].first[message_type.to_sym]
    attachment_file = download_attachment_file(attachment_payload)

    @message.content ||= attachment_payload[:caption]
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      file: {
        io: attachment_file,
        filename: attachment_file.original_filename,
        content_type: attachment_file.content_type
      }
    )
  end

  def download_attachment_file(attachment_payload)
    Down.download(inbox.channel.media_url(attachment_payload[:id]), headers: inbox.channel.api_headers)
  end
end
