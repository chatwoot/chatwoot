module MailboxHelper
  include MailboxInlineAttachmentHelper
  include MailboxSanitizer
  include ::FileTypeHelper

  private

  def create_message
    Rails.logger.info "[MailboxHelper] Creating message #{processed_mail.message_id}"
    source_id = sanitize_mailbox_value(processed_mail.message_id)
    return if @conversation.messages.find_by(source_id: source_id).present?

    @message = @conversation.messages.create!(sanitized_message_attributes(source_id))
  end

  def add_attachments_to_message
    return if @message.blank?

    # Load email content once for all attachment processing
    load_email_content

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
      inline_attachment?(attachment)
    end

    regular_attachments = attachments - inline_attachments
    { inline: inline_attachments, regular: regular_attachments }
  end

  def process_regular_attachments(attachments)
    Rails.logger.info "[MailboxHelper] Processing regular attachments for message with ID: #{processed_mail.message_id}"
    attachments.each do |mail_attachment|
      blob = mail_attachment[:blob]
      attachment = @message.attachments.new(
        account_id: @conversation.account_id,
        file_type: file_type(blob.content_type)
      )
      attachment.file.attach(blob)
    end
  end

  def process_inline_attachments(attachments)
    Rails.logger.info "[MailboxHelper] Processing inline attachments for message with ID: #{processed_mail.message_id}"

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
    sender_email = sanitize_mailbox_value(processed_mail.original_sender)
    message_id = sanitize_mailbox_value(processed_mail.message_id)

    @contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: sender_email,
      inbox: @inbox,
      contact_attributes: {
        name: sanitize_mailbox_value(identify_contact_name),
        email: sender_email,
        additional_attributes: { source_id: "email:#{message_id}" }
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
