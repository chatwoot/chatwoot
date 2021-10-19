module MailboxHelper
  private

  def create_message
    @message = @conversation.messages.create(
      account_id: @conversation.account_id,
      sender: @conversation.contact,
      content: processed_mail.text_content[:reply],
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
end
