class Messages::MessageBuilder # rubocop:disable Metrics/ClassLength
  include ::FileTypeHelper
  include ::EmailHelper
  include ::DataHelper

  attr_reader :message

  def initialize(user, conversation, params) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    @params = params
    @private = params[:private] || false
    @conversation = conversation
    @user = user
    @account = conversation.account
    @message_type = params[:message_type] || 'outgoing'
    @attachments = params[:attachments]
    @is_recorded_audio = params[:is_recorded_audio]
    @transcode_audio = params[:transcode_audio]
    @attachments_metadata = normalize_attachments_metadata(params[:attachments_metadata])
    @automation_rule = content_attributes&.dig(:automation_rule_id)
    return unless params.instance_of?(ActionController::Parameters)

    @in_reply_to = content_attributes&.dig(:in_reply_to)
    @is_reaction = content_attributes&.dig(:is_reaction)
    @items = content_attributes&.dig(:items)
    @zapi_args = content_attributes&.dig(:zapi_args)
  end

  def perform
    @message = @conversation.messages.build(message_params)
    process_attachments
    process_emails
    # When the message has no quoted content, it will just be rendered as a regular message
    # The frontend is equipped to handle this case
    process_email_content
    @message.save!
    @message
  end

  private

  # Extracts content attributes from the given params.
  # - Converts ActionController::Parameters to a regular hash if needed.
  # - Attempts to parse a JSON string if content is a string.
  # - Returns an empty hash if content is not present, if there's a parsing error, or if it's an unexpected type.
  def content_attributes
    params = convert_to_hash(@params)
    content_attributes = params.fetch(:content_attributes, {})

    return safe_parse_json(content_attributes) if content_attributes.is_a?(String)
    return content_attributes if content_attributes.is_a?(Hash)

    {}
  end

  def process_attachments
    return if @attachments.blank?

    @attachments.each do |uploaded_attachment|
      attachment = @message.attachments.build(
        account_id: @message.account_id,
        file: uploaded_attachment
      )
      attachment.meta = process_metadata(uploaded_attachment)
      attachment.file_type = if uploaded_attachment.is_a?(String)
                               file_type_by_signed_id(
                                 uploaded_attachment
                               )
                             else
                               file_type(uploaded_attachment&.content_type)
                             end
      transcode_attachment(attachment, file_like_source(uploaded_attachment)) if should_transcode?(attachment)
    end
  end

  def process_metadata(attachment)
    meta = {}
    meta.merge!(recorded_audio_metadata(attachment) || {})
    meta.merge!(custom_attachment_metadata(attachment) || {})
    meta.presence
  end

  def recorded_audio_metadata(attachment) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    # NOTE: `is_recorded_audio` can be either a boolean, the string "true", or an array of file names.
    return unless @is_recorded_audio
    return { is_recorded_audio: true } if @is_recorded_audio == true || @is_recorded_audio == 'true'

    return { is_recorded_audio: true } if @is_recorded_audio.is_a?(Array) && attachment.original_filename.in?(@is_recorded_audio)

    # FIXME: Remove backwards compatibility with old format.
    if @is_recorded_audio.is_a?(String)
      parsed = JSON.parse(@is_recorded_audio)
      { is_recorded_audio: true } if parsed.is_a?(Array) && attachment.original_filename.in?(parsed)
    end
  rescue JSON::ParserError
    nil
  end

  def custom_attachment_metadata(attachment)
    return unless @attachments_metadata.is_a?(Hash)

    filename = attachment.respond_to?(:original_filename) ? attachment.original_filename : nil
    return unless filename

    metadata = @attachments_metadata[filename]
    metadata.to_h if metadata.present?
  end

  def normalize_attachments_metadata(metadata)
    return if metadata.blank?

    metadata = metadata.to_unsafe_h if metadata.respond_to?(:to_unsafe_h)
    metadata.deep_stringify_keys
  end

  def should_transcode?(attachment)
    @transcode_audio.present? && attachment.file_type == 'audio'
  end

  # Returns the uploaded file only when it's a real file-like object (ActionDispatch::Http::UploadedFile,
  # Tempfile, etc.). Direct-upload signed-ID Strings are not usable as source files for transcoding;
  # TranscodeService falls back to downloading from the blob in that case.
  def file_like_source(uploaded_attachment)
    return uploaded_attachment if uploaded_attachment.respond_to?(:path) || uploaded_attachment.respond_to?(:tempfile)
  end

  def transcode_attachment(attachment, uploaded_file = nil)
    Audio::TranscodeService.new(attachment, @transcode_audio, source_file: uploaded_file).perform
    attachment.meta ||= {}
    attachment.meta['is_recorded_audio'] = true
  rescue CustomExceptions::Audio::UnsupportedFormatError, CustomExceptions::Audio::TranscodingError => e
    Rails.logger.error("Audio transcoding failed, keeping original attachment: #{e.message}")
    attachment.meta ||= {}
    attachment.meta['audio_transcoding_failed'] = true
  end

  def process_emails
    return unless @conversation.inbox&.inbox_type == 'Email'

    cc_emails = process_email_string(@params[:cc_emails])
    bcc_emails = process_email_string(@params[:bcc_emails])
    to_emails = process_email_string(@params[:to_emails])

    all_email_addresses = cc_emails + bcc_emails + to_emails
    validate_email_addresses(all_email_addresses)

    @message.content_attributes[:cc_emails] = cc_emails
    @message.content_attributes[:bcc_emails] = bcc_emails
    @message.content_attributes[:to_emails] = to_emails
  end

  def process_email_content
    return unless should_process_email_content?

    @message.content_attributes ||= {}
    email_attributes = build_email_attributes
    @message.content_attributes[:email] = email_attributes
  end

  def process_email_string(email_string)
    return [] if email_string.blank?

    email_string.gsub(/\s+/, '').split(',')
  end

  def message_type
    if @conversation.inbox.channel_type != 'Channel::Api' && @message_type == 'incoming'
      raise StandardError, 'Incoming messages are only allowed in Api inboxes'
    end

    @message_type
  end

  def sender
    message_type == 'outgoing' ? (message_sender || @user) : @conversation.contact
  end

  def external_created_at
    @params[:external_created_at].present? ? { external_created_at: @params[:external_created_at] } : {}
  end

  def automation_rule_id
    @automation_rule.present? ? { content_attributes: { automation_rule_id: @automation_rule } } : {}
  end

  def campaign_id
    @params[:campaign_id].present? ? { additional_attributes: { campaign_id: @params[:campaign_id] } } : {}
  end

  def template_params
    @params[:template_params].present? ? { additional_attributes: { template_params: JSON.parse(@params[:template_params].to_json) } } : {}
  end

  def scheduled_message_metadata
    return {} if @params[:scheduled_message].blank?

    sm = @params[:scheduled_message]
    scheduled_by = { 'id' => sm.author_id, 'type' => sm.author_type }
    scheduled_by['name'] = sm.author.name if sm.author.respond_to?(:name)

    {
      additional_attributes: {
        scheduled_message_id: sm.id,
        scheduled_by: scheduled_by,
        scheduled_at: sm.updated_at.to_i
      }
    }
  end

  def message_sender
    return if @params[:sender_type] != 'AgentBot'

    AgentBot.where(account_id: [nil, @conversation.account.id]).find_by(id: @params[:sender_id])
  end

  def zapi_args
    @zapi_args.present? ? { zapi_args: @zapi_args } : {}
  end

  def message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: message_type,
      content: @params[:content],
      private: @private,
      sender: sender,
      content_type: @params[:content_type],
      content_attributes: content_attributes.presence,
      items: @items,
      in_reply_to: @in_reply_to,
      is_reaction: @is_reaction,
      echo_id: @params[:echo_id],
      source_id: @params[:source_id]
    }.merge(external_created_at).merge(automation_rule_id).merge(campaign_id)
      .deep_merge(template_params).merge(zapi_args).deep_merge(scheduled_message_metadata)
  end

  def email_inbox?
    @conversation.inbox&.inbox_type == 'Email'
  end

  def should_process_email_content?
    email_inbox? && !@private && @message.content.present?
  end

  def build_email_attributes
    email_attributes = ensure_indifferent_access(@message.content_attributes[:email] || {})
    normalized_content = normalize_email_body(@message.content)

    # Process liquid templates in normalized content with code block protection
    processed_content = process_liquid_in_email_body(normalized_content)

    # Use custom HTML content if provided, otherwise generate from message content
    email_attributes[:html_content] = if custom_email_content_provided?
                                        build_custom_html_content
                                      else
                                        build_html_content(processed_content)
                                      end

    email_attributes[:text_content] = build_text_content(processed_content)
    email_attributes
  end

  def build_html_content(normalized_content)
    html_content = ensure_indifferent_access(@message.content_attributes.dig(:email, :html_content) || {})
    rendered_html = render_email_html(normalized_content)
    html_content[:full] = rendered_html
    html_content[:reply] = rendered_html
    html_content
  end

  def build_text_content(normalized_content)
    text_content = ensure_indifferent_access(@message.content_attributes.dig(:email, :text_content) || {})
    text_content[:full] = normalized_content
    text_content[:reply] = normalized_content
    text_content
  end

  def custom_email_content_provided?
    @params[:email_html_content].present?
  end

  def build_custom_html_content
    html_content = ensure_indifferent_access(@message.content_attributes.dig(:email, :html_content) || {})

    html_content[:full] = @params[:email_html_content]
    html_content[:reply] = @params[:email_html_content]

    html_content
  end

  # Liquid processing methods for email content
  def process_liquid_in_email_body(content)
    return content if content.blank?
    return content unless should_process_liquid?

    # Protect code blocks from liquid processing
    modified_content = modified_liquid_content(content)
    template = Liquid::Template.parse(modified_content)
    template.render(drops_with_sender)
  rescue Liquid::Error
    content
  end

  def should_process_liquid?
    @message_type == 'outgoing' || @message_type == 'template'
  end

  def drops_with_sender
    message_drops(@conversation).merge({
                                         'agent' => UserDrop.new(sender)
                                       })
  end
end

Messages::MessageBuilder.prepend_mod_with('Messages::MessageBuilder')
