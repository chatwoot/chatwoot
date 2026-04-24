module Messages::Instagram::StoryReplyAttachmentHandling
  private

  def create_story_reply_attachment(story_url)
    return if story_url.blank?

    attach_story_reply_file(build_story_reply_attachment(story_url), story_url)
    update_story_reply_message
  end

  def build_story_reply_attachment(story_url)
    @message.attachments.new(
      file_type: :ig_story,
      account_id: @message.account_id,
      external_url: story_url
    )
  end

  def attach_story_reply_file(attachment, story_url)
    SafeFetch.fetch(story_url, **remote_attachment_fetch_options) do |attachment_file|
      persist_story_reply_attachment(attachment, attachment_file)
    end
  rescue SafeFetch::Error => e
    Rails.logger.info "Error downloading Messenger attachment from #{story_url}: #{e.message}: Skipping"
    discard_story_reply_attachment(attachment)
  rescue StandardError => e
    Rails.logger.warn "Failed to download Instagram story attachment: #{e.message}"
    discard_story_reply_attachment(attachment)
  end

  def persist_story_reply_attachment(attachment, attachment_file)
    attachment.file.attach(
      io: attachment_file.tempfile,
      filename: attachment_file.original_filename,
      content_type: attachment_file.content_type
    )
    attachment.save!
  end

  def discard_story_reply_attachment(attachment)
    return attachment.destroy if attachment.persisted?

    @message.attachments.proxy_association.target.delete(attachment)
  end

  def update_story_reply_message
    @message.content_attributes[:image_type] = 'ig_story_reply'
    @message.save!
  end
end
