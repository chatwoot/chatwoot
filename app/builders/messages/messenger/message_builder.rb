class Messages::Messenger::MessageBuilder
  include ::FileTypeHelper
  REMOTE_FILE_ALLOWED_CONTENT_TYPE_PREFIXES = %w[image/ video/ audio/].freeze

  def process_attachment(attachment)
    # This check handles very rare case if there are multiple files to attach with only one unsupported file
    return if unsupported_file_type?(attachment['type'])

    attachment_obj = persist_attachment(attachment)
    return unless attachment_obj

    fetch_story_link(attachment_obj) if attachment_obj.file_type == 'story_mention'
    fetch_ig_story_link(attachment_obj) if attachment_obj.file_type == 'ig_story'
    fetch_ig_post_link(attachment_obj) if attachment_obj.file_type == 'ig_post'
    update_attachment_file_type(attachment_obj)
  end

  def attach_file(attachment, file_url)
    SafeFetch.fetch(file_url, **remote_attachment_fetch_options) do |attachment_file|
      attachment.file.attach(
        io: attachment_file.tempfile,
        filename: attachment_file.original_filename,
        content_type: attachment_file.content_type
      )
    end
    true
  rescue SafeFetch::Error => e
    Rails.logger.info "Error downloading Messenger attachment from #{file_url}: #{e.message}: Skipping"
    false
  end

  def attachment_params(attachment)
    file_type = normalize_file_type(attachment['type'])
    params = { file_type: file_type, account_id: @message.account_id }

    if [:image, :file, :audio, :video, :share, :story_mention, :ig_reel, :ig_post, :ig_story].include? file_type
      params.merge!(file_type_params(attachment))
    elsif file_type == :location
      params.merge!(location_params(attachment))
    elsif file_type == :fallback
      params.merge!(fallback_params(attachment))
    end

    params
  end

  def file_type_params(attachment)
    # Handle different URL field names for different attachment types
    url = case attachment['type'].to_sym
          when :ig_story
            attachment['payload']['story_media_url']
          else
            attachment['payload']['url']
          end

    {
      external_url: url,
      remote_file_url: url
    }
  end

  def update_attachment_file_type(attachment)
    return if @message.reload.attachments.blank?
    return unless attachment.file_type == 'share' || attachment.file_type == 'story_mention'

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

  def fetch_ig_story_link(attachment)
    message = attachment.message
    # For ig_story, we don't have the same API call as story_mention, so we'll set it up similarly but with generic content
    message.content_attributes[:image_type] = 'ig_story'
    message.content = I18n.t('conversations.messages.instagram_shared_story_content')
    message.save!
  end

  def fetch_ig_post_link(attachment)
    message = attachment.message
    message.content_attributes[:image_type] = 'ig_post'
    message.content = I18n.t('conversations.messages.instagram_shared_post_content')
    message.save!
  end

  # This is a placeholder method to be overridden by child classes
  def get_story_object_from_source_id(_source_id)
    {}
  end

  private

  def persist_attachment(attachment)
    params = attachment_params(attachment)
    attachment_obj = @message.attachments.new(params.except(:remote_file_url))

    return save_facebook_reel_attachment(attachment, attachment_obj) if facebook_reel?(attachment)
    return save_remote_file_attachment(attachment_obj, params[:remote_file_url]) if params[:remote_file_url].present?

    attachment_obj.save!
    attachment_obj
  end

  def save_facebook_reel_attachment(attachment, attachment_obj)
    attachment_obj.save!
    update_facebook_reel_content(attachment)
    attachment_obj
  end

  def save_remote_file_attachment(attachment_obj, remote_file_url)
    return unless attach_file(attachment_obj, remote_file_url)

    attachment_obj.save!
    attachment_obj
  end

  def remote_attachment_fetch_options
    {
      allowed_content_type_prefixes: REMOTE_FILE_ALLOWED_CONTENT_TYPE_PREFIXES,
      allowed_content_types: Attachment::ACCEPTABLE_FILE_TYPES
    }
  end

  # Facebook may send attachment types that don't directly match our file_type enum.
  # Map known aliases to their canonical enum values.
  FACEBOOK_FILE_TYPE_MAP = { reel: :ig_reel }.freeze

  def normalize_file_type(type)
    sym = type.to_sym
    FACEBOOK_FILE_TYPE_MAP.fetch(sym, sym)
  end

  # Facebook sends reel URLs as webpage links (facebook.com/reel/...) rather than
  # direct video URLs. Downloading these yields HTML, not video content.
  def facebook_reel?(attachment)
    attachment['type'].to_sym == :reel
  end

  def update_facebook_reel_content(attachment)
    url = attachment.dig('payload', 'url')
    return if url.blank?

    @message.update!(content: url) if @message.content.blank?
  end

  def unsupported_file_type?(attachment_type)
    [:template, :unsupported_type, :ephemeral].include? attachment_type.to_sym
  end
end
