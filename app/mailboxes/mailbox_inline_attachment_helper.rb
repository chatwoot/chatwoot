module MailboxInlineAttachmentHelper
  private

  def load_email_content
    @html_content = processed_mail.serialized_data[:html_content][:full]
    @text_content = processed_mail.serialized_data[:text_content][:reply]
  end

  def inline_attachment?(attachment)
    # Only process images as potential inline attachments
    return false unless mail_content.present? && attachment[:original].content_type.to_s.start_with?('image/')

    # Check if attachment is explicitly marked as inline
    return true if attachment[:original].inline?

    # For Outlook compatibility: if not marked as inline but has CID and is referenced in body
    cid = attachment[:original].cid
    cid.present? && body_references_cid?(cid)
  end

  def body_references_cid?(cid)
    # Check if CID is referenced in HTML content
    return false if @html_content.blank?

    cid_urls_for(cid).any? { |cid_url| @html_content.include?(cid_url) }
  end

  def upload_inline_image(mail_attachment)
    content_id = mail_attachment[:original].cid
    image_url = inline_image_url(mail_attachment[:blob]).to_s

    cid_urls_for(content_id).each do |cid_url|
      @html_content = @html_content.gsub(cid_url, image_url)
    end
  end

  def cid_urls_for(cid)
    # RFC 2392 cid URLs can contain URL-encoded Content-ID values.
    # Check both raw and encoded variants so clients using either form render inline images.
    encoded_cid = ERB::Util.url_encode(cid)
    lowercase_encoded_cid = encoded_cid.gsub(/%[0-9A-F]{2}/, &:downcase)

    ["cid:#{cid}", "cid:#{encoded_cid}", "cid:#{lowercase_encoded_cid}"].uniq
  end
end
