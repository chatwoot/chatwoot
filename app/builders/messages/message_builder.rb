class Messages::MessageBuilder # rubocop:disable Metrics/ClassLength
  include ::FileTypeHelper
  attr_reader :message

  # rubocop:disable  Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/PerceivedComplexity
  def initialize(user, conversation, params) # rubocop:disable Metrics/MethodLength
    @params = params
    @private = params[:private] || false
    @conversation = conversation
    @user = user
    @message_type = params[:message_type] || 'outgoing'
    @attachments = params[:attachments]
    @url_attachments = params[:url_attachments]
    @automation_rule = content_attributes&.dig(:automation_rule_id)
    @comment_id = content_attributes&.dig(:comment_id)
    @is_dm_conversation_created = content_attributes&.dig(:is_dm_conversation_created)
    @ignore_automation_rules = params[:ignore_automation_rules]
    @disable_notifications = params[:disable_notifications]
    @disable_webhook_notifications = params[:disable_webhook_notifications]
    @parent_source_id = params[:parent_source_id]
    @reply_to_comment_id = content_attributes&.dig(:reply_to_comment_id)
    @should_prompt_resolution = content_attributes&.dig(:should_prompt_resolution)
    @skip_conversation_reopen = content_attributes&.dig(:skip_conversation_reopen)
    return unless params.instance_of?(ActionController::Parameters)

    @in_reply_to = content_attributes&.dig(:in_reply_to)
    @items = content_attributes&.dig(:items)

    check_parent_source_id
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity

  def perform
    return @message if duplicate_message

    @message = @conversation.messages.build(message_params)
    process_attachments
    process_url_attachments
    process_emails
    @message.save!
    assign_conversation_to_contact_owner

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

    return parse_json(content_attributes) if content_attributes.is_a?(String)
    return content_attributes if content_attributes.is_a?(Hash)

    {}
  end

  # Converts the given object to a hash.
  # If it's an instance of ActionController::Parameters, converts it to an unsafe hash.
  # Otherwise, returns the object as-is.
  def convert_to_hash(obj)
    return obj.to_unsafe_h if obj.instance_of?(ActionController::Parameters)

    obj
  end

  # Attempts to parse a string as JSON.
  # If successful, returns the parsed hash with symbolized names.
  # If unsuccessful, returns nil.
  def parse_json(content)
    JSON.parse(content, symbolize_names: true)
  rescue JSON::ParserError
    {}
  end

  def process_attachments
    return if @attachments.blank?

    @attachments.each do |uploaded_attachment|
      attachment = @message.attachments.build(
        account_id: @message.account_id,
        file: uploaded_attachment
      )

      attachment.file_type = if uploaded_attachment.is_a?(String)
                               file_type_by_signed_id(
                                 uploaded_attachment
                               )
                             else
                               file_type(uploaded_attachment&.content_type)
                             end
    end
  end

  def duplicate_message
    return false if @params[:source_id].blank?

    @message = Message.find_by(conversation_id: @conversation.id, source_id: @params[:source_id])
    @message.present?
  end

  def process_url_attachments
    return if @url_attachments.blank?

    @url_attachments.each do |url_attachment|
      @message.attachments.build(
        account_id: @message.account_id,
        external_url: url_attachment[:url],
        file_type: url_attachment[:type]
      )
    end
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

  def process_email_string(email_string)
    return [] if email_string.blank?

    email_string.gsub(/\s+/, '').split(',')
  end

  def validate_email_addresses(all_emails)
    all_emails&.each do |email|
      raise StandardError, 'Invalid email address' unless email.match?(URI::MailTo::EMAIL_REGEXP)
    end
  end

  def message_type
    if @conversation.inbox.channel_type != 'Channel::Api' && @message_type == 'incoming'
      raise StandardError, 'Incoming messages are only allowed in Api inboxes'
    end

    @message_type
  end

  def check_parent_source_id
    return if @parent_source_id.blank?

    @in_reply_to = Message.find_by(conversation_id: @conversation.id, source_id: @parent_source_id)&.id
    # @in_reply_to_external_id = @parent_source_id if @in_reply_to.present?
  end

  def sender
    message_type == 'outgoing' ? (message_sender || @user) : @conversation.contact
  end

  def external_created_at
    @params[:external_created_at].present? ? { external_created_at: @params[:external_created_at] } : {}
  end

  def comment_id
    @comment_id.present? ? { comment_id: @comment_id } : {}
  end

  def should_prompt_resolution
    @should_prompt_resolution.present? ? { should_prompt_resolution: @should_prompt_resolution } : {}
  end

  def skip_conversation_reopen
    @skip_conversation_reopen.present? ? { skip_conversation_reopen: @skip_conversation_reopen } : {}
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

  def template_params_stringified
    # rubocop:disable Layout/LineLength
    @params[:stringified_template_params].present? ? { additional_attributes: { template_params: JSON.parse(@params[:stringified_template_params]) } } : {}
    # rubocop:enable Layout/LineLength
  end

  def ignore_automation_rules
    @ignore_automation_rules.present? && @ignore_automation_rules == 'true' ? { additional_attributes: { ignore_automation_rules: true } } : {}
  end

  def disable_notifications
    @disable_notifications.present? && @disable_notifications == 'true' ? { additional_attributes: { disable_notifications: true } } : {}
  end

  def disable_webhook_notifications
    if @disable_webhook_notifications.present? && @disable_webhook_notifications == 'true'
      {
        additional_attributes: { disable_webhook_notifications: true }
      }
    else
      {}
    end
  end

  def message_sender
    return if @params[:sender_type] != 'AgentBot'

    AgentBot.where(account_id: [nil, @conversation.account.id]).find_by(id: @params[:sender_id])
  end

  # rubocop:disable Layout/LineLength
  # rubocop:disable Metrics/AbcSize,Lint/MissingCopEnableDirective
  def message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: message_type,
      content: @params[:content],
      private: @private,
      sender: sender,
      content_type: @params[:content_type],
      items: @items,
      in_reply_to: @in_reply_to,
      echo_id: @params[:echo_id],
      source_id: @params[:source_id],
      reply_to_comment_id: @reply_to_comment_id,
      is_dm_conversation_created: @is_dm_conversation_created
    }.merge(external_created_at).merge(automation_rule_id).merge(campaign_id).merge(template_params).merge(ignore_automation_rules).merge(disable_notifications).merge(disable_webhook_notifications).merge(template_params_stringified).merge(comment_id).merge(should_prompt_resolution).merge(skip_conversation_reopen)
  end
  # rubocop:enable Layout/LineLength

  # Auto-assign conversation to contact owner when customer replies
  def assign_conversation_to_contact_owner
    return unless @message.incoming? # Only for incoming messages
    return unless @conversation.assignee_id.nil? # Only if conversation is unassigned
    return unless @conversation.account.contact_assignment_enabled? # Feature check
    return if @conversation.contact.assignee_id.blank? # Contact must have owner

    # Auto-assign conversation to contact owner
    @conversation.update(assignee_id: @conversation.contact.assignee_id)

    Rails.logger.info "Conversation #{@conversation.id} auto-assigned to agent #{@conversation.contact.assignee_id} (contact owner)"
  end
end
