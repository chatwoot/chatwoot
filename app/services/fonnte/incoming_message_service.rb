class Fonnte::IncomingMessageService
  include ::FileTypeHelper

  pattr_initialize [:params!]

  def perform
    return if fonnte_channel.blank?

    Rails.logger.info "Fonnte channel: #{fonnte_channel.inspect}"
    begin
      set_contact
      set_conversation
      @message = @conversation.messages.build(
        content: message_body,
        account_id: @inbox.account_id,
        inbox_id: @inbox.id,
        message_type: :incoming,
        sender: @contact,
        source_id: params[:token]
      )
      attach_files
      @message.save!
    rescue StandardError => e
      Rails.logger.error "Fonnte send_message error: #{e.message}"
    end
  end

  private

  def fonnte_channel
    @fonnte_channel ||= ::Channel::WhatsappUnofficial.find_by(phone_number: params[:device])
    @fonnte_channel ||= ::Channel::WhatsappUnofficial.find_by!(phone_number: phone_number) if params[:device].present?

    Rails.logger.info "Fonnte channel: #{@fonnte_channel.inspect}"
    @fonnte_channel
  end

  def inbox
    @inbox ||= fonnte_channel.inbox
  end

  def account
    @account ||= inbox.account
  end

  def phone_number
    num = params[:device]
    num.present? && !num.start_with?('+') ? "+#{num}" : num
  end

  def formatted_phone_number
    TelephoneNumber.parse(phone_number).international_number
  end

  def message_body
    (params[:pesan] || params[:message])&.delete("\u0000")
  end

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: params[:pengirim] || params[:sender],
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
      additional_attributes: additional_attributes
    }
  end

  def set_conversation
    # if lock to single conversation is disabled, we will create a new conversation if previous conversation is resolved
    @conversation = if @inbox.lock_to_single_conversation
                      @contact_inbox.conversations.last
                    else
                      @contact_inbox.conversations.where
                                    .not(status: :resolved).last
                    end
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def contact_attributes
    {
      name: params[:name] || formatted_phone_number,
      phone_number: phone_number,
      additional_attributes: additional_attributes
    }
  end

  def additional_attributes
    {}
  end

  def attach_files
    return if params[:url].blank?

    attachment_file = download_attachment_file

    return if attachment_file.blank?

    content_type = attachment_file.content_type
    filename = attachment_file.original_filename

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_type(content_type),
      file: {
        io: attachment_file,
        filename: filename,
        content_type: content_type
      }
    )
  end

  def download_attachment_file
    download_with_auth
  rescue Down::Error, Down::ClientError => e
    handle_download_attachment_error(e)
  end

  def download_with_auth
    Down.download(params[:url])
  end

  # This is just a temporary workaround since some users have not yet enabled media protection. We will remove this in the future.
  def handle_download_attachment_error(error)
    Rails.logger.info "Error downloading attachment from Fonnte: #{error.message}: Retrying"
    Down.download(params[:url])
  rescue StandardError => e
    Rails.logger.info "Error downloading attachment from Fonnte: #{e.message}: Skipping"
    nil
  end
end
