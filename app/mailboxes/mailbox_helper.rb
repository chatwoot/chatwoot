module MailboxHelper
  private

  def create_message
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

    # ensure we don't add more than the permitted number of attachments
    all_attachments = processed_mail.attachments.last(Message::NUMBER_OF_PERMITTED_ATTACHMENTS)

    inline_attachments = all_attachments.select { |attachment| attachment[:original].inline? }
    regular_attachments = all_attachments - inline_attachments

    process_inline_attachments(inline_attachments) if inline_attachments.present?
    process_regular_attachments(regular_attachments) if regular_attachments.present?

    @message.save!
  end

  def process_regular_attachments(attachments)
    attachments.each do |mail_attachment|
      attachment = @message.attachments.new(
        account_id: @conversation.account_id,
        file_type: 'file'
      )
      attachment.file.attach(mail_attachment[:blob])
    end
  end

  def process_inline_attachments(attachments)
    # create an instance variable here, the `embed_inline_image_source`
    # updates them directly. And then the value is eventaully used to update the message content
    @html_content = processed_mail.serialized_data[:html_content][:full]
    @text_content = processed_mail.serialized_data[:text_content][:reply]

    attachments.each do |mail_attachment|
      embed_inline_image_source(mail_attachment)
    end

    # update the message content with the updated html and text content
    @message.content_attributes[:email][:html_content][:full] = @html_content
    @message.content_attributes[:email][:text_content][:full] = @text_content
  end

  def embed_inline_image_source(mail_attachment)
    if @html_content.present?
      upload_inline_image(mail_attachment)
    elsif @text_content.present?
      embed_plain_text_email_with_inline_image(mail_attachment)
    end
  end

  def upload_inline_image(mail_attachment)
    content_id = mail_attachment[:original].cid

    @html_content = @html_content.gsub("cid:#{content_id}", inline_image_url(mail_attachment[:blob]).to_s)
  end

  def embed_plain_text_email_with_inline_image(mail_attachment)
    attachment_name = mail_attachment[:original].filename

    @text_content = @text_content.gsub(
      "[image: #{attachment_name}]", "<img src=\"#{inline_image_url(mail_attachment[:blob])}\" alt=\"#{attachment_name}\">"
    )
  end

  def inline_image_url(blob)
    Rails.application.routes.url_helpers.url_for(blob)
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
