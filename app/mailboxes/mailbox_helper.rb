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

    # ensure we don't add more than the permitted number of attachments
    all_attachments = processed_mail.attachments.last(Message::NUMBER_OF_PERMITTED_ATTACHMENTS)
    grouped_attachments = group_attachments(all_attachments)

    process_inline_attachments(grouped_attachments[:inline]) if grouped_attachments[:inline].present?
    process_regular_attachments(grouped_attachments[:regular]) if grouped_attachments[:regular].present?

    @message.save!
  end

  def group_attachments(attachments)
    # If the email lacks a text body or if inline attachments aren't images,
    # treat them as standard attachments for processing.
    inline_attachments = attachments.select do |attachment|
      mail_content.present? && attachment[:original].inline? && attachment[:original].content_type.to_s.start_with?('image/')
    end

    regular_attachments = attachments - inline_attachments
    { inline: inline_attachments, regular: regular_attachments }
  end

  def process_regular_attachments(attachments)
    Rails.logger.info "[MailboxHelper] Processing regular attachments for message with ID: #{processed_mail.message_id}"
    attachments.each do |mail_attachment|
      attachment = @message.attachments.new(
        account_id: @conversation.account_id,
        file_type: 'file'
      )
      attachment.file.attach(mail_attachment[:blob])
    end
  end

  def process_inline_attachments(attachments)
    Rails.logger.info "[MailboxHelper] Processing inline attachments for message with ID: #{processed_mail.message_id}"

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
    img_tag = "<img src=\"#{inline_image_url(mail_attachment[:blob])}\" alt=\"#{attachment_name}\">"

    tag_to_replace = "[image: #{attachment_name}]"

    if @text_content.include?(tag_to_replace)
      @text_content = @text_content.gsub(tag_to_replace, img_tag)
    else
      @text_content += "\n\n#{img_tag}"
    end
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
        additional_attributes: { source_id: "email:#{processed_mail.message_id}" }
      }
    ).perform

    @contact = @contact_inbox.contact
    Rails.logger.info "[MailboxHelper] Contact created with ID: #{@contact.id} for inbox with ID: #{@inbox.id}"
  end

  def mail_content
    if processed_mail.text_content.present?
      processed_mail.text_content[:reply]
    elsif processed_mail.html_content.present?
      processed_mail.html_content[:reply]
    end
  end
end
