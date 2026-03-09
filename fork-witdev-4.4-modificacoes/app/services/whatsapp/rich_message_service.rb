# frozen_string_literal: true

class Whatsapp::RichMessageService
  pattr_initialize [:message!, :interactive_payload!]

  def perform
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] === STARTING PERFORM ==="
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Message ID: #{message.id}"
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Message type: #{message.message_type}"
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Message outgoing?: #{message.outgoing?}"
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Interactive payload: #{interactive_payload.inspect}"

    validate_message
    validate_channel

    # Mirror interactive payload to dashboard before sending to WhatsApp API
    mirror_interactive_payload_to_dashboard

    # Send interactive message
    send_interactive_message

    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] === PERFORM COMPLETED ==="
  rescue StandardError => e
    Rails.logger.error "[SOCIALWISE-WHATSAPP-RICH] Rich message send failed: #{e.class}: #{e.message}"
    Rails.logger.error "[SOCIALWISE-WHATSAPP-RICH] Backtrace: #{e.backtrace.join('\n')}"
    handle_error(e)
  end

  private

  def validate_message
    unless message.outgoing?
      Rails.logger.warn "[SOCIALWISE-WHATSAPP-RICH] Message is not outgoing, skipping"
      return false
    end

    if message.private?
      Rails.logger.warn "[SOCIALWISE-WHATSAPP-RICH] Message is private, skipping"
      return false
    end

    true
  end

  def validate_channel
    inbox = message.conversation.inbox
    channel = inbox.channel
    
    unless channel.is_a?(Channel::Whatsapp)
      Rails.logger.error "[SOCIALWISE-WHATSAPP-RICH] Channel is not WhatsApp: #{channel.class}"
      raise ArgumentError, "Channel must be WhatsApp"
    end

    @channel = channel
    @inbox = inbox
    true
  end

  def contact
    @contact ||= message.conversation.contact
  end

  def phone_number
    @phone_number ||= contact.get_source_id(@inbox.id)
  end

  # Mirror interactive payload to dashboard for visualization (EXACT Instagram pattern)
  def mirror_interactive_payload_to_dashboard
    # ALWAYS mirror - NO FEATURE FLAG DEPENDENCY
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Mirroring enabled (feature flag dependency removed)"

    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] === STARTING DASHBOARD MIRRORING ==="
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Message ID: #{message.id}"
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Current message content_type: #{message.content_type}"
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Interactive payload type: #{interactive_payload['type']}"

    # Check if message is already in rich format (created directly as integrations) - EXACT INSTAGRAM PATTERN
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Checking if message is already rich..."
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Message content_type: #{message.content_type} (class: #{message.content_type.class})"
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Message content_attributes keys: #{message.content_attributes.keys}"
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Message has interactive payload: #{!!(message.content_attributes['interactive'] || message.content_attributes['whatsapp_interactive_payload'])}"
    
    if message_already_rich?
      Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] ✅ Message already created as rich content, skipping mirroring"
      Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] === DASHBOARD MIRRORING SKIPPED ==="
      return
    else
      Rails.logger.warn "[SOCIALWISE-WHATSAPP-RICH] ⚠️ Message NOT detected as rich, will do mirroring (THIS MIGHT CAUSE FLASH EFFECT)"
    end

    # Use the WhatsApp Renderer Mapper to convert payload to Chatwoot format - EXACT INSTAGRAM PATTERN
    mapped_result = Messages::WhatsappRendererMapper.map(interactive_payload)
    
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Mapped content_type: #{mapped_result.content_type}"
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Mapped fallback_text: #{mapped_result.fallback_text}"
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Mapped content_attributes keys: #{mapped_result.content_attributes.keys}"

    # Update message with rich content using update_columns for performance - EXACT INSTAGRAM PATTERN
    # This bypasses callbacks and validations for better performance
    Rails.logger.warn "[SOCIALWISE-WHATSAPP-RICH] 🚨 ABOUT TO UPDATE MESSAGE - THIS MIGHT CAUSE FLASH EFFECT"
    Rails.logger.warn "[SOCIALWISE-WHATSAPP-RICH] Current content_type: #{message.content_type}"
    Rails.logger.warn "[SOCIALWISE-WHATSAPP-RICH] New content_type: #{mapped_result.content_type}"
    Rails.logger.warn "[SOCIALWISE-WHATSAPP-RICH] Current content_attributes: #{message.content_attributes.keys}"
    Rails.logger.warn "[SOCIALWISE-WHATSAPP-RICH] New content_attributes: #{mapped_result.content_attributes.keys}"
    
    message.update_columns(
      content_type: Message.content_types[mapped_result.content_type],
      content_attributes: mapped_result.content_attributes,
      content: mapped_result.fallback_text,
      updated_at: Time.current
    )
    
    Rails.logger.warn "[SOCIALWISE-WHATSAPP-RICH] 🚨 MESSAGE UPDATED - Frontend should receive this update via WebSocket"

    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Message updated successfully"
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Final content_type (enum): #{message.content_type}"
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] === DASHBOARD MIRRORING COMPLETED ==="

  rescue StandardError => e
    Rails.logger.error "[SOCIALWISE-WHATSAPP-RICH] Dashboard mirroring failed for message #{message.id}: #{e.class}: #{e.message}"
    Rails.logger.error "[SOCIALWISE-WHATSAPP-RICH] Mirroring error backtrace: #{e.backtrace.first(5).join('\n')}"
    
    # Continue with normal flow even if mirroring fails
    # This ensures WhatsApp API sending is not affected by dashboard issues
  end





  # Extract meaningful text from interactive payload using mapper
  def extract_fallback_text
    # Use the mapper to get consistent fallback text
    mapped_result = Messages::WhatsappRendererMapper.map(interactive_payload)
    mapped_result.fallback_text
  rescue StandardError => e
    Rails.logger.error "[SOCIALWISE-WHATSAPP-RICH] Fallback text extraction failed: #{e.class}: #{e.message}"
    'Mensagem interativa do WhatsApp'
  end

  # Send interactive message using WhatsApp provider
  def send_interactive_message
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] === STARTING WHATSAPP SEND ==="
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Phone number: #{phone_number}"
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Provider: #{@channel.provider}"

    if phone_number.blank?
      Rails.logger.error "[SOCIALWISE-WHATSAPP-RICH] Phone number is blank"
      raise ArgumentError, "Phone number is required"
    end

    # Store interactive payload in message for provider to use (only if not already present)
    unless message.content_attributes['interactive_payload'] == interactive_payload
      message.content_attributes['interactive_payload'] = interactive_payload
      message.save!
      Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Interactive payload stored in message"
    else
      Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Interactive payload already present, skipping save"
    end

    # Use existing WhatsApp provider infrastructure
    provider = provider_service(@channel)
    result = provider.send_interactive_text_message(phone_number, message)

    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] WhatsApp send result: #{result.inspect}"
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] === WHATSAPP SEND COMPLETED ==="
    
    result
  end

  def provider_service(channel)
    case channel.provider
    when 'whatsapp_cloud'
      Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: channel)
    when 'unoapi'
      Whatsapp::Providers::Whatsapp360DialogService.new(whatsapp_channel: channel)
    else
      Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Unknown provider #{channel.provider}, defaulting to whatsapp_cloud"
      Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: channel)
    end
  end



  # Check if message is already in rich format
  def message_already_rich?
    rich_content_types = %w[cards input_select integrations]
    is_rich = rich_content_types.include?(message.content_type)
    
    Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Message already rich check: #{is_rich} (content_type: #{message.content_type})"
    is_rich
  end




  def handle_error(error)
    Rails.logger.error "[SOCIALWISE-WHATSAPP-RICH] Error in WhatsApp rich message service: #{error.class}: #{error.message}"
    
    # Try to send as simple text message as fallback
    begin
      Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Attempting fallback to simple text message"
      
      fallback_text = extract_fallback_text
      message.update!(content: fallback_text, content_type: 'text')
      
      provider = provider_service(@channel)
      provider.send_text_message(phone_number, message)
      
      Rails.logger.info "[SOCIALWISE-WHATSAPP-RICH] Fallback text message sent successfully"
    rescue StandardError => fallback_error
      Rails.logger.error "[SOCIALWISE-WHATSAPP-RICH] Fallback message also failed: #{fallback_error.class}: #{fallback_error.message}"
    end
  end
end
  