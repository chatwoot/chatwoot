# frozen_string_literal: true

class Instagram::RichMessageService < Instagram::BaseSendService
  pattr_initialize [:message!, :rich_payload!]

  # Override perform method to add validation logging
  def perform
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] === STARTING PERFORM ==="
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Message ID: #{message.id}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Message type: #{message.message_type}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Message outgoing?: #{message.outgoing?}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Message template?: #{message.template?}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Message private?: #{message.private?}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Message source_id: #{message.source_id}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Channel class: #{channel.class}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Expected channel class: #{channel_class}"
    
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] About to call validate_target_channel"
    validate_target_channel
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] validate_target_channel passed"
    
    unless outgoing_message?
      Rails.logger.warn "[SOCIALWISE-INSTAGRAM-RICH] Returning early: not outgoing_message"
      return
    end
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] outgoing_message? check passed"
    
    if invalid_message?
      Rails.logger.warn "[SOCIALWISE-INSTAGRAM-RICH] Returning early: invalid_message"
      return
    end
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] invalid_message? check passed"

    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] About to call perform_reply"
    perform_reply
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] === PERFORM COMPLETED ==="
  end

  private

  def channel_class
    Channel::Instagram
  end

  # Override perform_reply to handle rich message content instead of regular content
  def perform_reply
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] === STARTING RICH MESSAGE SEND ==="
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Message ID: #{message.id}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Message class: #{message.class}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Rich payload: #{rich_payload.inspect}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Rich payload class: #{rich_payload.class}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Channel: #{channel.class}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Contact: #{contact.class}"

    # Mirror rich payload to dashboard before sending to Instagram API
    mirror_rich_payload_to_dashboard

    # Send rich message content
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] About to call send_rich_message"
    send_rich_message
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] send_rich_message completed"
    
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] === RICH MESSAGE SEND COMPLETED ==="
  rescue StandardError => e
    Rails.logger.error "[SOCIALWISE-INSTAGRAM-RICH] Rich message send failed: #{e.class}: #{e.message}"
    Rails.logger.error "[SOCIALWISE-INSTAGRAM-RICH] Backtrace: #{e.backtrace.join('\n')}"
    handle_error(e)
  end

  # Send rich message using the rich_payload
  def send_rich_message
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] === STARTING send_rich_message ==="
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Sending rich message with payload: #{rich_payload.inspect}"
    
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] About to call rich_message_params"
    rich_message_content = rich_message_params
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Rich message params generated: #{rich_message_content.inspect}"
    
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] About to call send_message with content"
    result = send_message(rich_message_content)
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] send_message returned: #{result.inspect}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] === COMPLETED send_rich_message ==="
    result
  end

  # Deliver a rich message with the given payload
  # Uses the same Instagram API endpoint as regular messages
  # https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/messaging-api
  def send_message(message_content)
    api_call_start_time = Time.current
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] === STARTING INSTAGRAM API CALL ==="
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] API call started at: #{api_call_start_time.iso8601}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Message content size: #{message_content.to_json.length} bytes"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Calling Instagram API with content: #{message_content.inspect}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] JSON payload: #{message_content.to_json}"
    
    access_token = channel.access_token
    query = { access_token: access_token }
    instagram_id = channel.instagram_id.presence || 'me'
    api_endpoint = "https://graph.instagram.com/v22.0/#{instagram_id}/messages"

    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] API endpoint: #{api_endpoint}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Instagram ID: #{instagram_id}, Access token present: #{access_token.present?}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Access token length: #{access_token&.length || 0} characters"

    response = HTTParty.post(
      api_endpoint,
      body: message_content.to_json,
      headers: { 'Content-Type' => 'application/json' },
      query: query
    )

    api_call_end_time = Time.current
    api_call_duration = ((api_call_end_time - api_call_start_time) * 1000).round(2)
    
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] === INSTAGRAM API CALL COMPLETED ==="
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] API call completed at: #{api_call_end_time.iso8601}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] API call duration: #{api_call_duration}ms"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Response status: #{response.code}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Response headers: #{response.headers.inspect}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Response body: #{response.body}"
    
    # Performance warnings for API calls
    if api_call_duration > 10000
      Rails.logger.warn "[SOCIALWISE-INSTAGRAM-RICH] PERFORMANCE WARNING: Instagram API call took #{api_call_duration}ms (>10s)"
    elsif api_call_duration > 5000
      Rails.logger.warn "[SOCIALWISE-INSTAGRAM-RICH] PERFORMANCE NOTICE: Instagram API call took #{api_call_duration}ms (>5s)"
    end
    
    process_response(response, message_content)
  end

  # Build Instagram API compatible message structure for rich messages
  def rich_message_params
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Building rich message params from payload: #{rich_payload.inspect}"
    
    params = {
      "recipient" => { "id" => contact.get_source_id(inbox.id) },
      "message" => build_message_content
    }

    # Add messaging_type for Quick Replies (required by Instagram API)
    unless template_format?
      params["messaging_type"] = "RESPONSE"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Added messaging_type: RESPONSE for Quick Replies"
    end

    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Base params before human agent tag: #{params.inspect}"
    
    # Apply human agent tag if needed
    final_params = merge_human_agent_tag(params)
    
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Final params after human agent tag: #{final_params.inspect}"
    
    final_params
  end

  # Build the message content based on rich_payload format
  def build_message_content
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Building message content for payload: #{rich_payload.inspect}"
    
    if template_format?
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Building template format message"
      build_template_message
    else
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Building quick replies format message"
      build_quick_replies_message
    end
  end

  # Check if the payload is for template format (Generic or Button Template)
  def template_format?
    template_types = %w[generic button]
    is_template = template_types.include?(rich_payload['template_type'])
    
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Template format check: #{is_template} (template_type: #{rich_payload['template_type']})"
    
    is_template
  end

  # Build template message (Generic Template or Button Template)
  def build_template_message
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Building template message for type: #{rich_payload['template_type']}"
    
    case rich_payload['template_type']
    when 'generic'
      build_generic_template
    when 'button'
      build_button_template
    else
      Rails.logger.error "[SOCIALWISE-INSTAGRAM-RICH] Unknown template type: #{rich_payload['template_type']}"
      raise ArgumentError, "Unknown template type: #{rich_payload['template_type']}"
    end
  end

  # Build Generic Template message structure
  def build_generic_template
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Building Generic Template with #{rich_payload['elements']&.length} elements"
    
    {
      "attachment" => {
        "type" => "template",
        "payload" => {
          "template_type" => "generic",
          "elements" => build_generic_elements
        }
      }
    }
  end

  # Build Button Template message structure
  def build_button_template
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Building Button Template with text: #{rich_payload['text']}"
    
    {
      "attachment" => {
        "type" => "template",
        "payload" => {
          "template_type" => "button",
          "text" => rich_payload['text'],
          "buttons" => build_buttons(rich_payload['buttons'])
        }
      }
    }
  end

  # Build Quick Replies message structure
  def build_quick_replies_message
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Building Quick Replies with #{rich_payload['quick_replies']&.length} options"
    
    {
      "text" => rich_payload['text'],
      "quick_replies" => build_quick_replies(rich_payload['quick_replies'])
    }
  end

  # Build elements for Generic Template
  def build_generic_elements
    elements = rich_payload['elements'].map.with_index do |element, index|
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Building element #{index}: #{element.inspect}"
      
      # Use strings instead of symbols for Instagram API compatibility
      element_data = {
        "title" => element['title']
      }
      
      # Add optional fields
      element_data["subtitle"] = element['subtitle'] if element['subtitle'].present?
      element_data["image_url"] = element['image_url'] if element['image_url'].present?
      element_data["buttons"] = build_buttons(element['buttons']) if element['buttons'].present?
      
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Built element #{index}: #{element_data.inspect}"
      element_data
    end
    
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Built #{elements.length} elements for Generic Template"
    elements
  end

  # Build buttons array for templates
  def build_buttons(buttons_data)
    return [] unless buttons_data.is_a?(Array)
    
    buttons = buttons_data.map.with_index do |button, index|
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Building button #{index}: #{button.inspect}"
      
      # Use strings instead of symbols for Instagram API compatibility
      button_data = {
        "type" => button['type'],
        "title" => button['title']
      }
      
      case button['type']
      when 'postback'
        button_data["payload"] = button['payload']
      when 'web_url'
        button_data["url"] = button['url']
      end
      
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Built button #{index}: #{button_data.inspect}"
      button_data
    end
    
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Built #{buttons.length} buttons"
    buttons
  end

  # Build quick replies array
  def build_quick_replies(quick_replies_data)
    return [] unless quick_replies_data.is_a?(Array)
    
    quick_replies = quick_replies_data.map.with_index do |quick_reply, index|
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Building quick reply #{index}: #{quick_reply.inspect}"
      
      # Use strings instead of symbols for Instagram API compatibility
      quick_reply_data = {
        "content_type" => quick_reply['content_type'],
        "title" => quick_reply['title'],
        "payload" => quick_reply['payload']
      }
      
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Built quick reply #{index}: #{quick_reply_data.inspect}"
      quick_reply_data
    end
    
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Built #{quick_replies.length} quick replies"
    quick_replies
  end

  # Apply human agent tag for Instagram messaging
  def merge_human_agent_tag(params)
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Applying human agent tag to params"
    
    global_config = GlobalConfig.get('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')

    unless global_config['ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT']
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Human agent tag disabled, returning params as-is"
      return params
    end

    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Human agent tag enabled, adding MESSAGE_TAG and HUMAN_AGENT"
    
    params["messaging_type"] = "MESSAGE_TAG"
    params["tag"] = "HUMAN_AGENT"
    
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Params after human agent tag: #{params.inspect}"
    params
  end

  # Mirror rich payload to dashboard for visualization
  def mirror_rich_payload_to_dashboard
    return unless rich_dashboard_enabled?

    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] === STARTING DASHBOARD MIRRORING ==="
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Message ID: #{message.id}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Current message content_type: #{message.content_type}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Rich payload template_type: #{rich_payload['template_type']}"

    # Check if message is already in rich format (created directly as cards)
    if message_already_rich?
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Message already created as rich cards, skipping mirroring"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] === DASHBOARD MIRRORING SKIPPED ==="
      return
    end

    # Use the Instagram Renderer Mapper to convert payload to Chatwoot format
    mapped_result = Messages::InstagramRendererMapper.map(rich_payload)
    
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Mapped content_type: #{mapped_result.content_type}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Mapped fallback_text: #{mapped_result.fallback_text}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Mapped content_attributes keys: #{mapped_result.content_attributes.keys}"

    # Update message with rich content using update_columns for performance
    # This bypasses callbacks and validations for better performance
    message.update_columns(
      content_type: Message.content_types[mapped_result.content_type],
      content_attributes: mapped_result.content_attributes,
      content: mapped_result.fallback_text,
      updated_at: Time.current
    )

    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Message updated successfully"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Final content_type (enum): #{message.content_type}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Final content_type (string): #{message.content_type}"
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] === DASHBOARD MIRRORING COMPLETED ==="

  rescue StandardError => e
    Rails.logger.error "[SOCIALWISE-INSTAGRAM-RICH] Dashboard mirroring failed for message #{message.id}: #{e.class}: #{e.message}"
    Rails.logger.error "[SOCIALWISE-INSTAGRAM-RICH] Mirroring error backtrace: #{e.backtrace.first(5).join('\n')}"
    
    # Continue with normal flow even if mirroring fails
    # This ensures Instagram API sending is not affected by dashboard issues
  end

  # Check if rich dashboard feature is enabled
  def rich_dashboard_enabled?
    # ALWAYS return true - feature flag dependency removed
    # This is a core system feature and should always be enabled
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Rich dashboard always enabled (feature flag dependency removed)"
    true
  end

  # Check if message is already in rich format (created directly as cards/input_select)
  def message_already_rich?
    rich_content_types = %w[cards input_select]
    is_rich = rich_content_types.include?(message.content_type)
    
    Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] Message already rich check: #{is_rich} (content_type: #{message.content_type})"
    is_rich
  end
end