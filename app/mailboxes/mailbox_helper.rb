module MailboxHelper
  private

  def create_message
    return if @conversation.messages.find_by(source_id: processed_mail.message_id).present?

    @message = @conversation.messages.create(
      account_id: @conversation.account_id,
      sender: @conversation.contact,
      content: mail_content&.truncate(150_000),
      inbox_id: @conversation.inbox_id,
      message_type: 'incoming',
      content_type: 'incoming_email',
      source_id: processed_mail.message_id,
      content_attributes: {
        email: processed_mail.serialized_data,
        cc_email: processed_mail.cc,
        bcc_email: processed_mail.bcc
      }
    )
  end

  def add_attachments_to_message
    processed_mail.attachments.each do |mail_attachment|
      attachment = @message.attachments.new(
        account_id: @conversation.account_id,
        file_type: 'file'
      )
      attachment.file.attach(mail_attachment[:blob])
    end
    @message.save!
  end

  def create_contact
    @contact_inbox = ::ContactBuilder.new(
      source_id: "email:#{processed_mail.message_id}",
      inbox: @inbox,
      contact_attributes: {
        name: identify_contact_name,
        email: processed_mail.original_sender,
        additional_attributes: {
          source_id: "email:#{processed_mail.message_id}"
        }
      }
    ).perform
    @contact = @contact_inbox.contact
  end

  def notification_email_from_chatwoot?
    # notification emails are send via mailer sender email address. so it should match
    @processed_mail.original_sender == Mail::Address.new(ENV.fetch('MAILER_SENDER_EMAIL', 'Chatwoot <accounts@chatwoot.com>')).address
  end

  def mail_content
    if processed_mail.text_content.present?
      processed_mail.text_content[:reply]
    elsif processed_mail.html_content.present?
      processed_mail.html_content[:reply]
    end
  end
end
