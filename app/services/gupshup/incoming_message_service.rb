class Gupshup::IncomingMessageService
  include ::FileTypeHelper

  pattr_initialize [:params!]

  def perform
    set_contact
    set_conversation
    @message = @conversation.messages.create(
      content: payload,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: params[:payload][:source]
    )
    attach_files
  end

  private
  def payload
    # Setting content parameter based on message type.
    content = case params[:payload][:type]
              when 'text'
                params[:payload][:payload][:text]
              when 'image'
                params[:payload][:payload][:caption]
              when 'video'
                params[:payload][:payload][:caption]
              end
    content
  end
  def gupshup_inbox
    @gupshup_inbox ||= ::Channel::Gupshup.find_by!(
      app: params[:app]
    )
  end

  def inbox
    @inbox ||= gupshup_inbox.inbox
  end

  def account
    @account ||= inbox.account
  end

  def phone_number
    params[:source]
  end

  def contact_name
    params[:payload][:sender][:name]
  end

  def set_contact

    contact_inbox = ::ContactBuilder.new(
      source_id: params[:payload][:source],
      inbox: inbox,
      contact_attributes: contact_attributes
    ).perform
    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
    }
  end

  def set_conversation
    @conversation = @contact_inbox.conversations.first
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def contact_attributes
    {
      name: contact_name,
      phone_number: phone_number
    }
  end

  def attach_files
    return if params[:payload][:payload][:url].blank?
    file_resource = LocalResource.new(params[:payload][:payload][:url], params[:payload][:payload][:contentType])
    attachment = @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_type(params[:payload][:payload][:contentType])
    )
    attachment.file.attach(
      io: file_resource.file,
      filename: file_resource.tmp_filename,
      content_type: file_resource.encoding
    )
    @message.save!
  rescue *ExceptionList::URI_EXCEPTIONS => e
    Rails.logger.info "invalid url #{file_url} : #{e.message}"
  end
end
