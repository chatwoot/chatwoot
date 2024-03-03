class Twilio::IncomingMessageService
  include ::FileTypeHelper

  pattr_initialize [:params!]

  def perform
    return if twilio_channel.blank?

    set_contact
    set_conversation
    @message = @conversation.messages.create!(
      content: message_body,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: params[:SmsSid]
    )
    attach_files
  end

  private

  def twilio_channel
    @twilio_channel ||= ::Channel::TwilioSms.find_by(messaging_service_sid: params[:MessagingServiceSid]) if params[:MessagingServiceSid].present?
    if params[:AccountSid].present? && params[:To].present?
      @twilio_channel ||= ::Channel::TwilioSms.find_by!(account_sid: params[:AccountSid],
                                                        phone_number: params[:To])
    end
    @twilio_channel
  end

  def inbox
    @inbox ||= twilio_channel.inbox
  end

  def account
    @account ||= inbox.account
  end

  def phone_number
    twilio_channel.sms? ? params[:From] : params[:From].gsub('whatsapp:', '')
  end

  def formatted_phone_number
    TelephoneNumber.parse(phone_number).international_number
  end

  def message_body
    params[:Body]&.delete("\u0000")
  end

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: params[:From],
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
      name: formatted_phone_number,
      phone_number: phone_number,
      additional_attributes: additional_attributes
    }
  end

  def additional_attributes
    if twilio_channel.sms?
      {
        from_zip_code: params[:FromZip],
        from_country: params[:FromCountry],
        from_state: params[:FromState]
      }
    else
      {}
    end
  end

  def attach_files
    return if params[:MediaUrl0].blank?

    attachment_file = download_attachment_file

    return if attachment_file.blank?

    attachment = @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_type(params[:MediaContentType0])
    )

    attachment.file.attach(
      io: attachment_file,
      filename: attachment_file.original_filename,
      content_type: attachment_file.content_type
    )

    @message.save!
  end

  def download_attachment_file
    download_with_auth
  rescue Down::Error, Down::ClientError => e
    handle_download_attachment_error(e)
  end

  def download_with_auth
    Down.download(
      params[:MediaUrl0],
      # https://support.twilio.com/hc/en-us/articles/223183748-Protect-Media-Access-with-HTTP-Basic-Authentication-for-Programmable-Messaging
      http_basic_authentication: [twilio_channel.account_sid, twilio_channel.auth_token || twilio_channel.api_key_sid]
    )
  end

  # This is just a temporary workaround since some users have not yet enabled media protection. We will remove this in the future.
  def handle_download_attachment_error(error)
    Rails.logger.info "Error downloading attachment from Twilio: #{error.message}: Retrying"
    Down.download(params[:MediaUrl0])
  rescue StandardError => e
    Rails.logger.info "Error downloading attachment from Twilio: #{e.message}: Skipping"
    nil
  end
end
