class AppleMessagesForBusiness::FormService
  include ApplicationHelper

  def initialize(channel:, destination_id:, form_config:)
    @channel = channel
    @destination_id = destination_id
    @form_config = form_config
  end

  def create_form_message
    validate_form_config!

    message_id = SecureRandom.uuid

    payload = build_apple_msp_payload(message_id)

    response = send_to_apple_gateway(payload, message_id)

    if response.success?
      { success: true, message_id: message_id, payload: payload }
    else
      { success: false, error: "HTTP #{response.code}: #{response.body}" }
    end
  rescue StandardError => e
    Rails.logger.error "Apple Messages form creation failed: #{e.message}"
    { success: false, error: e.message }
  end

  def self.process_form_response(channel:, payload:)
    # Handle form responses from Apple Messages
    form_data = payload.dig('message', 'interactiveData')
    return unless form_data

    conversation = find_conversation_by_source_id(channel, payload['sourceId'])
    return unless conversation

    # Extract form response data
    form_response = extract_form_response_data(form_data)

    # Create response message in Chatwoot
    create_form_response_message(conversation, form_response)

    # Trigger any configured automation or webhooks
    trigger_form_response_hooks(conversation, form_response)
  end

  private

  def validate_form_config!
    raise ArgumentError, 'Form title is required' unless @form_config['title'].present?

    raise ArgumentError, 'Form must have at least one page' unless @form_config['pages'].present? && @form_config['pages'].is_a?(Array)

    @form_config['pages'].each_with_index do |page, index|
      validate_form_page!(page, index)
    end
  end

  def validate_form_page!(page, index)
    raise ArgumentError, "Page #{index} must have a page_id" unless page['page_id'].present?

    raise ArgumentError, "Page #{index} must have at least one form item" unless page['items'].present? && page['items'].is_a?(Array)

    page['items'].each_with_index do |item, item_index|
      validate_form_item!(item, index, item_index)
    end
  end

  def validate_form_item!(item, page_index, item_index)
    required_fields = %w[item_id item_type]
    missing_fields = required_fields.select { |field| item[field].blank? }

    raise ArgumentError, "Page #{page_index}, Item #{item_index}: Missing required fields: #{missing_fields.join(', ')}" if missing_fields.any?

    raise ArgumentError, "Page #{page_index}, Item #{item_index}: Invalid item_type '#{item['item_type']}'" unless valid_item_type?(item['item_type'])

    validate_item_specific_requirements!(item, page_index, item_index)
  end

  def valid_item_type?(item_type)
    %w[
      text textArea singleSelect multiSelect
      dateTime toggle stepper picker
      richLink button email phone
    ].include?(item_type)
  end

  def validate_item_specific_requirements!(item, page_index, item_index)
    case item['item_type']
    when 'singleSelect', 'multiSelect'
      unless item['options'].present? && item['options'].is_a?(Array)
        raise ArgumentError, "Page #{page_index}, Item #{item_index}: Select items must have options"
      end
    when 'stepper'
      unless item['min_value'].present? && item['max_value'].present?
        raise ArgumentError, "Page #{page_index}, Item #{item_index}: Stepper must have min_value and max_value"
      end
    when 'picker'
      unless item['picker_type'].present? && %w[date time dateTime].include?(item['picker_type'])
        raise ArgumentError, "Page #{page_index}, Item #{item_index}: Picker must have valid picker_type (date, time, dateTime)"
      end
    end
  end

  def build_apple_msp_payload(message_id)
    {
      v: 1,
      id: message_id,
      sourceId: @channel.business_id,
      destinationId: @destination_id,
      type: 'interactive',
      interactiveData: build_form_data
    }
  end

  def build_form_data
    {
      bid: 'com.apple.messages.MSMessageExtensionBalloonPlugin:com.apple.messages.form:form',
      data: {
        version: @form_config['version'] || '1.0',
        requestIdentifier: SecureRandom.uuid,
        form: build_form_structure
      },
      useLiveLayout: @form_config['use_live_layout'] != false
    }
  end

  def build_form_structure
    {
      form_id: @form_config['form_id'] || SecureRandom.uuid,
      title: @form_config['title'],
      description: @form_config['description'],
      pages: @form_config['pages'].map { |page| build_form_page(page) },
      submit_button: @form_config['submit_button'] || { title: 'Submit' },
      cancel_button: @form_config['cancel_button'] || { title: 'Cancel' }
    }
  end

  def build_form_page(page_config)
    {
      page_id: page_config['page_id'],
      title: page_config['title'],
      description: page_config['description'],
      items: page_config['items'].map { |item| build_form_item(item) }
    }
  end

  def build_form_item(item_config)
    base_item = {
      item_id: item_config['item_id'],
      item_type: item_config['item_type'],
      title: item_config['title'],
      required: item_config['required'] || false
    }

    # Add optional fields
    base_item[:description] = item_config['description'] if item_config['description'].present?
    base_item[:placeholder] = item_config['placeholder'] if item_config['placeholder'].present?
    base_item[:default_value] = item_config['default_value'] if item_config['default_value'].present?

    # Add item-type-specific fields
    case item_config['item_type']
    when 'text', 'textArea', 'email', 'phone'
      add_text_item_fields(base_item, item_config)
    when 'singleSelect', 'multiSelect'
      add_select_item_fields(base_item, item_config)
    when 'dateTime'
      add_datetime_item_fields(base_item, item_config)
    when 'toggle'
      add_toggle_item_fields(base_item, item_config)
    when 'stepper'
      add_stepper_item_fields(base_item, item_config)
    when 'picker'
      add_picker_item_fields(base_item, item_config)
    when 'richLink'
      add_rich_link_item_fields(base_item, item_config)
    when 'button'
      add_button_item_fields(base_item, item_config)
    end

    base_item
  end

  def add_text_item_fields(base_item, item_config)
    base_item[:max_length] = item_config['max_length'] if item_config['max_length'].present?
    base_item[:keyboard_type] = item_config['keyboard_type'] if item_config['keyboard_type'].present?
    base_item[:text_content_type] = item_config['text_content_type'] if item_config['text_content_type'].present?
  end

  def add_select_item_fields(base_item, item_config)
    base_item[:options] = item_config['options'].map do |option|
      {
        value: option['value'],
        title: option['title'],
        description: option['description']
      }.compact
    end
  end

  def add_datetime_item_fields(base_item, item_config)
    base_item[:date_format] = item_config['date_format'] if item_config['date_format'].present?
    base_item[:min_date] = item_config['min_date'] if item_config['min_date'].present?
    base_item[:max_date] = item_config['max_date'] if item_config['max_date'].present?
  end

  def add_toggle_item_fields(base_item, item_config)
    base_item[:toggle_style] = item_config['toggle_style'] || 'switch'
  end

  def add_stepper_item_fields(base_item, item_config)
    base_item[:min_value] = item_config['min_value']
    base_item[:max_value] = item_config['max_value']
    base_item[:step] = item_config['step'] || 1
  end

  def add_picker_item_fields(base_item, item_config)
    base_item[:picker_type] = item_config['picker_type']
    base_item[:picker_options] = item_config['picker_options'] if item_config['picker_options'].present?
  end

  def add_rich_link_item_fields(base_item, item_config)
    base_item[:url] = item_config['url']
    base_item[:image_url] = item_config['image_url'] if item_config['image_url'].present?
  end

  def add_button_item_fields(base_item, item_config)
    base_item[:button_style] = item_config['button_style'] || 'primary'
    base_item[:action] = item_config['action']
  end

  def send_to_apple_gateway(payload, message_id)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@channel.generate_jwt_token}",
      'id' => message_id,
      'Source-Id' => @channel.business_id,
      'Destination-Id' => @destination_id
    }

    HTTParty.post(
      "#{AppleMessagesForBusiness::SendMessageService::AMB_SERVER}/message",
      body: payload.to_json,
      headers: headers,
      timeout: 30
    )
  end

  def self.find_conversation_by_source_id(channel, source_id)
    contact_inbox = ContactInbox.find_by(
      inbox: channel.inbox,
      source_id: source_id
    )

    contact_inbox&.conversations&.last
  end

  def self.extract_form_response_data(form_data)
    {
      form_id: form_data.dig('data', 'form', 'form_id'),
      responses: form_data.dig('data', 'form', 'responses') || {},
      completion_status: form_data.dig('data', 'completion_status') || 'completed',
      submitted_at: Time.current.iso8601,
      apple_message_id: form_data['requestIdentifier']
    }
  end

  def self.create_form_response_message(conversation, form_response)
    message = conversation.messages.create!(
      account: conversation.account,
      inbox: conversation.inbox,
      message_type: 'incoming',
      content: format_form_response_content(form_response),
      content_type: 'apple_form_response',
      content_attributes: {
        form_id: form_response[:form_id],
        responses: form_response[:responses],
        completion_status: form_response[:completion_status],
        submitted_at: form_response[:submitted_at],
        apple_message_id: form_response[:apple_message_id]
      },
      external_source_id: form_response[:apple_message_id],
      sender: conversation.contact
    )

    # Trigger conversation updated event
    Rails.application.event_store.publish(
      Events::MessageCreated.new(data: { message: message })
    )

    message
  end

  def self.format_form_response_content(form_response)
    return 'Form submitted (no responses)' if form_response[:responses].empty?

    content = "Form Response:\n"
    form_response[:responses].each do |field_id, value|
      field_name = field_id.humanize
      content += "#{field_name}: #{format_field_value(value)}\n"
    end

    content.strip
  end

  def self.format_field_value(value)
    case value
    when Array
      value.join(', ')
    when Hash
      value.to_s
    else
      value.to_s
    end
  end

  def self.trigger_form_response_hooks(conversation, form_response)
    # Trigger webhooks if enabled
    if conversation.account.feature_enabled?(:webhooks)
      WebhookJob.perform_later(
        conversation.account,
        :form_response_received,
        {
          conversation: conversation,
          form_response: form_response
        }
      )
    end

    # Trigger automation rules
    AutomationRuleJob.perform_later(
      conversation,
      :form_response_received,
      form_response
    )
  end
end
