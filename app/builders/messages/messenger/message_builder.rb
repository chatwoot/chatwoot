class Messages::Messenger::MessageBuilder
  include ::FileTypeHelper

  def process_attachment(attachment)
    # This check handles very rare case if there are multiple files to attach with only one usupported file
    return if unsupported_file_type?(attachment['type'])

    attachment_obj = @message.attachments.new(attachment_params(attachment).except(:remote_file_url))
    attachment_obj.save!
    attach_file(attachment_obj, attachment_params(attachment)[:remote_file_url]) if attachment_params(attachment)[:remote_file_url]
    fetch_story_link(attachment_obj) if attachment_obj.file_type == 'story_mention'
    fetch_ig_post_link(attachment_obj) if attachment_obj.file_type == 'ig_post'
    update_attachment_file_type(attachment_obj)
  end

  def attach_file(attachment, file_url)
    attachment_file = Down.download(file_url)
    attachment.file.attach(
      io: attachment_file,
      filename: attachment_file.original_filename,
      content_type: attachment_file.content_type
    )
  rescue StandardError => e
    Rails.logger.error "Failed to attach file: #{e.message}"
  end

  def attachment_params(attachment)
    original_type = attachment['type'].to_s
    # Normalize unsupported/alternate types
    # Keep ig_story as is so we can treat highlight shares distinctly
    normalized_type = original_type.to_sym

    params = { file_type: normalized_type, account_id: @message.account_id }

    if [:image, :file, :audio, :video, :share, :story_mention, :ig_reel, :ig_post, :ig_story].include? normalized_type
      params.merge!(file_type_params(attachment))
    elsif normalized_type == :location
      params.merge!(location_params(attachment))
    elsif normalized_type == :fallback
      params.merge!(fallback_params(attachment))
    end

    params
  end

  def file_type_params(attachment)
    # Some Instagram payloads use story_media_url (eg: ig_story). Prefer it when present.
    url = attachment.dig('payload', 'story_media_url') || attachment.dig('payload', 'url')
    {
      external_url: url,
      remote_file_url: url
    }
  end

  def update_attachment_file_type(attachment)
    return if @message.reload.attachments.blank?
    return unless attachment.file_type == 'share' || attachment.file_type == 'story_mention' || attachment.file_type == 'ig_story'

    attachment.file_type = file_type(attachment.file&.content_type)
    attachment.save!
  end

  def fetch_story_link(attachment)
    message = attachment.message
    result = get_story_object_from_source_id(message.source_id)

    return if result.blank?

    story_id = result['story']['mention']['id']
    story_sender = result['from']['username']
    message.content_attributes[:story_sender] = story_sender
    message.content_attributes[:story_id] = story_id
    message.content_attributes[:image_type] = 'story_mention'
    message.content = I18n.t('conversations.messages.instagram_story_content', story_sender: story_sender)
    message.save!
  end

  def fetch_ig_post_link(attachment)
    message = attachment.message
    message.content_attributes[:image_type] = 'ig_post'
    message.content = I18n.t('conversations.messages.instagram_shared_post_content')
    message.save!
  end

  def get_story_object_from_source_id(source_id)
    k = Koala::Facebook::API.new(@inbox.channel.page_access_token) if @inbox.facebook?
    k.get_object(source_id, fields: %w[story from]) || {}
  rescue Koala::Facebook::AuthenticationError
    @inbox.channel.authorization_error!
    raise
  rescue Koala::Facebook::ClientError => e
    # The exception occurs when we are trying fetch the deleted story or blocked story.
    @message.attachments.destroy_all
    @message.update(content: I18n.t('conversations.messages.instagram_deleted_story_content'))
    @message.attachments.destroy_all
    Rails.logger.error e
    {}
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    {}
  end

  private

  def unsupported_file_type?(attachment_type)
    [:template, :unsupported_type].include? attachment_type.to_sym
  end
end
