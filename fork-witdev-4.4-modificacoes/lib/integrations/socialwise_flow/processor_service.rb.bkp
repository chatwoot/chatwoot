# lib/integrations/socialwise_flow/processor_service.rb

class Integrations::SocialwiseFlow::ProcessorService < Integrations::BotProcessorService
  pattr_initialize [:event_name!, :hook!, :event_data!]

  private

  def message_content(message)
    return message.content_attributes['submitted_values']&.first&.dig('value') if event_name == 'message.updated'
    message.content
  end

  def get_response(session_id, message_content)
    url = hook.settings['endpoint'].presence || 'https://socialwise.witdev.com.br/api/integrations/webhooks/socialwiseflow'

    payload = build_request_payload(session_id, message_content)

    headers = {
      'Content-Type' => 'application/json'
    }
    headers['Authorization'] = "Bearer #{hook.settings['access_token']}" if hook.settings['access_token'].present?

    # Debug: Log full outbound content
    begin
      log_headers = headers.dup
      log_headers['Authorization'] = '[FILTERED]' if log_headers['Authorization']
      Rails.logger.info "[SOCIALWISE-FLOW] === SENDING REQUEST TO SOCIALWISE FLOW ==="
      Rails.logger.info "[SOCIALWISE-FLOW] URL: #{url}"
      Rails.logger.info "[SOCIALWISE-FLOW] HEADERS: #{log_headers.inspect}"
      Rails.logger.info "[SOCIALWISE-FLOW] PAYLOAD: #{payload.inspect}"
      Rails.logger.info "[SOCIALWISE-FLOW] === END REQUEST ==="
    rescue => e
      Rails.logger.warn "[SOCIALWISE-FLOW] Failed to log payload: #{e.class}: #{e.message}"
    end

    response = HTTParty.post(url, headers: headers, body: payload.to_json, timeout: 30)
    
    if response.success?
      Rails.logger.info "[SOCIALWISE-FLOW] Response received: #{response.parsed_response.inspect}"
      response.parsed_response
    else
      Rails.logger.error "[SOCIALWISE-FLOW] HTTP error: #{response.code} - #{response.message}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "[SOCIALWISE-FLOW] Request failed: #{e.class}: #{e.message}"
    Rails.logger.error "[SOCIALWISE-FLOW] Backtrace: #{e.backtrace.first(5).join('\n')}"
    nil
  end

  def process_response(message, response)
    Rails.logger.info "[SOCIALWISE-FLOW] === PROCESSING RESPONSE ==="
    Rails.logger.info "[SOCIALWISE-FLOW] Message ID: #{message.id}, Conversation ID: #{message.conversation.id}"
    Rails.logger.info "[SOCIALWISE-FLOW] Account ID: #{message.conversation.account_id}, Inbox ID: #{message.conversation.inbox_id}"
    Rails.logger.info "[SOCIALWISE-FLOW] Channel type: #{message.conversation.inbox.channel_type}"
    Rails.logger.info "[SOCIALWISE-FLOW] Response: #{response.inspect}"
    
    # Requirement 6.1: Log detailed error information when response is blank
    if response.blank?
      Rails.logger.warn "[SOCIALWISE-FLOW] Empty or nil response received"
      Rails.logger.warn "[SOCIALWISE-FLOW] Message content: #{message.content}"
      Rails.logger.warn "[SOCIALWISE-FLOW] Hook settings: #{hook.settings.inspect}"
      return
    end

    begin
      # Primeiro, processar button_reaction se existir
      if response['action_type'] == 'button_reaction'
        Rails.logger.info "[SOCIALWISE-FLOW] Processing button_reaction"
        process_button_reaction(message, response)
        return
      end

      # Processar ação padrão (handoff, resolve)
      if response['action'].present?
        Rails.logger.info "[SOCIALWISE-FLOW] Processing action: #{response['action']}"
        begin
          process_action(message, response['action'])
          Rails.logger.info "[SOCIALWISE-FLOW] Action processed successfully: #{response['action']}"
        rescue StandardError => action_error
          # Requirement 6.3: Log handoff action failures but don't block message processing
          Rails.logger.error "[SOCIALWISE-FLOW] Action processing failed: #{action_error.class}: #{action_error.message}"
          Rails.logger.error "[SOCIALWISE-FLOW] Action: #{response['action']}"
          Rails.logger.error "[SOCIALWISE-FLOW] Message ID: #{message.id}"
          Rails.logger.error "[SOCIALWISE-FLOW] Backtrace: #{action_error.backtrace.first(3).join('\n')}"
          # Continue processing messages even if action fails
        end
        # Não retornar aqui, pode haver mensagem também
      end

      # Rotear por canal
      channel_type = message.conversation.inbox.channel_type
      Rails.logger.info "[SOCIALWISE-FLOW] Channel type: #{channel_type}"

      case channel_type
      when 'Channel::Whatsapp'
        if response['whatsapp'].present?
          process_whatsapp_response(message, response['whatsapp'])
        else
          Rails.logger.warn "[SOCIALWISE-FLOW] WhatsApp channel but no whatsapp payload in response"
        end
      when 'Channel::FacebookPage', 'Channel::Instagram'
        # Instagram pode usar Channel::FacebookPage ou Channel::Instagram
        if response['instagram'].present?
          process_instagram_response(message, response['instagram'])
        elsif response['facebook'].present?
          process_facebook_response(message, response['facebook'])
        else
          Rails.logger.warn "[SOCIALWISE-FLOW] Facebook/Instagram channel but no instagram/facebook payload in response"
        end
      else
        # Fallback para texto simples
        if response['text'].present?
          Rails.logger.info "[SOCIALWISE-FLOW] Using text fallback for channel: #{channel_type}"
          create_conversation(message, { content: response['text'] })
        else
          Rails.logger.warn "[SOCIALWISE-FLOW] No suitable payload found for channel: #{channel_type}"
          Rails.logger.warn "[SOCIALWISE-FLOW] Available response keys: #{response.keys.inspect}"
        end
      end
      
      Rails.logger.info "[SOCIALWISE-FLOW] === RESPONSE PROCESSING COMPLETED ==="
      
    rescue StandardError => e
      # Requirement 6.1: Log detailed error information
      Rails.logger.error "[SOCIALWISE-FLOW] === RESPONSE PROCESSING FAILED ==="
      Rails.logger.error "[SOCIALWISE-FLOW] Exception class: #{e.class}"
      Rails.logger.error "[SOCIALWISE-FLOW] Exception message: #{e.message}"
      Rails.logger.error "[SOCIALWISE-FLOW] Message ID: #{message.id}"
      Rails.logger.error "[SOCIALWISE-FLOW] Conversation ID: #{message.conversation.id}"
      Rails.logger.error "[SOCIALWISE-FLOW] Account ID: #{message.conversation.account_id}"
      Rails.logger.error "[SOCIALWISE-FLOW] Inbox ID: #{message.conversation.inbox_id}"
      Rails.logger.error "[SOCIALWISE-FLOW] Channel type: #{message.conversation.inbox.channel_type}"
      Rails.logger.error "[SOCIALWISE-FLOW] Response data: #{response.inspect}"
      Rails.logger.error "[SOCIALWISE-FLOW] Backtrace: #{e.backtrace.first(10).join('\n')}"
      
      # Requirement 6.4: Create fallback text message with raw response when format is invalid
      begin
        fallback_content = extract_fallback_content_from_response(response)
        create_conversation(message, { content: fallback_content })
        Rails.logger.info "[SOCIALWISE-FLOW] Created fallback message with content: #{fallback_content}"
      rescue StandardError => fallback_error
        Rails.logger.error "[SOCIALWISE-FLOW] Fallback message creation also failed: #{fallback_error.class}: #{fallback_error.message}"
        # Last resort: create simple error message
        begin
          create_conversation(message, { content: "Erro ao processar resposta do bot" })
          Rails.logger.info "[SOCIALWISE-FLOW] Created simple error message as last resort"
        rescue StandardError => last_resort_error
          Rails.logger.error "[SOCIALWISE-FLOW] Even simple error message creation failed: #{last_resort_error.class}: #{last_resort_error.message}"
        end
      end
    end
  end

  def process_button_reaction(message, response)
    Rails.logger.info "[SOCIALWISE-FLOW] === PROCESSING BUTTON REACTION ==="
    Rails.logger.info "[SOCIALWISE-FLOW] Button ID: #{response['buttonId']}"
    Rails.logger.info "[SOCIALWISE-FLOW] Emoji: #{response['emoji']}"
    Rails.logger.info "[SOCIALWISE-FLOW] Text: #{response['text']}"
    Rails.logger.info "[SOCIALWISE-FLOW] Action: #{response['action']}"
    Rails.logger.info "[SOCIALWISE-FLOW] Message ID: #{message.id}"
    Rails.logger.info "[SOCIALWISE-FLOW] Conversation ID: #{message.conversation.id}"
    
    begin
      conversation = message.conversation
      channel_type = conversation.inbox.channel_type
      Rails.logger.info "[SOCIALWISE-FLOW] Channel type: #{channel_type}"
      
      # Validate response data
      if response['buttonId'].blank?
        Rails.logger.warn "[SOCIALWISE-FLOW] Button reaction missing buttonId"
      end
      
      begin
        # 1. Send emoji reaction based on channel type (Requirements 3.2, 3.3)
        if response['emoji'].present?
          Rails.logger.info "[SOCIALWISE-FLOW] Sending emoji reaction: #{response['emoji']}"
          send_emoji_reaction(message, response, channel_type)
          Rails.logger.info "[SOCIALWISE-FLOW] Emoji reaction sent successfully"
        else
          Rails.logger.warn "[SOCIALWISE-FLOW] No emoji in button reaction response"
        end
        
      rescue StandardError => emoji_error
        # Requirement 6.2: Continue processing other response elements when emoji reaction fails
        Rails.logger.error "[SOCIALWISE-FLOW] Emoji reaction sending failed: #{emoji_error.class}: #{emoji_error.message}"
        Rails.logger.error "[SOCIALWISE-FLOW] Emoji: #{response['emoji']}"
        Rails.logger.error "[SOCIALWISE-FLOW] Channel type: #{channel_type}"
        Rails.logger.error "[SOCIALWISE-FLOW] Backtrace: #{emoji_error.backtrace.first(3).join('\n')}"
        # Continue processing even if emoji reaction fails (Requirement 3.4)
      end
      
      begin
        # 2. Send contextual response text (Requirements 3.2, 3.3)
        if response['text'].present?
          Rails.logger.info "[SOCIALWISE-FLOW] Sending reaction text: #{response['text']}"
          send_reaction_text(message, response, channel_type)
          Rails.logger.info "[SOCIALWISE-FLOW] Reaction text sent successfully"
        else
          Rails.logger.warn "[SOCIALWISE-FLOW] No text in button reaction response"
        end
        
      rescue StandardError => text_error
        # Requirement 6.2: Continue processing other response elements when text sending fails
        Rails.logger.error "[SOCIALWISE-FLOW] Reaction text sending failed: #{text_error.class}: #{text_error.message}"
        Rails.logger.error "[SOCIALWISE-FLOW] Text: #{response['text']}"
        Rails.logger.error "[SOCIALWISE-FLOW] Channel type: #{channel_type}"
        Rails.logger.error "[SOCIALWISE-FLOW] Backtrace: #{text_error.backtrace.first(3).join('\n')}"
        # Continue processing even if text sending fails (Requirement 3.4)
      end
      
      # 3. Process handoff action even if reaction sending failed (Requirements 3.4, 4.1, 4.2, 4.3, 4.4)
      if response['action'].present?
        Rails.logger.info "[SOCIALWISE-FLOW] Processing button reaction action: #{response['action']}"
        begin
          process_action(message, response['action'])
          Rails.logger.info "[SOCIALWISE-FLOW] Action processed successfully: #{response['action']}"
        rescue StandardError => action_error
          # Requirement 6.3: Log handoff action failures but don't block message processing
          Rails.logger.error "[SOCIALWISE-FLOW] Action processing failed: #{action_error.class}: #{action_error.message}"
          Rails.logger.error "[SOCIALWISE-FLOW] Action: #{response['action']}"
          Rails.logger.error "[SOCIALWISE-FLOW] Message ID: #{message.id}"
          Rails.logger.error "[SOCIALWISE-FLOW] Conversation ID: #{conversation.id}"
          Rails.logger.error "[SOCIALWISE-FLOW] Backtrace: #{action_error.backtrace.first(5).join('\n')}"
          # Log error but don't re-raise (Requirement 6.3)
        end
      else
        Rails.logger.info "[SOCIALWISE-FLOW] No action specified in button reaction"
      end
      
      Rails.logger.info "[SOCIALWISE-FLOW] === BUTTON REACTION PROCESSING COMPLETED ==="
      
    rescue StandardError => e
      # Requirement 6.1: Log detailed error information
      Rails.logger.error "[SOCIALWISE-FLOW] === BUTTON REACTION PROCESSING FAILED ==="
      Rails.logger.error "[SOCIALWISE-FLOW] Exception class: #{e.class}"
      Rails.logger.error "[SOCIALWISE-FLOW] Exception message: #{e.message}"
      Rails.logger.error "[SOCIALWISE-FLOW] Message ID: #{message.id}"
      Rails.logger.error "[SOCIALWISE-FLOW] Conversation ID: #{message.conversation.id}"
      Rails.logger.error "[SOCIALWISE-FLOW] Channel type: #{message.conversation.inbox.channel_type}"
      Rails.logger.error "[SOCIALWISE-FLOW] Response data: #{response.inspect}"
      Rails.logger.error "[SOCIALWISE-FLOW] Backtrace: #{e.backtrace.first(10).join('\n')}"
      
      # Still try to process handoff if specified (Requirement 3.4)
      if response['action'].present?
        begin
          Rails.logger.info "[SOCIALWISE-FLOW] Attempting handoff despite button reaction failure"
          process_action(message, response['action'])
          Rails.logger.info "[SOCIALWISE-FLOW] Handoff processed successfully despite earlier failure"
        rescue StandardError => handoff_error
          Rails.logger.error "[SOCIALWISE-FLOW] Handoff also failed: #{handoff_error.class}: #{handoff_error.message}"
          Rails.logger.error "[SOCIALWISE-FLOW] Handoff error backtrace: #{handoff_error.backtrace.first(3).join('\n')}"
        end
      end
    end
  end

  private

  def send_emoji_reaction(message, response, channel_type)
    Rails.logger.info "[SOCIALWISE-FLOW] Sending emoji reaction for #{channel_type}"
    
    conversation = message.conversation
    emoji = response['emoji']
    
    case channel_type
    when 'Channel::Whatsapp'
      # WhatsApp: Send both emoji reaction and contextual response (Requirement 3.2)
      send_whatsapp_emoji_reaction(conversation, emoji, response)
    when 'Channel::FacebookPage'
      # Instagram: Send emoji reaction and simple response (Requirement 3.3)
      send_instagram_emoji_reaction(conversation, emoji, response)
    else
      # Generic emoji reaction for other channels
      send_generic_emoji_reaction(conversation, emoji, response)
    end
  end

  def send_reaction_text(message, response, channel_type)
    Rails.logger.info "[SOCIALWISE-FLOW] Sending reaction text for #{channel_type}"
    
    conversation = message.conversation
    text = response['text']
    
    case channel_type
    when 'Channel::Whatsapp'
      # WhatsApp: Send contextual response text (Requirement 3.2)
      send_whatsapp_reaction_text(conversation, text, response)
    when 'Channel::FacebookPage'
      # Instagram: Send simple response text (Requirement 3.3)
      send_instagram_reaction_text(conversation, text, response)
    else
      # Generic text response for other channels
      send_generic_reaction_text(conversation, text, response)
    end
  end

  def send_whatsapp_emoji_reaction(conversation, emoji, response)
    # Create activity message indicating emoji reaction
    emoji_message = conversation.messages.create!(
      message_type: :activity,
      content: "Bot reagiu com #{emoji}",
      private: false,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content_attributes: {
        'emoji_reaction' => emoji,
        'button_id' => response['buttonId'],
        'reaction_type' => 'button_reaction',
        'channel_type' => 'whatsapp'
      }
    )
    
    Rails.logger.info "[SOCIALWISE-FLOW] WhatsApp emoji reaction message created: #{emoji_message.id}"
  end

  def send_instagram_emoji_reaction(conversation, emoji, response)
    # Create activity message indicating emoji reaction for Instagram
    emoji_message = conversation.messages.create!(
      message_type: :activity,
      content: "Bot reagiu com #{emoji}",
      private: false,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content_attributes: {
        'emoji_reaction' => emoji,
        'button_id' => response['buttonId'],
        'reaction_type' => 'button_reaction',
        'channel_type' => 'instagram'
      }
    )
    
    Rails.logger.info "[SOCIALWISE-FLOW] Instagram emoji reaction message created: #{emoji_message.id}"
  end

  def send_generic_emoji_reaction(conversation, emoji, response)
    # Generic emoji reaction for other channels
    emoji_message = conversation.messages.create!(
      message_type: :activity,
      content: "Bot reagiu com #{emoji}",
      private: false,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content_attributes: {
        'emoji_reaction' => emoji,
        'button_id' => response['buttonId'],
        'reaction_type' => 'button_reaction',
        'channel_type' => 'generic'
      }
    )
    
    Rails.logger.info "[SOCIALWISE-FLOW] Generic emoji reaction message created: #{emoji_message.id}"
  end

  def send_whatsapp_reaction_text(conversation, text, response)
    # WhatsApp contextual response text
    text_message = conversation.messages.create!(
      message_type: :outgoing,
      content: text,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content_attributes: {
        'button_reaction_response' => true,
        'button_id' => response['buttonId'],
        'channel_type' => 'whatsapp'
      }
    )
    
    Rails.logger.info "[SOCIALWISE-FLOW] WhatsApp reaction text message created: #{text_message.id}"
  end

  def send_instagram_reaction_text(conversation, text, response)
    # Instagram simple response text
    text_message = conversation.messages.create!(
      message_type: :outgoing,
      content: text,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content_attributes: {
        'button_reaction_response' => true,
        'button_id' => response['buttonId'],
        'channel_type' => 'instagram'
      }
    )
    
    Rails.logger.info "[SOCIALWISE-FLOW] Instagram reaction text message created: #{text_message.id}"
  end

  def send_generic_reaction_text(conversation, text, response)
    # Generic text response for other channels
    text_message = conversation.messages.create!(
      message_type: :outgoing,
      content: text,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content_attributes: {
        'button_reaction_response' => true,
        'button_id' => response['buttonId'],
        'channel_type' => 'generic'
      }
    )
    
    Rails.logger.info "[SOCIALWISE-FLOW] Generic reaction text message created: #{text_message.id}"
  end



  def create_conversation(message, content_params)
    # Requirement 7.1, 7.2: Create outgoing messages with proper message_type and tracking
    Rails.logger.info "[SOCIALWISE-FLOW] Creating conversation message"
    Rails.logger.info "[SOCIALWISE-FLOW] Content params: #{content_params.inspect}"
    
    if content_params.blank?
      Rails.logger.warn "[SOCIALWISE-FLOW] Blank content_params provided to create_conversation"
      return
    end

    begin
      conversation = message.conversation
      
      # Validate required fields
      unless conversation.account_id.present?
        Rails.logger.error "[SOCIALWISE-FLOW] Missing account_id in conversation"
        return
      end
      
      unless conversation.inbox_id.present?
        Rails.logger.error "[SOCIALWISE-FLOW] Missing inbox_id in conversation"
        return
      end
      
      # Ensure content is present
      if content_params[:content].blank? && content_params['content'].blank?
        Rails.logger.warn "[SOCIALWISE-FLOW] No content in content_params, adding default"
        content_params[:content] = 'Bot message'
      end
      
      # Requirement 7.3: Include proper account_id and inbox_id for tracking
      merged_params = content_params.merge(
        {
          message_type: :outgoing,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id
        }
      )
      
      Rails.logger.info "[SOCIALWISE-FLOW] Creating message with params: #{merged_params.inspect}"
      
      created_message = conversation.messages.create!(merged_params)
      
      Rails.logger.info "[SOCIALWISE-FLOW] Message created successfully: #{created_message.id}"
      Rails.logger.info "[SOCIALWISE-FLOW] Message content: #{created_message.content}"
      Rails.logger.info "[SOCIALWISE-FLOW] Message content_type: #{created_message.content_type}"
      
      created_message
      
    rescue StandardError => e
      # Requirement 6.1: Log detailed error information
      Rails.logger.error "[SOCIALWISE-FLOW] === MESSAGE CREATION FAILED ==="
      Rails.logger.error "[SOCIALWISE-FLOW] Exception class: #{e.class}"
      Rails.logger.error "[SOCIALWISE-FLOW] Exception message: #{e.message}"
      Rails.logger.error "[SOCIALWISE-FLOW] Original message ID: #{message.id}"
      Rails.logger.error "[SOCIALWISE-FLOW] Conversation ID: #{message.conversation.id}"
      Rails.logger.error "[SOCIALWISE-FLOW] Account ID: #{message.conversation.account_id}"
      Rails.logger.error "[SOCIALWISE-FLOW] Inbox ID: #{message.conversation.inbox_id}"
      Rails.logger.error "[SOCIALWISE-FLOW] Content params: #{content_params.inspect}"
      Rails.logger.error "[SOCIALWISE-FLOW] Backtrace: #{e.backtrace.first(5).join('\n')}"
      
      # Try to create a minimal fallback message
      begin
        Rails.logger.info "[SOCIALWISE-FLOW] Attempting minimal fallback message creation"
        fallback_message = message.conversation.messages.create!(
          message_type: :outgoing,
          content: 'Message creation failed',
          account_id: message.conversation.account_id,
          inbox_id: message.conversation.inbox_id
        )
        Rails.logger.info "[SOCIALWISE-FLOW] Minimal fallback message created: #{fallback_message.id}"
        fallback_message
      rescue StandardError => fallback_error
        Rails.logger.error "[SOCIALWISE-FLOW] Minimal fallback message creation also failed: #{fallback_error.class}: #{fallback_error.message}"
        nil
      end
    end
  end

  # ===== WhatsApp =====
  def process_whatsapp_response(message, whatsapp_payload)
    Rails.logger.info "[SOCIALWISE-FLOW] === PROCESSING WHATSAPP RESPONSE ==="
    Rails.logger.info "[SOCIALWISE-FLOW] WhatsApp payload: #{whatsapp_payload.inspect}"
    
    # Requirement 6.1: Log detailed error information when payload is blank
    if whatsapp_payload.blank?
      Rails.logger.warn "[SOCIALWISE-FLOW][WHATSAPP] Empty or nil WhatsApp payload received"
      Rails.logger.warn "[SOCIALWISE-FLOW][WHATSAPP] Message ID: #{message.id}"
      Rails.logger.warn "[SOCIALWISE-FLOW][WHATSAPP] Conversation ID: #{message.conversation.id}"
      return
    end
    
    begin
      conversation = message.conversation
      
      # Verificar se é canal WhatsApp
      unless conversation.inbox.channel_type == 'Channel::Whatsapp'
        Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] WhatsApp response received but channel is not WhatsApp"
        Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Actual channel type: #{conversation.inbox.channel_type}"
        Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Expected: Channel::Whatsapp"
        Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Message ID: #{message.id}"
        Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Conversation ID: #{conversation.id}"
        Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Inbox ID: #{conversation.inbox.id}"
        return
      end
      
      Rails.logger.info "[SOCIALWISE-FLOW][WHATSAPP] Channel validation passed, processing with WhatsappResponseProcessor"
      
      # Usar o WhatsappResponseProcessor dedicado (seguindo padrão do Instagram)
      begin
        success = Integrations::SocialwiseFlow::WhatsappResponseProcessor.process(whatsapp_payload, message)
        
        if success
          Rails.logger.info "[SOCIALWISE-FLOW][WHATSAPP] WhatsApp response processed successfully by WhatsappResponseProcessor"
        else
          # Requirement 6.2: Continue processing other response elements when rich message sending fails
          Rails.logger.warn "[SOCIALWISE-FLOW][WHATSAPP] WhatsApp response processing returned false, creating fallback message"
          Rails.logger.warn "[SOCIALWISE-FLOW][WHATSAPP] Message type: #{whatsapp_payload['type']}"
          
          # Fallback: criar mensagem de texto simples
          create_fallback_whatsapp_message(message, whatsapp_payload)
        end
        
      rescue StandardError => processor_error
        # Requirement 6.1: Log detailed error information
        Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] === WHATSAPP PROCESSOR EXCEPTION ==="
        Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Exception class: #{processor_error.class}"
        Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Exception message: #{processor_error.message}"
        Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Message ID: #{message.id}"
        Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Conversation ID: #{conversation.id}"
        Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Account ID: #{conversation.account_id}"
        Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Inbox ID: #{conversation.inbox_id}"
        Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] WhatsApp payload: #{whatsapp_payload.inspect}"
        Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Backtrace: #{processor_error.backtrace.first(10).join('\n')}"
        
        # Requirement 6.4: Create fallback text message when processing fails
        create_fallback_whatsapp_message(message, whatsapp_payload)
      end
      
      Rails.logger.info "[SOCIALWISE-FLOW][WHATSAPP] === WHATSAPP PROCESSING COMPLETED ==="
      
    rescue StandardError => e
      # Requirement 6.1: Log detailed error information
      Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] === WHATSAPP PROCESSING FAILED ==="
      Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Exception class: #{e.class}"
      Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Exception message: #{e.message}"
      Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Message ID: #{message.id}"
      Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Conversation ID: #{message.conversation.id}"
      Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Channel type: #{message.conversation.inbox.channel_type}"
      Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] WhatsApp payload: #{whatsapp_payload.inspect}"
      Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Backtrace: #{e.backtrace.first(10).join('\n')}"
      
      # Requirement 6.4: Create fallback text message when processing fails
      begin
        create_fallback_whatsapp_message(message, whatsapp_payload)
        Rails.logger.info "[SOCIALWISE-FLOW][WHATSAPP] Created fallback message after processing failure"
      rescue StandardError => fallback_error
        Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Fallback message creation failed: #{fallback_error.class}: #{fallback_error.message}"
      end
    end
  end

  # ===== Instagram =====
  def process_instagram_response(message, instagram_payload)
    Rails.logger.info "[SOCIALWISE-FLOW] === PROCESSING INSTAGRAM RESPONSE ==="
    Rails.logger.info "[SOCIALWISE-FLOW] Instagram payload: #{instagram_payload.inspect}"
    
    # Requirement 6.1: Log detailed error information when payload is blank
    if instagram_payload.blank?
      Rails.logger.warn "[SOCIALWISE-FLOW][INSTAGRAM] Empty or nil Instagram payload received"
      Rails.logger.warn "[SOCIALWISE-FLOW][INSTAGRAM] Message ID: #{message.id}"
      Rails.logger.warn "[SOCIALWISE-FLOW][INSTAGRAM] Conversation ID: #{message.conversation.id}"
      return
    end
    
    begin
      conversation = message.conversation
      
      # Verificar se é canal Instagram (FacebookPage ou Instagram)
      valid_instagram_channels = ['Channel::FacebookPage', 'Channel::Instagram']
      unless valid_instagram_channels.include?(conversation.inbox.channel_type)
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Instagram response received but channel is not Instagram compatible"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Actual channel type: #{conversation.inbox.channel_type}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Expected: #{valid_instagram_channels.join(' or ')}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Message ID: #{message.id}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Conversation ID: #{conversation.id}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Inbox ID: #{conversation.inbox.id}"
        return
      end
      
      Rails.logger.info "[SOCIALWISE-FLOW][INSTAGRAM] Channel validation passed, processing with InstagramResponseProcessor"
      
      # Reestruturar payload para formato esperado pelo InstagramResponseProcessor
      # O processor espera: { message_format: 'X', payload: { template_type: 'Y', ... } }
      # Mas SocialWise Flow envia: { message_format: 'X', template_type: 'Y', ... }
      restructured_payload = {
        'message_format' => instagram_payload['message_format'],
        'payload' => instagram_payload.except('message_format')
      }
      
      Rails.logger.info "[SOCIALWISE-FLOW][INSTAGRAM] Restructured payload for processor: #{restructured_payload.inspect}"
      
      # Usar o InstagramResponseProcessor do Socialwise (mesmo usado pelo Dialogflow)
      begin
        success = Integrations::Socialwise::InstagramResponseProcessor.process(restructured_payload, message)
        
        if success
          Rails.logger.info "[SOCIALWISE-FLOW][INSTAGRAM] Instagram response processed successfully by InstagramResponseProcessor"
        else
          # Requirement 6.2: Continue processing other response elements when rich message sending fails
          Rails.logger.warn "[SOCIALWISE-FLOW][INSTAGRAM] Instagram response processing returned false, creating fallback message"
          Rails.logger.warn "[SOCIALWISE-FLOW][INSTAGRAM] Message format: #{instagram_payload['message_format']}"
          Rails.logger.warn "[SOCIALWISE-FLOW][INSTAGRAM] Template type: #{instagram_payload['template_type']}"
          
          # Fallback: criar mensagem de texto simples
          create_fallback_instagram_message(message, instagram_payload)
        end
        
      rescue StandardError => processor_error
        # Requirement 6.1: Log detailed error information
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] === INSTAGRAM PROCESSOR EXCEPTION ==="
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Exception class: #{processor_error.class}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Exception message: #{processor_error.message}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Message ID: #{message.id}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Conversation ID: #{conversation.id}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Account ID: #{conversation.account_id}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Inbox ID: #{conversation.inbox_id}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Instagram payload: #{instagram_payload.inspect}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Backtrace: #{processor_error.backtrace.first(10).join('\n')}"
        
        # Requirement 6.4: Create fallback text message when processing fails
        create_fallback_instagram_message(message, instagram_payload)
      end
      
      Rails.logger.info "[SOCIALWISE-FLOW][INSTAGRAM] === INSTAGRAM PROCESSING COMPLETED ==="
      
    rescue StandardError => e
      # Requirement 6.1: Log detailed error information
      Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] === INSTAGRAM PROCESSING FAILED ==="
      Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Exception class: #{e.class}"
      Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Exception message: #{e.message}"
      Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Message ID: #{message.id}"
      Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Conversation ID: #{message.conversation.id}"
      Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Channel type: #{message.conversation.inbox.channel_type}"
      Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Instagram payload: #{instagram_payload.inspect}"
      Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Backtrace: #{e.backtrace.first(10).join('\n')}"
      
      # Requirement 6.4: Create fallback text message when processing fails
      begin
        create_fallback_instagram_message(message, instagram_payload)
        Rails.logger.info "[SOCIALWISE-FLOW][INSTAGRAM] Created fallback message after processing failure"
      rescue StandardError => fallback_error
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Fallback message creation failed: #{fallback_error.class}: #{fallback_error.message}"
      end
    end
  end

  # ===== Facebook =====
  def process_facebook_response(message, facebook_payload)
    Rails.logger.info "[SOCIALWISE-FLOW] === PROCESSING FACEBOOK RESPONSE ==="
    Rails.logger.info "[SOCIALWISE-FLOW] Facebook payload: #{facebook_payload.inspect}"
    
    # Requirement 6.1: Log detailed error information when payload is blank
    if facebook_payload.blank?
      Rails.logger.warn "[SOCIALWISE-FLOW][FACEBOOK] Empty or nil Facebook payload received"
      Rails.logger.warn "[SOCIALWISE-FLOW][FACEBOOK] Message ID: #{message.id}"
      Rails.logger.warn "[SOCIALWISE-FLOW][FACEBOOK] Conversation ID: #{message.conversation.id}"
      return
    end
    
    begin
      conversation = message.conversation
      
      # Extract text content for dashboard display
      text_content = facebook_payload.dig('message', 'text') || 'Facebook message'
      Rails.logger.info "[SOCIALWISE-FLOW][FACEBOOK] Extracted text content: #{text_content}"
      
      # Determine if this is rich content or simple text
      has_rich_content = facebook_payload['message'].present? && 
                        (facebook_payload['message'].keys - ['text']).any?
      Rails.logger.info "[SOCIALWISE-FLOW][FACEBOOK] Has rich content: #{has_rich_content}"
      
      if has_rich_content
        Rails.logger.info "[SOCIALWISE-FLOW][FACEBOOK] Rich content keys: #{(facebook_payload['message'].keys - ['text']).inspect}"
      end
      
      # Create message for dashboard display (Requirement 7.1, 7.2)
      outgoing_message = nil
      begin
        content_params = {
          message_type: :outgoing,
          content: text_content,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id
        }
        
        if has_rich_content
          # Rich content - use integrations content_type
          content_params[:content_type] = 'integrations'
          content_params[:content_attributes] = facebook_payload
        else
          # Simple text message
          content_params[:content_type] = 'text'
        end
        
        outgoing_message = conversation.messages.create!(content_params)
        Rails.logger.info "[SOCIALWISE-FLOW][FACEBOOK] Message created: #{outgoing_message.id} (content_type: #{outgoing_message.content_type})"
        
      rescue StandardError => message_creation_error
        # Requirement 6.2: Continue processing even if message creation fails
        Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Message creation failed: #{message_creation_error.class}: #{message_creation_error.message}"
        Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Text content: #{text_content}"
        Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Has rich content: #{has_rich_content}"
        Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Backtrace: #{message_creation_error.backtrace.first(3).join('\n')}"
        
        # Try to create a simple fallback message
        begin
          outgoing_message = conversation.messages.create!(
            message_type: :outgoing,
            content: text_content,
            content_type: 'text',
            account_id: conversation.account_id,
            inbox_id: conversation.inbox_id
          )
          Rails.logger.info "[SOCIALWISE-FLOW][FACEBOOK] Fallback message created: #{outgoing_message.id}"
        rescue StandardError => fallback_error
          Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Fallback message creation also failed: #{fallback_error.class}: #{fallback_error.message}"
          return # Can't create message, abort processing
        end
      end
      
      # Send message using appropriate service
      if outgoing_message
        begin
          # Prepare payload for sending
          send_payload = facebook_payload.deep_dup
          
          # Add recipient ID if missing (Requirement 5.4)
          unless send_payload['recipient'].present?
            contact_source_id = conversation.contact.get_source_id(conversation.inbox.id)
            send_payload['recipient'] = { 'id' => contact_source_id }
            Rails.logger.info "[SOCIALWISE-FLOW][FACEBOOK] Added recipient ID: #{contact_source_id}"
          end
          
          if has_rich_content
            # Use RawDeliverService for rich content (Requirement 5.3)
            Rails.logger.info "[SOCIALWISE-FLOW][FACEBOOK] Sending rich content via RawDeliverService"
            Facebook::RawDeliverService.new(message: outgoing_message, payload: send_payload).perform
            Rails.logger.info "[SOCIALWISE-FLOW][FACEBOOK] Rich content sent successfully"
          else
            # Use standard service for simple text (Requirement 5.2)
            Rails.logger.info "[SOCIALWISE-FLOW][FACEBOOK] Sending text message via SendOnFacebookService"
            Facebook::SendOnFacebookService.new(message: outgoing_message).perform
            Rails.logger.info "[SOCIALWISE-FLOW][FACEBOOK] Text message sent successfully"
          end
          
        rescue StandardError => sending_error
          # Requirement 6.2: Log rich message sending failures but continue processing
          Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Message sending failed: #{sending_error.class}: #{sending_error.message}"
          Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Message ID: #{outgoing_message.id}"
          Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Has rich content: #{has_rich_content}"
          Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Contact source ID: #{conversation.contact.get_source_id(conversation.inbox.id) rescue 'unknown'}"
          Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Send payload: #{send_payload.inspect}"
          Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Backtrace: #{sending_error.backtrace.first(5).join('\n')}"
          # Message is created in dashboard, sending failure doesn't affect that
        end
      end
      
      Rails.logger.info "[SOCIALWISE-FLOW][FACEBOOK] === FACEBOOK PROCESSING COMPLETED ==="
      
    rescue StandardError => e
      # Requirement 6.1: Log detailed error information
      Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] === FACEBOOK PROCESSING FAILED ==="
      Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Exception class: #{e.class}"
      Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Exception message: #{e.message}"
      Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Message ID: #{message.id}"
      Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Conversation ID: #{message.conversation.id}"
      Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Facebook payload: #{facebook_payload.inspect}"
      Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Backtrace: #{e.backtrace.first(10).join('\n')}"
      
      # Requirement 6.4: Create fallback text message when processing fails
      begin
        fallback_text = facebook_payload.dig('message', 'text') || 
                       facebook_payload['text'] || 
                       'Facebook message processing failed'
        create_conversation(message, { content: fallback_text })
        Rails.logger.info "[SOCIALWISE-FLOW][FACEBOOK] Created fallback message: #{fallback_text}"
      rescue StandardError => fallback_error
        Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Fallback message creation failed: #{fallback_error.class}: #{fallback_error.message}"
      end
    end
  end

  # ==== Helper Methods =====
  
  def extract_whatsapp_text(payload)
    # Tentar extrair texto de diferentes locais no payload
    payload.dig('interactive', 'body', 'text') ||
    payload.dig('text', 'body') ||
    payload['text'] ||
    'Mensagem interativa'
  end
  
  def create_fallback_instagram_message(message, instagram_payload)
    Rails.logger.info "[SOCIALWISE-FLOW] Creating fallback Instagram message"
    Rails.logger.info "[SOCIALWISE-FLOW] Instagram payload for fallback: #{instagram_payload.inspect}"
    
    begin
      # Extrair texto principal do payload Instagram
      text = case instagram_payload['message_format']
             when 'QUICK_REPLIES'
               instagram_payload['text']
             when 'BUTTON_TEMPLATE'
               instagram_payload['text']
             when 'GENERIC_TEMPLATE'
               instagram_payload.dig('elements', 0, 'title')
             else
               'Mensagem rica do Instagram'
             end
      
      fallback_text = text || 'Mensagem do Instagram'
      create_conversation(message, { content: fallback_text })
      Rails.logger.info "[SOCIALWISE-FLOW] Instagram fallback message created: #{fallback_text}"
      
    rescue StandardError => e
      Rails.logger.error "[SOCIALWISE-FLOW] Instagram fallback message creation failed: #{e.class}: #{e.message}"
      Rails.logger.error "[SOCIALWISE-FLOW] Backtrace: #{e.backtrace.first(3).join('\n')}"
      
      # Last resort fallback
      begin
        create_conversation(message, { content: 'Instagram message processing failed' })
        Rails.logger.info "[SOCIALWISE-FLOW] Created last resort Instagram fallback message"
      rescue StandardError => last_resort_error
        Rails.logger.error "[SOCIALWISE-FLOW] Last resort Instagram fallback also failed: #{last_resort_error.class}: #{last_resort_error.message}"
      end
    end
  end

  def create_fallback_whatsapp_message(message, whatsapp_payload)
    Rails.logger.info "[SOCIALWISE-FLOW] Creating fallback WhatsApp message"
    Rails.logger.info "[SOCIALWISE-FLOW] WhatsApp payload for fallback: #{whatsapp_payload.inspect}"
    
    begin
      # Extrair texto principal do payload WhatsApp
      text = extract_whatsapp_text(whatsapp_payload)
      
      fallback_text = text || 'Mensagem do WhatsApp'
      create_conversation(message, { content: fallback_text })
      Rails.logger.info "[SOCIALWISE-FLOW] WhatsApp fallback message created: #{fallback_text}"
      
    rescue StandardError => e
      Rails.logger.error "[SOCIALWISE-FLOW] WhatsApp fallback message creation failed: #{e.class}: #{e.message}"
      Rails.logger.error "[SOCIALWISE-FLOW] Backtrace: #{e.backtrace.first(3).join('\n')}"
      
      # Last resort fallback
      begin
        create_conversation(message, { content: 'WhatsApp message processing failed' })
        Rails.logger.info "[SOCIALWISE-FLOW] Created last resort WhatsApp fallback message"
      rescue StandardError => last_resort_error
        Rails.logger.error "[SOCIALWISE-FLOW] Last resort WhatsApp fallback also failed: #{last_resort_error.class}: #{last_resort_error.message}"
      end
    end
  end

  # Helper method to extract fallback content from any response format
  def extract_fallback_content_from_response(response)
    Rails.logger.info "[SOCIALWISE-FLOW] Extracting fallback content from response"
    
    # Try to extract meaningful text from various response formats
    fallback_content = nil
    
    # Try text field first
    fallback_content = response['text'] if response['text'].present?
    
    # Try WhatsApp content
    if fallback_content.blank? && response['whatsapp'].present?
      fallback_content = extract_whatsapp_text(response['whatsapp'])
    end
    
    # Try Instagram content
    if fallback_content.blank? && response['instagram'].present?
      instagram_payload = response['instagram']
      fallback_content = case instagram_payload['message_format']
                        when 'QUICK_REPLIES', 'BUTTON_TEMPLATE'
                          instagram_payload['text']
                        when 'GENERIC_TEMPLATE'
                          instagram_payload.dig('elements', 0, 'title')
                        else
                          'Instagram rich message'
                        end
    end
    
    # Try Facebook content
    if fallback_content.blank? && response['facebook'].present?
      fallback_content = response['facebook'].dig('message', 'text') || 'Facebook message'
    end
    
    # Try button reaction text
    if fallback_content.blank? && response['action_type'] == 'button_reaction'
      fallback_content = response['text'] || "Button reaction: #{response['emoji']}"
    end
    
    # Last resort: stringify the response
    if fallback_content.blank?
      fallback_content = "Bot response: #{response.to_s.truncate(100)}"
    end
    
    Rails.logger.info "[SOCIALWISE-FLOW] Extracted fallback content: #{fallback_content}"
    fallback_content
  rescue StandardError => e
    Rails.logger.error "[SOCIALWISE-FLOW] Fallback content extraction failed: #{e.class}: #{e.message}"
    "Response processing failed"
  end

  def build_request_payload(session_id, message_content)
    message = event_data[:message]
    conversation = message.conversation
    contact = conversation.contact
    inbox = conversation.inbox

    # Criar payload base para o WebhookEnhancerService
    webhook_payload = {
      message: message,
      conversation: conversation,
      contact: contact,
      inbox: inbox
    }

    # Obter payload enriquecido do serviço compartilhado
    enhanced = Integrations::Socialwise::WebhookEnhancerService.enhance_payload(webhook_payload, hook.account)

    # Construir payload final para SocialWise Flow
    {
      session_id: session_id,
      message: message_content,
      channel_type: inbox.channel_type,
      language: hook.settings['language'].presence || 'pt-BR',
      context: enhanced,
      metadata: {
        event_name: event_name,
        conversation_id: conversation.id,
        message_id: message.id,
        account_id: conversation.account_id,
        inbox_id: inbox.id
      }
    }
  end
end