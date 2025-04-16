class Messages::MessageBuilder
  include ::FileTypeHelper
  attr_reader :message

  def initialize(user, conversation, params)
    @params = params
    @private = params[:private] || false
    @conversation = conversation
    @user = user
    @message_type = params[:message_type] || 'outgoing'
    @attachments = params[:attachments]
    @automation_rule = content_attributes&.dig(:automation_rule_id)
    return unless params.instance_of?(ActionController::Parameters)

    @in_reply_to = content_attributes&.dig(:in_reply_to)
    @items = content_attributes&.dig(:items)
  end

  def perform
    @message = @conversation.messages.build(message_params)
    process_attachments
    process_emails
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

    Rails.logger.info("Processing attachments in MessageBuilder: #{@attachments.inspect}")
    Rails.logger.info("Attachments class in MessageBuilder: #{@attachments.class}")

    @attachments.each do |uploaded_attachment|
      # Kiểm tra các trường hợp khác nhau của uploaded_attachment
      Rails.logger.info("Processing attachment in MessageBuilder: #{uploaded_attachment.inspect}")
      Rails.logger.info("Attachment class in MessageBuilder: #{uploaded_attachment.class}")

      if uploaded_attachment.is_a?(Hash)
        # Xử lý attachment với external_url (hash với key symbol)
        if uploaded_attachment[:external_url].present?
          Rails.logger.info("Building attachment with external_url (symbol): #{uploaded_attachment[:external_url]}")

          file_type_value = if uploaded_attachment[:file_type].is_a?(String)
                             uploaded_attachment[:file_type].to_sym
                           elsif uploaded_attachment[:file_type].is_a?(Symbol)
                             uploaded_attachment[:file_type]
                           else
                             :image
                           end

          attachment = @message.attachments.build(
            account_id: @message.account_id,
            external_url: uploaded_attachment[:external_url],
            file_type: file_type_value
          )

          Rails.logger.info("Built attachment with symbol keys: #{attachment.inspect}")
        # Xử lý attachment với external_url (hash với key string)
        elsif uploaded_attachment['external_url'].present?
          Rails.logger.info("Building attachment with external_url (string): #{uploaded_attachment['external_url']}")

          file_type_value = if uploaded_attachment['file_type'].is_a?(String)
                             uploaded_attachment['file_type'].to_sym
                           else
                             :image
                           end

          attachment = @message.attachments.build(
            account_id: @message.account_id,
            external_url: uploaded_attachment['external_url'],
            file_type: file_type_value
          )

          Rails.logger.info("Built attachment with string keys: #{attachment.inspect}")
        else
          # Xử lý attachment thông thường (file)
          Rails.logger.info("Building regular attachment from hash without external_url")

          attachment = @message.attachments.build(
            account_id: @message.account_id,
            file: uploaded_attachment
          )

          attachment.file_type = file_type(uploaded_attachment&.content_type) || :file
          Rails.logger.info("Built regular attachment from hash: #{attachment.inspect}")
        end
      elsif uploaded_attachment.is_a?(ActionController::Parameters)
        # Xử lý attachment với external_url từ ActionController::Parameters
        if uploaded_attachment[:external_url].present?
          Rails.logger.info("Building attachment with external_url from params: #{uploaded_attachment[:external_url]}")

          file_type_value = if uploaded_attachment[:file_type].present?
                             uploaded_attachment[:file_type].to_s.to_sym
                           else
                             :image
                           end

          attachment = @message.attachments.build(
            account_id: @message.account_id,
            external_url: uploaded_attachment[:external_url],
            file_type: file_type_value
          )

          Rails.logger.info("Built attachment from params: #{attachment.inspect}")
        else
          # Xử lý attachment thông thường (file)
          Rails.logger.info("Building regular attachment from params without external_url")

          attachment = @message.attachments.build(
            account_id: @message.account_id,
            file: uploaded_attachment
          )

          attachment.file_type = file_type(uploaded_attachment&.content_type) || :file
          Rails.logger.info("Built regular attachment from params: #{attachment.inspect}")
        end
      elsif uploaded_attachment.is_a?(String)
        # Xử lý attachment thông thường (signed_id)
        Rails.logger.info("Building regular attachment from string")

        # Kiểm tra xem có phải là URL không
        if uploaded_attachment.start_with?('http://', 'https://')
          Rails.logger.info("Detected URL in string: #{uploaded_attachment}")
          attachment = @message.attachments.build(
            account_id: @message.account_id,
            external_url: uploaded_attachment,
            file_type: :image
          )
        else
          attachment = @message.attachments.build(
            account_id: @message.account_id,
            file: uploaded_attachment
          )

          attachment.file_type = file_type_by_signed_id(uploaded_attachment)
        end

        Rails.logger.info("Built regular attachment from string: #{attachment.inspect}")
      else
        # Xử lý attachment thông thường (file)
        Rails.logger.info("Building regular attachment from unknown type: #{uploaded_attachment.class}")

        attachment = @message.attachments.build(
          account_id: @message.account_id,
          file: uploaded_attachment
        )

        attachment.file_type = file_type(uploaded_attachment&.content_type) || :file
        Rails.logger.info("Built regular attachment from unknown type: #{attachment.inspect}")
      end
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

  def message_sender
    return if @params[:sender_type] != 'AgentBot'

    AgentBot.where(account_id: [nil, @conversation.account.id]).find_by(id: @params[:sender_id])
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
      items: @items,
      in_reply_to: @in_reply_to,
      echo_id: @params[:echo_id],
      source_id: @params[:source_id]
    }.merge(external_created_at).merge(automation_rule_id).merge(campaign_id).merge(template_params)
  end
end
