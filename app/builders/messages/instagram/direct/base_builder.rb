class Messages::Instagram::Direct::BaseBuilder
  include ::FileTypeHelper
  include HTTParty

  base_uri "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}"

  def process_attachment(attachment)
    # This check handles very rare case if there are multiple files to attach with only one unsupported file
    return if unsupported_file_type?(attachment['type'])

    attachment_obj = @message.attachments.new(attachment_params(attachment).except(:remote_file_url))
    attachment_obj.save!
    attach_file(attachment_obj, attachment_params(attachment)[:remote_file_url]) if attachment_params(attachment)[:remote_file_url]
    fetch_story_link(attachment_obj) if attachment_obj.file_type == 'story_mention'
    update_attachment_file_type(attachment_obj)
  end

  def attach_file(attachment, file_url)
    attachment_file = Down.download(
      file_url
    )
    attachment.file.attach(
      io: attachment_file,
      filename: attachment_file.original_filename,
      content_type: attachment_file.content_type
    )
  end

  def attachment_params(attachment)
    file_type = attachment['type'].to_sym
    params = { file_type: file_type, account_id: @message.account_id }

    if [:image, :file, :audio, :video, :share, :story_mention, :ig_reel].include? file_type
      params.merge!(file_type_params(attachment))
    elsif file_type == :location
      params.merge!(location_params(attachment))
    elsif file_type == :fallback
      params.merge!(fallback_params(attachment))
    end

    params
  end

  def file_type_params(attachment)
    {
      external_url: attachment['payload']['url'],
      remote_file_url: attachment['payload']['url']
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
    Rails.logger.info("Instagram story object: #{result}")
    return if result.blank?

    story_id = result['story']['mention']['id']
    story_sender = result['from']['username']
    message.content_attributes[:story_sender] = story_sender
    message.content_attributes[:story_id] = story_id
    message.content_attributes[:image_type] = 'story_mention'
    message.content = I18n.t('conversations.messages.instagram_story_content', story_sender: story_sender)
    message.save!
  end

  def get_story_object_from_source_id(source_id)
    Rails.logger.info("Instagram source id: #{source_id}")

    url = "#{self.class.base_uri}/#{source_id}?fields=story,from&access_token=#{@inbox.channel.access_token}"
    response = HTTParty.get(url)

    Rails.logger.info("Instagram Story Response: #{response.body}")

    return JSON.parse(response.body).with_indifferent_access if response.success?

    handle_error_response(response)
    {}
  rescue StandardError => e
    handle_standard_error(e)
    {}
  end

  private

  def unsupported_file_type?(attachment_type)
    [:template, :unsupported_type].include? attachment_type.to_sym
  end

  def handle_error_response(response)
    Rails.logger.error("Instagram API Error: #{response.code} - #{response.body}")
    return unless response.code == 404

    @message.attachments.destroy_all
    @message.update(content: I18n.t('conversations.messages.instagram_deleted_story_content'))
  end

  def handle_standard_error(error)
    if error.response&.unauthorized?
      @inbox.channel.authorization_error!
      raise
    end
    Rails.logger.error("Instagram Story Error: #{error.message}")
    ChatwootExceptionTracker.new(error, account: @inbox.account).capture_exception
  end
end
