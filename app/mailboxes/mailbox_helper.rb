module MailboxHelper
  private

  def create_message
    Rails.logger.info "[MailboxHelper] Creating message #{processed_mail.message_id}"
    return if @conversation.messages.find_by(source_id: processed_mail.message_id).present?

    @message = @conversation.messages.create!(
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
    return if @message.blank?

    all_attachments = processed_mail.attachments.last(Message::NUMBER_OF_PERMITTED_ATTACHMENTS)

    inline_attachments = all_attachments.select { |attachment| attachment[:original].inline? }
    regular_attachments = all_attachments - inline_attachments

    process_inline_attachments(inline_attachments) if inline_attachments.present?
    process_regular_attachments(regular_attachments) if regular_attachments.present?

    @message.save!
  end

  def process_regular_attachments(attachments)
    Rails.logger.info "[MailboxHelper] Processing regular attachments for message with ID: #{@message.id}"
    attachments.each do |mail_attachment|
      attachment = @message.attachments.new(
        account_id: @conversation.account_id,
        file_type: 'file'
      )
      attachment.file.attach(mail_attachment[:blob])
    end
  end

  def process_inline_attachments(attachments)
    Rails.logger.info "[MailboxHelper] Processing inline attachments for message with ID: #{@message.id}"
    @html_content = processed_mail.serialized_data[:html_content][:full]
    @text_content = processed_mail.serialized_data[:text_content][:reply]

    attachments.each do |mail_attachment|
      embed_inline_image_source(mail_attachment)
    end

    @message.content_attributes[:email][:html_content][:full] = @html_content
    @message.content_attributes[:email][:text_content][:full] = @text_content
  end

  def create_contact
    @contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: processed_mail.original_sender,
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
    Rails.logger.info "[MailboxHelper] Contact created with ID: #{@contact.id} for inbox with ID: #{@inbox.id}"
  end
end
