# lib/integrations/socialwise_flow/processor_service.rb

class Integrations::SocialwiseFlow::ProcessorService < Integrations::BotProcessorService
  pattr_initialize [:event_name!, :hook!, :event_data!]

  # Override perform to add debounce logic
  def perform
    Rails.logger.info '[SOCIALWISE-FLOW] === ProcessorService.perform called ==='
    message = event_data[:message]
    Rails.logger.info "[SOCIALWISE-FLOW] Processing message ID: #{message&.id}"
    Rails.logger.info "[SOCIALWISE-FLOW] Hook ID: #{hook&.id}"
    Rails.logger.info "[SOCIALWISE-FLOW] Hook settings: #{hook&.settings&.except('access_token')}"

    unless should_run_processor?(message)
      Rails.logger.info '[SOCIALWISE-FLOW] should_run_processor? returned false, aborting'
      return
    end

    Rails.logger.info '[SOCIALWISE-FLOW] should_run_processor? returned true, continuing'

    # Check if this is an interactive reply (button click or list selection)
    # Interactive replies should ALWAYS be processed immediately, never debounced
    if interactive_reply?(message)
      Rails.logger.info '[SOCIALWISE-FLOW] Interactive reply detected (button/list click) - processing immediately, skipping debounce'
      process_content(message)
      Rails.logger.info '[SOCIALWISE-FLOW] === ProcessorService.perform completed (immediate - interactive reply) ==='
      return
    end

    # Check if debounce is enabled for regular text messages
    debounce_ms = debounce_duration_ms
    Rails.logger.info "[SOCIALWISE-FLOW] Debounce MS: #{debounce_ms}"

    if debounce_ms.positive?
      Rails.logger.info '[SOCIALWISE-FLOW] Debounce enabled, enqueueing for debounce'
      enqueue_for_debounce(message, debounce_ms)
    else
      # No debounce, process immediately
      Rails.logger.info '[SOCIALWISE-FLOW] No debounce, processing immediately'
      process_content(message)
    end
    Rails.logger.info '[SOCIALWISE-FLOW] === ProcessorService.perform completed ==='
  rescue StandardError => e
    Rails.logger.error "[SOCIALWISE-FLOW] ProcessorService.perform ERROR: #{e.class}: #{e.message}"
    Rails.logger.error "[SOCIALWISE-FLOW] Backtrace: #{e.backtrace.first(5).join('\n')}"
    ChatwootExceptionTracker.new(e, account: hook&.account).capture_exception
  end

  private

  # Check if the message is an interactive reply (button click or list selection)
  # These should be processed immediately without debounce because:
  # 1. Button clicks are deliberate user actions that expect immediate response
  # 2. There's no need to wait for more messages after a button click
  # 3. The interaction context (button_id) needs to be sent immediately
  def interactive_reply?(message)
    content_attrs = message.content_attributes
    return false if content_attrs.blank?

    # Check for button_reply or list_reply in content_attributes
    # These are set by extract_interactive_data in incoming_message_base_service.rb
    has_button_reply = content_attrs['button_reply'].present? || content_attrs[:button_reply].present?
    has_list_reply = content_attrs['list_reply'].present? || content_attrs[:list_reply].present?

    is_interactive = has_button_reply || has_list_reply

    if is_interactive
      interaction_type = content_attrs['interaction_type'] || content_attrs[:interaction_type]
      Rails.logger.info "[SOCIALWISE-FLOW] Detected interactive reply: type=#{interaction_type}"
    end

    is_interactive
  end

  # Get debounce duration from ENV variable (default: 0 = disabled)
  def debounce_duration_ms
    ENV.fetch('SOCIALWISE_DEBOUNCE_MS', '0').to_i
  end

  # Get max timeout from ENV variable (default: 30000ms = 30s)
  def debounce_max_timeout_ms
    ENV.fetch('SOCIALWISE_DEBOUNCE_MAX_MS', '30000').to_i
  end

  # Enqueue message for debounced processing with reset timer logic
  # Each new message resets the timer, but there's a max timeout to prevent infinite wait
  def enqueue_for_debounce(message, debounce_ms)
    conversation = message.conversation
    content = message_content(message)

    return if content.blank?

    current_time = Time.current.to_f

    Rails.logger.info "[SOCIALWISE-DEBOUNCE] Enqueueing message #{message.id} for debounce (#{debounce_ms}ms)"

    # Redis keys
    messages_key = format(Redis::Alfred::SOCIALWISE_DEBOUNCE_MESSAGES, conversation_id: conversation.id)
    first_at_key = format(Redis::Alfred::SOCIALWISE_DEBOUNCE_FIRST_AT, conversation_id: conversation.id)
    last_at_key = format(Redis::Alfred::SOCIALWISE_DEBOUNCE_LAST_AT, conversation_id: conversation.id)

    # Store message content
    message_data = {
      message_id: message.id,
      content: content,
      timestamp: current_time
    }.to_json

    Redis::Alfred.lpush(messages_key, message_data)

    # Set first_at only if it doesn't exist (first message in the window)
    first_at = Redis::Alfred.get(first_at_key)
    if first_at.blank?
      Redis::Alfred.set(first_at_key, current_time.to_s)
      Rails.logger.info "[SOCIALWISE-DEBOUNCE] First message at #{current_time} - starting debounce window"
    end

    # Always update last_at (reset the timer)
    Redis::Alfred.set(last_at_key, current_time.to_s)
    Rails.logger.info "[SOCIALWISE-DEBOUNCE] Last message at #{current_time} - timer reset"

    # Set expiry on all keys (max timeout + buffer)
    max_timeout_ms = debounce_max_timeout_ms
    expiry_seconds = ((max_timeout_ms / 1000.0) * 1.5).ceil + 60
    $alfred.with do |conn|
      conn.expire(messages_key, expiry_seconds)
      conn.expire(first_at_key, expiry_seconds)
      conn.expire(last_at_key, expiry_seconds)
    end

    # Schedule the debounce job
    # The job will check if enough silence has passed OR if max timeout reached
    SocialwiseDebounceJob.set(wait: (debounce_ms / 1000.0).seconds).perform_later(
      conversation.id,
      hook.id,
      event_name,
      debounce_ms,
      max_timeout_ms
    )

    Rails.logger.info "[SOCIALWISE-DEBOUNCE] Message #{message.id} enqueued, job scheduled in #{debounce_ms}ms (max timeout: #{max_timeout_ms}ms)"
  end

  # Expose should_run_processor? and process_content for use by DebounceProcessorService
  def should_run_processor?(message)
    Rails.logger.info '[SOCIALWISE-FLOW] === CHECKING SHOULD_RUN_PROCESSOR ==='
    Rails.logger.info "[SOCIALWISE-FLOW] Message ID: #{message.id}"
    Rails.logger.info "[SOCIALWISE-FLOW] Message private?: #{message.private?}"
    Rails.logger.info "[SOCIALWISE-FLOW] Message reportable?: #{message.reportable?}"
    Rails.logger.info "[SOCIALWISE-FLOW] Message outgoing?: #{message.outgoing?}"
    Rails.logger.info "[SOCIALWISE-FLOW] Message content_type: #{message.content_type}"
    Rails.logger.info "[SOCIALWISE-FLOW] Conversation ID: #{message.conversation&.id}"
    Rails.logger.info "[SOCIALWISE-FLOW] Conversation status: #{message.conversation&.status}"
    Rails.logger.info "[SOCIALWISE-FLOW] Event name: #{event_name}"

    if message.private?
      Rails.logger.info '[SOCIALWISE-FLOW] BLOCKED: Message is private'
      return
    end

    unless processable_message?(message)
      Rails.logger.info '[SOCIALWISE-FLOW] BLOCKED: Message is not processable'
      return
    end

    # Accept pending OR open conversations without agent replies
    # This allows the bot to respond to auto-assigned conversations
    unless bot_should_respond?
      Rails.logger.info "[SOCIALWISE-FLOW] BLOCKED: Bot should not respond (status: #{conversation.status}, has_agent_reply: #{has_agent_reply?})"
      return
    end

    Rails.logger.info '[SOCIALWISE-FLOW] PASSED: All checks passed, will process message'
    true
  end

  # Check if bot should respond to this conversation
  # Returns true if:
  # - Conversation is pending (original behavior, ignores handoff flag as it's a new/reopened conversation)
  # - Conversation is open but has NO agent replies yet AND no handoff has occurred
  def bot_should_respond?
    Rails.logger.info "[SOCIALWISE-FLOW] Checking bot_should_respond: status=#{conversation.status}, has_agent_reply=#{has_agent_reply?}, handoff_completed=#{handoff_completed?}"

    # Pending conversations always get bot responses (new or reopened conversations)
    return true if conversation.pending?

    # Open conversations only get bot responses if:
    # 1. No human agent has replied yet, AND
    # 2. No handoff action has been executed
    return true if conversation.open? && !has_agent_reply? && !handoff_completed?

    false
  end

  # Check if handoff has been completed for this conversation
  # This flag is set when process_action receives 'handoff' action
  def handoff_completed?
    conversation.additional_attributes&.dig('socialwise_handoff_at').present?
  end

  # Check if conversation has any outgoing messages from agents (not from bot)
  def has_agent_reply?
    # Check for outgoing messages that are NOT from the bot (have a sender that is a User)
    conversation.messages.outgoing.where(sender_type: 'User').exists?
  end

  # Override process_action to mark handoff in additional_attributes
  # This ensures bot stops responding after handoff even if no human has replied yet
  def process_action(message, action)
    Rails.logger.info "[SOCIALWISE-FLOW] Processing action: #{action}"

    case action
    when 'handoff'
      Rails.logger.info '[SOCIALWISE-FLOW] Executing handoff action'

      # Mark handoff in additional_attributes BEFORE calling bot_handoff!
      # This ensures the flag is set even if bot_handoff! fails
      mark_handoff_completed(message.conversation)

      # Call native bot_handoff! which changes status to open and dispatches event
      message.conversation.bot_handoff!

      Rails.logger.info "[SOCIALWISE-FLOW] Handoff completed - conversation status: #{message.conversation.reload.status}"
    when 'resolve'
      Rails.logger.info '[SOCIALWISE-FLOW] Executing resolve action'

      # Clear handoff flag when resolving (allows bot to work if conversation reopens)
      clear_handoff_flag(message.conversation)

      message.conversation.resolved!

      Rails.logger.info "[SOCIALWISE-FLOW] Resolve completed - conversation status: #{message.conversation.reload.status}"
    else
      Rails.logger.warn "[SOCIALWISE-FLOW] Unknown action: #{action}"
    end
  end

  # Mark that handoff has been completed for this conversation
  # Uses additional_attributes to avoid affecting SLA metrics (first_reply_created_at)
  def mark_handoff_completed(conv)
    Rails.logger.info "[SOCIALWISE-FLOW] Marking handoff completed for conversation #{conv.id}"

    current_attrs = conv.additional_attributes || {}
    updated_attrs = current_attrs.merge(
      'socialwise_handoff_at' => Time.current.iso8601,
      'socialwise_handoff_by' => 'bot'
    )

    conv.update!(additional_attributes: updated_attrs)

    Rails.logger.info "[SOCIALWISE-FLOW] Handoff flag set: socialwise_handoff_at=#{updated_attrs['socialwise_handoff_at']}"
  end

  # Clear handoff flag when conversation is resolved
  # This allows bot to work again if conversation is reopened in the future
  def clear_handoff_flag(conv)
    Rails.logger.info "[SOCIALWISE-FLOW] Clearing handoff flag for conversation #{conv.id}"

    current_attrs = conv.additional_attributes || {}

    # Only update if flag exists
    return unless current_attrs['socialwise_handoff_at'].present?

    updated_attrs = current_attrs.except('socialwise_handoff_at', 'socialwise_handoff_by')
    conv.update!(additional_attributes: updated_attrs)

    Rails.logger.info '[SOCIALWISE-FLOW] Handoff flag cleared'
  end

  def conversation
    message = event_data[:message]
    @conversation ||= message.conversation
  end

  def process_content(message)
    content = message_content(message)
    response = get_response(conversation.contact_inbox.source_id, content) if content.present?
    process_response(message, response) if response.present?
  end

  def processable_message?(message)
    return unless message.reportable?
    return if message.outgoing? && !processable_outgoing_message?(message)

    true
  end

  def processable_outgoing_message?(message)
    event_name == 'message.updated' && ['input_select'].include?(message.content_type)
  end

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
      Rails.logger.info '[SOCIALWISE-FLOW] === SENDING REQUEST TO SOCIALWISE FLOW ==='
      Rails.logger.info "[SOCIALWISE-FLOW] URL: #{url}"
      Rails.logger.info "[SOCIALWISE-FLOW] HEADERS: #{log_headers.inspect}"
      Rails.logger.info "[SOCIALWISE-FLOW] PAYLOAD: #{payload.inspect}"
      Rails.logger.info '[SOCIALWISE-FLOW] === END REQUEST ==='
    rescue StandardError => e
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
    Rails.logger.info '[SOCIALWISE-FLOW] === PROCESSING RESPONSE ==='
    Rails.logger.info "[SOCIALWISE-FLOW] Message ID: #{message.id}, Conversation ID: #{message.conversation.id}"
    Rails.logger.info "[SOCIALWISE-FLOW] Account ID: #{message.conversation.account_id}, Inbox ID: #{message.conversation.inbox_id}"
    Rails.logger.info "[SOCIALWISE-FLOW] Channel type: #{message.conversation.inbox.channel_type}"
    Rails.logger.info "[SOCIALWISE-FLOW] Response: #{response.inspect}"

    # Requirement 6.1: Log detailed error information when response is blank
    if response.blank?
      Rails.logger.warn '[SOCIALWISE-FLOW] Empty or nil response received'
      Rails.logger.warn "[SOCIALWISE-FLOW] Message content: #{message.content}"
      Rails.logger.warn "[SOCIALWISE-FLOW] Hook settings: #{hook.settings.inspect}"
      return
    end

    begin
      # Primeiro, processar button_reaction se existir
      if response['action_type'] == 'button_reaction'
        Rails.logger.info '[SOCIALWISE-FLOW] Processing button_reaction'
        process_button_reaction(message, response)
        return
      end

      # Processar ação padrão (handoff, resolve)
      if response['action'].present?
        Rails.logger.info "[SOCIALWISE-FLOW] Processing action: #{response['action']}"
        begin
          process_action(message, response['action'])
          Rails.logger.info "[SOCIALWISE-FLOW] Action processed successfully: #{response['action']}"
        rescue StandardError => e
          # Requirement 6.3: Log handoff action failures but don't block message processing
          Rails.logger.error "[SOCIALWISE-FLOW] Action processing failed: #{e.class}: #{e.message}"
          Rails.logger.error "[SOCIALWISE-FLOW] Action: #{response['action']}"
          Rails.logger.error "[SOCIALWISE-FLOW] Message ID: #{message.id}"
          Rails.logger.error "[SOCIALWISE-FLOW] Backtrace: #{e.backtrace.first(3).join('\n')}"
          # Continue processing messages even if action fails
        end
        # Não retornar aqui, pode haver mensagem também
      end

      # Rotear por canal
      channel_type = message.conversation.inbox.channel_type
      Rails.logger.info "[SOCIALWISE-FLOW] Channel type: #{channel_type}"

      # Primeiro verificar se é resposta simples com apenas texto
      if response['text'].present? && !has_rich_content?(response)
        Rails.logger.info "[SOCIALWISE-FLOW] Simple text response detected for all channels: #{response['text']}"
        create_conversation(message, { content: response['text'] })
        return
      end

      case channel_type
      when 'Channel::Whatsapp'
        mapped_whatsapp = response.dig('mapped', 'whatsapp')
        if mapped_whatsapp.present?
          Rails.logger.info '[SOCIALWISE-FLOW] Detected mapped.whatsapp payload; delegating to WhatsappResponseProcessor'
          process_whatsapp_response(message, mapped_whatsapp)
        elsif response['whatsapp'].present?
          process_whatsapp_response(message, response['whatsapp'])
        elsif response['text'].present?
          Rails.logger.info '[SOCIALWISE-FLOW] WhatsApp channel with simple text response'
          create_conversation(message, { content: response['text'] })
        else
          Rails.logger.warn '[SOCIALWISE-FLOW] WhatsApp channel but no whatsapp payload in response'
        end
      when 'Channel::FacebookPage', 'Channel::Instagram'
        # Instagram pode usar Channel::FacebookPage ou Channel::Instagram
        mapped_instagram = response.dig('mapped', 'instagram')
        mapped_facebook = response.dig('mapped', 'facebook')
        if mapped_instagram.present?
          Rails.logger.info '[SOCIALWISE-FLOW] Detected mapped.instagram payload; delegating to Instagram processor'
          process_instagram_response(message, mapped_instagram)
        elsif mapped_facebook.present?
          Rails.logger.info '[SOCIALWISE-FLOW] Detected mapped.facebook payload; delegating to Facebook processor'
          process_facebook_response(message, mapped_facebook)
        elsif response['instagram'].present?
          process_instagram_response(message, response['instagram'])
        elsif response['facebook'].present?
          process_facebook_response(message, response['facebook'])
        elsif response['text'].present?
          Rails.logger.info '[SOCIALWISE-FLOW] Instagram/FacebookPage channel with simple text response'
          create_conversation(message, { content: response['text'] })
        else
          Rails.logger.warn '[SOCIALWISE-FLOW] Instagram/FacebookPage channel but no instagram/facebook payload in response'
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

      Rails.logger.info '[SOCIALWISE-FLOW] === RESPONSE PROCESSING COMPLETED ==='

    rescue StandardError => e
      # Requirement 6.1: Log detailed error information
      Rails.logger.error '[SOCIALWISE-FLOW] === RESPONSE PROCESSING FAILED ==='
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
          create_conversation(message, { content: 'Erro ao processar resposta do bot' })
          Rails.logger.info '[SOCIALWISE-FLOW] Created simple error message as last resort'
        rescue StandardError => last_resort_error
          Rails.logger.error "[SOCIALWISE-FLOW] Even simple error message creation failed: #{last_resort_error.class}: #{last_resort_error.message}"
        end
      end
    end
  end

  def process_button_reaction(message, response)
    Rails.logger.info '[SOCIALWISE-FLOW] === PROCESSING BUTTON REACTION ==='
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
      Rails.logger.warn '[SOCIALWISE-FLOW] Button reaction missing buttonId' if response['buttonId'].blank?

      begin
        # 1. Send emoji reaction based on channel type (Requirements 3.2, 3.3)
        if response['emoji'].present?
          Rails.logger.info "[SOCIALWISE-FLOW] Sending emoji reaction: #{response['emoji']}"
          send_emoji_reaction(message, response, channel_type)
          Rails.logger.info '[SOCIALWISE-FLOW] Emoji reaction sent successfully'
        else
          Rails.logger.warn '[SOCIALWISE-FLOW] No emoji in button reaction response'
        end

      rescue StandardError => e
        # Requirement 6.2: Continue processing other response elements when emoji reaction fails
        Rails.logger.error "[SOCIALWISE-FLOW] Emoji reaction sending failed: #{e.class}: #{e.message}"
        Rails.logger.error "[SOCIALWISE-FLOW] Emoji: #{response['emoji']}"
        Rails.logger.error "[SOCIALWISE-FLOW] Channel type: #{channel_type}"
        Rails.logger.error "[SOCIALWISE-FLOW] Backtrace: #{e.backtrace.first(3).join('\n')}"
        # Continue processing even if emoji reaction fails (Requirement 3.4)
      end

      begin
        # 2. Send contextual response text (Requirements 3.2, 3.3)
        if response['text'].present?
          Rails.logger.info "[SOCIALWISE-FLOW] Sending reaction text: #{response['text']}"
          send_reaction_text(message, response, channel_type)
          Rails.logger.info '[SOCIALWISE-FLOW] Reaction text sent successfully'
        else
          Rails.logger.warn '[SOCIALWISE-FLOW] No text in button reaction response'
        end

      rescue StandardError => e
        # Requirement 6.2: Continue processing other response elements when text sending fails
        Rails.logger.error "[SOCIALWISE-FLOW] Reaction text sending failed: #{e.class}: #{e.message}"
        Rails.logger.error "[SOCIALWISE-FLOW] Text: #{response['text']}"
        Rails.logger.error "[SOCIALWISE-FLOW] Channel type: #{channel_type}"
        Rails.logger.error "[SOCIALWISE-FLOW] Backtrace: #{e.backtrace.first(3).join('\n')}"
        # Continue processing even if text sending fails (Requirement 3.4)
      end

      # 3. Process handoff action even if reaction sending failed (Requirements 3.4, 4.1, 4.2, 4.3, 4.4)
      if response['action'].present?
        Rails.logger.info "[SOCIALWISE-FLOW] Processing button reaction action: #{response['action']}"
        begin
          process_action(message, response['action'])
          Rails.logger.info "[SOCIALWISE-FLOW] Action processed successfully: #{response['action']}"
        rescue StandardError => e
          # Requirement 6.3: Log handoff action failures but don't block message processing
          Rails.logger.error "[SOCIALWISE-FLOW] Action processing failed: #{e.class}: #{e.message}"
          Rails.logger.error "[SOCIALWISE-FLOW] Action: #{response['action']}"
          Rails.logger.error "[SOCIALWISE-FLOW] Message ID: #{message.id}"
          Rails.logger.error "[SOCIALWISE-FLOW] Conversation ID: #{conversation.id}"
          Rails.logger.error "[SOCIALWISE-FLOW] Backtrace: #{e.backtrace.first(5).join('\n')}"
          # Log error but don't re-raise (Requirement 6.3)
        end
      else
        Rails.logger.info '[SOCIALWISE-FLOW] No action specified in button reaction'
      end

      # 4. Process mapped payloads (WhatsApp/Instagram/Facebook) if present
      begin
        if response['mapped'].is_a?(Hash)
          Rails.logger.info '[SOCIALWISE-FLOW] Mapped payload detected inside button_reaction'
          case channel_type
          when 'Channel::Whatsapp'
            if response.dig('mapped', 'whatsapp').present?
              Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] Processing Interactive Message (mapped)'
              process_whatsapp_response(message, response['mapped']['whatsapp'])
            end
          when 'Channel::Instagram', 'Channel::FacebookPage'
            if response.dig('mapped', 'instagram').present?
              Rails.logger.info '[SOCIALWISE-INSTAGRAM-RICH] Processing mapped Instagram payload'
              process_instagram_response(message, response['mapped']['instagram'])
            elsif response.dig('mapped', 'facebook').present?
              Rails.logger.info '[SOCIALWISE-FLOW][FACEBOOK] Processing mapped Facebook payload'
              process_facebook_response(message, response['mapped']['facebook'])
            end
          else
            Rails.logger.warn "[SOCIALWISE-FLOW] Mapped payload present but unsupported channel: #{channel_type}"
          end
        end
      rescue StandardError => e
        Rails.logger.error "[SOCIALWISE-FLOW] Failed to process mapped payload in button_reaction: #{e.class}: #{e.message}"
        Rails.logger.error "[SOCIALWISE-FLOW] Backtrace: #{e.backtrace.first(5).join('\n')}"
      end

      Rails.logger.info '[SOCIALWISE-FLOW] === BUTTON REACTION PROCESSING COMPLETED ==='

    rescue StandardError => e
      # Requirement 6.1: Log detailed error information
      Rails.logger.error '[SOCIALWISE-FLOW] === BUTTON REACTION PROCESSING FAILED ==='
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
          Rails.logger.info '[SOCIALWISE-FLOW] Attempting handoff despite button reaction failure'
          process_action(message, response['action'])
          Rails.logger.info '[SOCIALWISE-FLOW] Handoff processed successfully despite earlier failure'
        rescue StandardError => handoff_error
          Rails.logger.error "[SOCIALWISE-FLOW] Handoff also failed: #{handoff_error.class}: #{handoff_error.message}"
          Rails.logger.error "[SOCIALWISE-FLOW] Handoff error backtrace: #{handoff_error.backtrace.first(3).join('\n')}"
        end
      end
    end
  end

  def send_emoji_reaction(message, response, channel_type)
    Rails.logger.info "[SOCIALWISE-FLOW] Sending emoji reaction for #{channel_type}"

    conversation = message.conversation
    emoji = response['emoji']

    case channel_type
    when 'Channel::Whatsapp'
      # WhatsApp: Send both emoji reaction and contextual response (Requirement 3.2)
      send_whatsapp_emoji_reaction(conversation, emoji, response)
    when 'Channel::FacebookPage'
      # Facebook: Send emoji reaction specific to Facebook
      Rails.logger.info "[SOCIALWISE-FLOW] Routing to Facebook emoji reaction handler for #{channel_type}"
      send_facebook_emoji_reaction(conversation, emoji, response)
    when 'Channel::Instagram'
      # Instagram: Send emoji reaction and simple response (Requirement 3.3)
      Rails.logger.info "[SOCIALWISE-FLOW] Routing to Instagram emoji reaction handler for #{channel_type}"
      send_instagram_emoji_reaction(conversation, emoji, response)
    else
      # Generic emoji reaction for other channels
      Rails.logger.warn "[SOCIALWISE-FLOW] Using generic emoji reaction for unsupported channel: #{channel_type}"
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
      # Facebook: Send simple response text specific to Facebook
      Rails.logger.info "[SOCIALWISE-FLOW] Routing to Facebook text reaction handler for #{channel_type}"
      send_facebook_reaction_text(conversation, text, response)
    when 'Channel::Instagram'
      # Instagram: Send simple response text (Requirement 3.3)
      Rails.logger.info "[SOCIALWISE-FLOW] Routing to Instagram text reaction handler for #{channel_type}"
      send_instagram_reaction_text(conversation, text, response)
    else
      # Generic text response for other channels
      Rails.logger.warn "[SOCIALWISE-FLOW] Using generic text reaction for unsupported channel: #{channel_type}"
      send_generic_reaction_text(conversation, text, response)
    end
  end

  def send_whatsapp_emoji_reaction(conversation, emoji, response)
    # Send emoji reaction to WhatsApp API
    begin
      whatsapp_payload = response['whatsapp']
      if whatsapp_payload && whatsapp_payload['message_id'].present?
        send_whatsapp_reaction_to_api(conversation, whatsapp_payload['message_id'], emoji)
        Rails.logger.info '[SOCIALWISE-FLOW] WhatsApp emoji reaction sent to API successfully'
      else
        Rails.logger.warn '[SOCIALWISE-FLOW] Missing WhatsApp message_id for emoji reaction'
      end
    rescue StandardError => e
      Rails.logger.error "[SOCIALWISE-FLOW] WhatsApp emoji reaction API call failed: #{e.class}: #{e.message}"
    end

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
      },
      additional_attributes: { skip_send_reply: true }
    )

    Rails.logger.info "[SOCIALWISE-FLOW] WhatsApp emoji reaction message created: #{emoji_message.id}"
  end

  def send_facebook_emoji_reaction(conversation, emoji, response)
    Rails.logger.info '[SOCIALWISE-FLOW] === FACEBOOK EMOJI REACTION START ==='
    Rails.logger.info "[SOCIALWISE-FLOW] Original emoji: #{emoji}"
    Rails.logger.info "[SOCIALWISE-FLOW] Response data: #{response.inspect}"

    # Send emoji reaction to Facebook API
    begin
      # Look for message_id in Facebook payload
      message_id = response.dig('facebook', 'message_id')

      Rails.logger.info "[SOCIALWISE-FLOW] Facebook message_id found: #{message_id}"

      if message_id.present?
        send_facebook_reaction_to_api(conversation, message_id, emoji)
        Rails.logger.info '[SOCIALWISE-FLOW] Facebook emoji reaction sent to API successfully'
      else
        Rails.logger.error '[SOCIALWISE-FLOW] CRITICAL: Missing message_id for Facebook emoji reaction'
        Rails.logger.error "[SOCIALWISE-FLOW] Available response keys: #{response.keys.inspect}"
      end
    rescue StandardError => e
      Rails.logger.error "[SOCIALWISE-FLOW] Facebook emoji reaction API call failed: #{e.class}: #{e.message}"
      Rails.logger.error "[SOCIALWISE-FLOW] Backtrace: #{e.backtrace.first(3).join('\n')}"
    end

    # Create activity message indicating emoji reaction for Facebook
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
        'channel_type' => 'facebook'
      }
    )

    Rails.logger.info "[SOCIALWISE-FLOW] Facebook emoji reaction message created: #{emoji_message.id}"
  end

  def send_instagram_emoji_reaction(conversation, emoji, response)
    Rails.logger.info '[SOCIALWISE-FLOW] === INSTAGRAM EMOJI REACTION START ==='
    Rails.logger.info "[SOCIALWISE-FLOW] Original emoji: #{emoji} -> Converting to: love"
    Rails.logger.info "[SOCIALWISE-FLOW] Response data: #{response.inspect}"

    # Send emoji reaction to Instagram API (only supports 'love')
    begin
      # Instagram only accepts 'love' as reaction
      instagram_reaction = 'love'

      # Look for message_id in various places
      message_id = response.dig('instagram', 'message_id') ||
                   response.dig('whatsapp', 'message_id') ||
                   response['message_id']

      Rails.logger.info "[SOCIALWISE-FLOW] Instagram message_id found: #{message_id}"

      if message_id.present?
        send_instagram_reaction_to_api(conversation, message_id, instagram_reaction)
        Rails.logger.info '[SOCIALWISE-FLOW] Instagram emoji reaction sent to API successfully'
      else
        Rails.logger.error '[SOCIALWISE-FLOW] CRITICAL: Missing message_id for Instagram emoji reaction'
        Rails.logger.error "[SOCIALWISE-FLOW] Available response keys: #{response.keys.inspect}"
      end
    rescue StandardError => e
      Rails.logger.error "[SOCIALWISE-FLOW] Instagram emoji reaction API call failed: #{e.class}: #{e.message}"
      Rails.logger.error "[SOCIALWISE-FLOW] Backtrace: #{e.backtrace.first(3).join('\n')}"
    end

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
    # Send contextual text to WhatsApp API
    response_message_id = nil

    begin
      whatsapp_payload = response['whatsapp']
      if whatsapp_payload && whatsapp_payload['message_id'].present?
        api_response = send_whatsapp_contextual_message_to_api(
          conversation,
          whatsapp_payload['message_id'],
          text
        )

        parsed_response = api_response&.parsed_response
        response_message_id = Array(parsed_response && parsed_response['messages']).first&.dig('id')

        if response_message_id.present?
          Rails.logger.info "[SOCIALWISE-FLOW] WhatsApp contextual text sent successfully, source_id: #{response_message_id}"
        else
          Rails.logger.warn '[SOCIALWISE-FLOW] WhatsApp contextual text sent but no message_id returned'
        end
      else
        Rails.logger.warn '[SOCIALWISE-FLOW] Missing WhatsApp message_id for contextual text'
      end
    rescue StandardError => e
      Rails.logger.error "[SOCIALWISE-FLOW] WhatsApp contextual text API call failed: #{e.class}: #{e.message}"
    end

    # WhatsApp contextual response text
    text_message = conversation.messages.create!(
      message_type: :outgoing,
      content: text,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      source_id: response_message_id,
      content_attributes: {
        'button_reaction_response' => true,
        'button_id' => response['buttonId'],
        'channel_type' => 'whatsapp'
      },
      additional_attributes: { skip_send_reply: true }
    )

    Rails.logger.info "[SOCIALWISE-FLOW] WhatsApp reaction text message created: #{text_message.id}, source_id stored: #{response_message_id.presence || 'none'}"
  end

  def send_facebook_reaction_text(conversation, text, response)
    # Send simple text message to Facebook API
    begin
      send_facebook_text_message_to_api(conversation, text)
      Rails.logger.info '[SOCIALWISE-FLOW] Facebook text message sent to API successfully'
    rescue StandardError => e
      Rails.logger.error "[SOCIALWISE-FLOW] Facebook text message API call failed: #{e.class}: #{e.message}"
    end

    # Facebook simple response text
    text_message = conversation.messages.create!(
      message_type: :outgoing,
      content: text,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content_attributes: {
        'button_reaction_response' => true,
        'button_id' => response['buttonId'],
        'channel_type' => 'facebook'
      },
      additional_attributes: { skip_send_reply: true }
    )

    Rails.logger.info "[SOCIALWISE-FLOW] Facebook reaction text message created: #{text_message.id}"
  end

  def send_instagram_reaction_text(conversation, text, response)
    # Send simple text message to Instagram API
    begin
      send_instagram_text_message_to_api(conversation, text)
      Rails.logger.info '[SOCIALWISE-FLOW] Instagram text message sent to API successfully'
    rescue StandardError => e
      Rails.logger.error "[SOCIALWISE-FLOW] Instagram text message API call failed: #{e.class}: #{e.message}"
    end

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
      },
      additional_attributes: { skip_send_reply: true }
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
    Rails.logger.info '[SOCIALWISE-FLOW] Creating conversation message'
    Rails.logger.info "[SOCIALWISE-FLOW] Content params: #{content_params.inspect}"

    if content_params.blank?
      Rails.logger.warn '[SOCIALWISE-FLOW] Blank content_params provided to create_conversation'
      return
    end

    begin
      conversation = message.conversation

      # Validate required fields
      if conversation.account_id.blank?
        Rails.logger.error '[SOCIALWISE-FLOW] Missing account_id in conversation'
        return
      end

      if conversation.inbox_id.blank?
        Rails.logger.error '[SOCIALWISE-FLOW] Missing inbox_id in conversation'
        return
      end

      # Ensure content is present
      if content_params[:content].blank? && content_params['content'].blank?
        Rails.logger.warn '[SOCIALWISE-FLOW] No content in content_params, adding default'
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
      Rails.logger.error '[SOCIALWISE-FLOW] === MESSAGE CREATION FAILED ==='
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
        Rails.logger.info '[SOCIALWISE-FLOW] Attempting minimal fallback message creation'
        fallback_message = message.conversation.messages.create!(
          message_type: :outgoing,
          content: 'Message creation failed',
          account_id: message.conversation.account_id,
          inbox_id: message.conversation.inbox_id,
          additional_attributes: { skip_send_reply: true }
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
    Rails.logger.info '[SOCIALWISE-FLOW] === PROCESSING WHATSAPP RESPONSE ==='
    Rails.logger.info '[SOCIALWISE-FLOW] Delegating to WhatsappResponseProcessor'
    Rails.logger.info "[SOCIALWISE-FLOW] WhatsApp payload: #{whatsapp_payload.inspect}"

    # Requirement 6.1: Log detailed error information when payload is blank
    if whatsapp_payload.blank?
      Rails.logger.warn '[SOCIALWISE-FLOW][WHATSAPP] Empty or nil WhatsApp payload received'
      Rails.logger.warn "[SOCIALWISE-FLOW][WHATSAPP] Message ID: #{message.id}"
      Rails.logger.warn "[SOCIALWISE-FLOW][WHATSAPP] Conversation ID: #{message.conversation.id}"
      return
    end

    begin
      # Delegate to dedicated WhatsApp processor
      success = Integrations::SocialwiseFlow::WhatsappResponseProcessor.process(whatsapp_payload, message)

      if success
        Rails.logger.info '[SOCIALWISE-FLOW][WHATSAPP] WhatsApp response processed successfully by WhatsappResponseProcessor'
      else
        # Requirement 6.2: Continue processing other response elements when WhatsApp processing fails
        Rails.logger.warn '[SOCIALWISE-FLOW][WHATSAPP] WhatsApp response processing returned false, creating fallback message'

        # Fallback: criar mensagem de texto simples
        fallback_text = extract_whatsapp_text(whatsapp_payload) || 'WhatsApp message processing failed'
        create_conversation(message, { content: fallback_text })
        Rails.logger.info "[SOCIALWISE-FLOW][WHATSAPP] Created fallback message: #{fallback_text}"
      end

      Rails.logger.info '[SOCIALWISE-FLOW][WHATSAPP] === WHATSAPP PROCESSING COMPLETED ==='

    rescue StandardError => e
      # Requirement 6.1: Log detailed error information
      Rails.logger.error '[SOCIALWISE-FLOW][WHATSAPP] === WHATSAPP PROCESSING FAILED ==='
      Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Exception class: #{e.class}"
      Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Exception message: #{e.message}"
      Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Message ID: #{message.id}"
      Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Conversation ID: #{message.conversation.id}"
      Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] WhatsApp payload: #{whatsapp_payload.inspect}"
      Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Backtrace: #{e.backtrace.first(10).join('\n')}"

      # Requirement 6.4: Create fallback text message when processing fails
      begin
        fallback_text = extract_whatsapp_text(whatsapp_payload) || 'WhatsApp message processing failed'
        create_conversation(message, { content: fallback_text })
        Rails.logger.info "[SOCIALWISE-FLOW][WHATSAPP] Created fallback message: #{fallback_text}"
      rescue StandardError => fallback_error
        Rails.logger.error "[SOCIALWISE-FLOW][WHATSAPP] Fallback message creation failed: #{fallback_error.class}: #{fallback_error.message}"
      end
    end
  end

  # ===== Instagram =====
  def process_instagram_response(message, instagram_payload)
    Rails.logger.info '[SOCIALWISE-FLOW] === PROCESSING INSTAGRAM RESPONSE ==='
    Rails.logger.info "[SOCIALWISE-FLOW] Instagram payload: #{instagram_payload.inspect}"

    # Requirement 6.1: Log detailed error information when payload is blank
    if instagram_payload.blank?
      Rails.logger.warn '[SOCIALWISE-FLOW][INSTAGRAM] Empty or nil Instagram payload received'
      Rails.logger.warn "[SOCIALWISE-FLOW][INSTAGRAM] Message ID: #{message.id}"
      Rails.logger.warn "[SOCIALWISE-FLOW][INSTAGRAM] Conversation ID: #{message.conversation.id}"
      return
    end

    begin
      conversation = message.conversation

      # Verificar se é canal Instagram (FacebookPage ou Instagram)
      valid_instagram_channels = ['Channel::FacebookPage', 'Channel::Instagram']
      unless valid_instagram_channels.include?(conversation.inbox.channel_type)
        Rails.logger.error '[SOCIALWISE-FLOW][INSTAGRAM] Instagram response received but channel is not Instagram compatible'
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Expected: #{valid_instagram_channels.join(' or ')}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Actual channel type: #{conversation.inbox.channel_type}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Message ID: #{message.id}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Conversation ID: #{conversation.id}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Inbox ID: #{conversation.inbox.id}"
        return
      end

      Rails.logger.info '[SOCIALWISE-FLOW][INSTAGRAM] Channel validation passed, processing with InstagramResponseProcessor'

      # CORREÇÃO: Reestruturar payload do SocialWise Flow para formato esperado pelo InstagramResponseProcessor
      normalized_payload = normalize_socialwise_flow_instagram_payload(instagram_payload)

      if normalized_payload.nil?
        Rails.logger.error '[SOCIALWISE-FLOW][INSTAGRAM] Failed to normalize Instagram payload structure'
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Original payload: #{instagram_payload.inspect}"
        create_fallback_instagram_message(message, instagram_payload)
        return
      end

      Rails.logger.info '[SOCIALWISE-FLOW][INSTAGRAM] Payload normalized successfully'
      Rails.logger.info "[SOCIALWISE-FLOW][INSTAGRAM] Normalized payload: #{normalized_payload.inspect}"

      # Usar o InstagramResponseProcessor do Socialwise (mesmo usado pelo Dialogflow)
      begin
        success = Integrations::Socialwise::InstagramResponseProcessor.process(normalized_payload, message)

        if success
          Rails.logger.info '[SOCIALWISE-FLOW][INSTAGRAM] Instagram response processed successfully by InstagramResponseProcessor'
        else
          # Requirement 6.2: Continue processing other response elements when rich message sending fails
          Rails.logger.warn '[SOCIALWISE-FLOW][INSTAGRAM] Instagram response processing returned false, creating fallback message'
          Rails.logger.warn "[SOCIALWISE-FLOW][INSTAGRAM] Message format: #{instagram_payload['message_format']}"
          Rails.logger.warn "[SOCIALWISE-FLOW][INSTAGRAM] Template type: #{instagram_payload['template_type']}"

          # Fallback: criar mensagem de texto simples
          create_fallback_instagram_message(message, instagram_payload)
        end

      rescue StandardError => e
        # Requirement 6.1: Log detailed error information
        Rails.logger.error '[SOCIALWISE-FLOW][INSTAGRAM] === INSTAGRAM PROCESSOR EXCEPTION ==='
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Exception class: #{e.class}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Exception message: #{e.message}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Message ID: #{message.id}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Conversation ID: #{conversation.id}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Account ID: #{conversation.account_id}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Inbox ID: #{conversation.inbox_id}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Instagram payload: #{instagram_payload.inspect}"
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Backtrace: #{e.backtrace.first(10).join('\n')}"

        # Requirement 6.4: Create fallback text message when processing fails
        create_fallback_instagram_message(message, instagram_payload)
      end

      Rails.logger.info '[SOCIALWISE-FLOW][INSTAGRAM] === INSTAGRAM PROCESSING COMPLETED ==='

    rescue StandardError => e
      # Requirement 6.1: Log detailed error information
      Rails.logger.error '[SOCIALWISE-FLOW][INSTAGRAM] === INSTAGRAM PROCESSING FAILED ==='
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
        Rails.logger.info '[SOCIALWISE-FLOW][INSTAGRAM] Created fallback message after processing failure'
      rescue StandardError => fallback_error
        Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Fallback message creation failed: #{fallback_error.class}: #{fallback_error.message}"
      end
    end
  end

  # ===== Facebook =====
  def process_facebook_response(message, facebook_payload)
    Rails.logger.info '[SOCIALWISE-FLOW] === PROCESSING FACEBOOK RESPONSE ==='
    Rails.logger.info "[SOCIALWISE-FLOW] Facebook payload: #{facebook_payload.inspect}"

    # Requirement 6.1: Log detailed error information when payload is blank
    if facebook_payload.blank?
      Rails.logger.warn '[SOCIALWISE-FLOW][FACEBOOK] Empty or nil Facebook payload received'
      Rails.logger.warn "[SOCIALWISE-FLOW][FACEBOOK] Message ID: #{message.id}"
      Rails.logger.warn "[SOCIALWISE-FLOW][FACEBOOK] Conversation ID: #{message.conversation.id}"
      return
    end

    begin
      conversation = message.conversation

      # Extract text content for dashboard display
      text_content = facebook_payload.dig('message', 'text') || facebook_payload['text'] || 'Facebook message'
      Rails.logger.info "[SOCIALWISE-FLOW][FACEBOOK] Extracted text content: #{text_content}"

      # Determine if this is rich content or simple text (supports Messenger or direct SocialWise format)
      mapping_payload = build_facebook_mapping_payload_for_cards(facebook_payload)
      has_rich_content = mapping_payload.present?
      Rails.logger.info "[SOCIALWISE-FLOW][FACEBOOK] Has rich content: #{has_rich_content}"
      Rails.logger.info "[SOCIALWISE-FLOW][FACEBOOK] Rich mapping payload: #{mapping_payload.inspect}" if has_rich_content

      # Create message for dashboard display (Requirement 7.1, 7.2)
      outgoing_message = nil
      begin
        content_params = {
          message_type: :outgoing,
          content: text_content,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id,
          # Avoid duplicate sending via SendReplyJob; we explicitly send below
          additional_attributes: { skip_send_reply: true }
        }

        if has_rich_content
          # Map rich payload to dashboard 'cards' just like Instagram
          Rails.logger.info '[SOCIALWISE-FLOW][FACEBOOK] Mapping payload to dashboard cards'
          mapped_result = Messages::InstagramRendererMapper.map(mapping_payload)
          # Ensure a visible title in the first card for Button/QuickReplies
          begin
            items = Array(mapped_result.content_attributes['items'])
            if items.any?
              items.first['title'] = text_content.to_s.truncate(120) if items.first['title'].blank?
              # persist adjusted items
              mapped_content_attributes = mapped_result.content_attributes.merge('items' => items)
            else
              mapped_content_attributes = mapped_result.content_attributes
            end
          rescue StandardError => _e
            mapped_content_attributes = mapped_result.content_attributes
          end

          content_params[:content] = mapped_result.fallback_text
          content_params[:content_type] = mapped_result.content_type # 'cards'
          content_params[:content_attributes] = mapped_content_attributes
        else
          # Simple text message
          content_params[:content_type] = 'text'
        end

        outgoing_message = conversation.messages.create!(content_params)
        Rails.logger.info "[SOCIALWISE-FLOW][FACEBOOK] Message created: #{outgoing_message.id} (content_type: #{outgoing_message.content_type})"

      rescue StandardError => e
        # Requirement 6.2: Continue processing even if message creation fails
        Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Message creation failed: #{e.class}: #{e.message}"
        Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Text content: #{text_content}"
        Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Has rich content: #{has_rich_content}"
        Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Backtrace: #{e.backtrace.first(3).join('\n')}"

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
          # Prepare payload for sending: support Messenger raw or direct SocialWise format
          message_for_send = build_facebook_send_message_payload(facebook_payload)
          send_payload = { 'message' => message_for_send }

          # Add recipient ID (Requirement 5.4)
          contact_source_id = conversation.contact.get_source_id(conversation.inbox.id)
          send_payload['recipient'] = { 'id' => contact_source_id }
          Rails.logger.info "[SOCIALWISE-FLOW][FACEBOOK] Added recipient ID: #{contact_source_id}"

          if has_rich_content
            # Use RawDeliverService for rich content (Requirement 5.3)
            Rails.logger.info '[SOCIALWISE-FLOW][FACEBOOK] Sending rich content via RawDeliverService'
            Facebook::RawDeliverService.new(message: outgoing_message, payload: send_payload).perform
            Rails.logger.info '[SOCIALWISE-FLOW][FACEBOOK] Rich content sent successfully'
          else
            # Use standard service for simple text (Requirement 5.2)
            Rails.logger.info '[SOCIALWISE-FLOW][FACEBOOK] Sending text message via SendOnFacebookService'
            Facebook::SendOnFacebookService.new(message: outgoing_message).perform
            Rails.logger.info '[SOCIALWISE-FLOW][FACEBOOK] Text message sent successfully'
          end

        rescue StandardError => e
          # Requirement 6.2: Log rich message sending failures but continue processing
          Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Message sending failed: #{e.class}: #{e.message}"
          Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Message ID: #{outgoing_message.id}"
          Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Has rich content: #{has_rich_content}"
          Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Contact source ID: #{begin
            conversation.contact.get_source_id(conversation.inbox.id)
          rescue StandardError
            'unknown'
          end}"
          Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Send payload: #{send_payload.inspect}"
          Rails.logger.error "[SOCIALWISE-FLOW][FACEBOOK] Backtrace: #{e.backtrace.first(5).join('\n')}"
          # Message is created in dashboard, sending failure doesn't affect that
        end
      end

      Rails.logger.info '[SOCIALWISE-FLOW][FACEBOOK] === FACEBOOK PROCESSING COMPLETED ==='

    rescue StandardError => e
      # Requirement 6.1: Log detailed error information
      Rails.logger.error '[SOCIALWISE-FLOW][FACEBOOK] === FACEBOOK PROCESSING FAILED ==='
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

  def has_rich_content?(response)
    # Verifica se a resposta contém conteúdo rico além de texto simples
    response['whatsapp'].present? ||
      response['instagram'].present? ||
      response['facebook'].present? ||
      response['action_type'] == 'button_reaction' ||
      (response['mapped'].is_a?(Hash) && (
        response['mapped']['whatsapp'].present? ||
        response['mapped']['instagram'].present? ||
        response['mapped']['facebook'].present?
      ))
  end

  # Build a payload to map into dashboard 'cards' structure, supporting Messenger or SocialWise direct format
  def build_facebook_mapping_payload_for_cards(facebook_payload)
    return nil unless facebook_payload.is_a?(Hash)

    # 1) Messenger-style nested structure
    return facebook_payload.dig('message', 'attachment', 'payload') if facebook_payload.dig('message', 'attachment', 'payload').present?

    if facebook_payload.dig('message', 'quick_replies').present?
      return {
        'text' => facebook_payload.dig('message', 'text'),
        'quick_replies' => facebook_payload.dig('message', 'quick_replies')
      }
    end

    # 2) SocialWise direct format (instagram-like)
    if facebook_payload['message_format'].present?
      case facebook_payload['message_format']
      when 'GENERIC_TEMPLATE'
        # Support single-element direct format (title/image_url/buttons)
        if facebook_payload['elements'].blank?
          element = {
            'title' => facebook_payload['title'],
            'subtitle' => facebook_payload['subtitle'],
            'image_url' => facebook_payload['image_url'],
            'buttons' => facebook_payload['buttons']
          }.compact
          return {
            'template_type' => 'generic',
            'elements' => [element]
          }
        else
          return {
            'template_type' => 'generic',
            'elements' => facebook_payload['elements']
          }
        end
      when 'BUTTON_TEMPLATE'
        return {
          'template_type' => 'button',
          'text' => facebook_payload['text'],
          'buttons' => facebook_payload['buttons']
        }
      when 'QUICK_REPLIES'
        return {
          'text' => facebook_payload['text'],
          'quick_replies' => facebook_payload['quick_replies']
        }
      end
    end

    nil
  end

  # Build the Messenger Send API 'message' payload from either nested Messenger or SocialWise direct format
  def build_facebook_send_message_payload(facebook_payload)
    # Use Messenger raw message if present
    return facebook_payload['message'] if facebook_payload['message'].is_a?(Hash)

    # Build from SocialWise direct format
    case facebook_payload['message_format']
    when 'GENERIC_TEMPLATE'
      elements = (facebook_payload['elements'].presence || [{
        'title' => facebook_payload['title'],
        'subtitle' => facebook_payload['subtitle'],
        'image_url' => facebook_payload['image_url'],
        'buttons' => facebook_payload['buttons']
      }.compact])
      {
        'attachment' => {
          'type' => 'template',
          'payload' => {
            'template_type' => 'generic',
            'elements' => elements
          }
        }
      }
    when 'BUTTON_TEMPLATE'
      {
        'attachment' => {
          'type' => 'template',
          'payload' => {
            'template_type' => 'button',
            'text' => facebook_payload['text'].to_s,
            'buttons' => facebook_payload['buttons'] || []
          }
        }
      }
    when 'QUICK_REPLIES'
      {
        'text' => facebook_payload['text'].to_s,
        'quick_replies' => facebook_payload['quick_replies'] || []
      }
    else
      # Fallback to simple text
      { 'text' => facebook_payload['text'].presence || 'Facebook message' }
    end
  end

  def extract_whatsapp_text(payload)
    # Tentar extrair texto de diferentes locais no payload
    payload.dig('interactive', 'body', 'text') ||
      payload.dig('text', 'body') ||
      payload['text'] ||
      'Mensagem interativa'
  end

  # Normaliza payload do SocialWise Flow para formato esperado pelo InstagramResponseProcessor
  def normalize_socialwise_flow_instagram_payload(instagram_payload)
    Rails.logger.info '[SOCIALWISE-FLOW][INSTAGRAM] === NORMALIZING SOCIALWISE FLOW PAYLOAD ==='
    Rails.logger.info "[SOCIALWISE-FLOW][INSTAGRAM] Original payload: #{instagram_payload.inspect}"

    begin
      # Verificar se já está no formato correto (Dialogflow)
      if instagram_payload['payload'].present? && instagram_payload['message_format'].present?
        Rails.logger.info '[SOCIALWISE-FLOW][INSTAGRAM] Payload already in Dialogflow format'
        return instagram_payload
      end

      # Verificar se é formato SocialWise Flow com estrutura aninhada
      if instagram_payload['message'].present? &&
         instagram_payload['message']['attachment'].present? &&
         instagram_payload['message']['attachment']['payload'].present?

        Rails.logger.info '[SOCIALWISE-FLOW][INSTAGRAM] Detected SocialWise Flow nested format'

        message_format = instagram_payload['message_format']
        nested_payload = instagram_payload['message']['attachment']['payload']

        normalized = {
          'message_format' => message_format,
          'payload' => nested_payload
        }

        Rails.logger.info "[SOCIALWISE-FLOW][INSTAGRAM] Normalized payload: #{normalized.inspect}"
        return normalized
      end

      # Verificar se é formato SocialWise Flow direto (sem aninhamento)
      if instagram_payload['message_format'].present?
        Rails.logger.info '[SOCIALWISE-FLOW][INSTAGRAM] Detected SocialWise Flow direct format'

        normalized = {
          'message_format' => instagram_payload['message_format'],
          'payload' => {}
        }

        # Copiar campos relevantes para o payload
        instagram_payload.each do |key, value|
          next if key == 'message_format'

          normalized['payload'][key] = value
        end

        Rails.logger.info "[SOCIALWISE-FLOW][INSTAGRAM] Normalized direct format: #{normalized.inspect}"
        return normalized
      end

      Rails.logger.error '[SOCIALWISE-FLOW][INSTAGRAM] Unknown payload format, cannot normalize'
      Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Available keys: #{instagram_payload.keys.inspect}"
      return nil

    rescue StandardError => e
      Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Payload normalization failed: #{e.class}: #{e.message}"
      Rails.logger.error "[SOCIALWISE-FLOW][INSTAGRAM] Backtrace: #{e.backtrace.first(5).join('\n')}"
      return nil
    end
  end

  def create_fallback_instagram_message(message, instagram_payload)
    Rails.logger.info '[SOCIALWISE-FLOW] Creating fallback Instagram message'
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
        Rails.logger.info '[SOCIALWISE-FLOW] Created last resort Instagram fallback message'
      rescue StandardError => last_resort_error
        Rails.logger.error "[SOCIALWISE-FLOW] Last resort Instagram fallback also failed: #{last_resort_error.class}: #{last_resort_error.message}"
      end
    end
  end

  # Helper method to extract fallback content from any response format
  def extract_fallback_content_from_response(response)
    Rails.logger.info '[SOCIALWISE-FLOW] Extracting fallback content from response'

    # Try to extract meaningful text from various response formats
    fallback_content = nil

    # Try text field first
    fallback_content = response['text'] if response['text'].present?

    # Try WhatsApp content
    fallback_content = extract_whatsapp_text(response['whatsapp']) if fallback_content.blank? && response['whatsapp'].present?

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
    fallback_content = response['facebook'].dig('message', 'text') || 'Facebook message' if fallback_content.blank? && response['facebook'].present?

    # Try button reaction text
    if fallback_content.blank? && response['action_type'] == 'button_reaction'
      fallback_content = response['text'] || "Button reaction: #{response['emoji']}"
    end

    # Last resort: stringify the response
    fallback_content = "Bot response: #{response.to_s.truncate(100)}" if fallback_content.blank?

    Rails.logger.info "[SOCIALWISE-FLOW] Extracted fallback content: #{fallback_content}"
    fallback_content
  rescue StandardError => e
    Rails.logger.error "[SOCIALWISE-FLOW] Fallback content extraction failed: #{e.class}: #{e.message}"
    'Response processing failed'
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

  # API call methods for WhatsApp reactions and messages
  def send_whatsapp_reaction_to_api(conversation, message_id, emoji)
    inbox = conversation.inbox
    contact_phone = conversation.contact.get_source_id(inbox.id)

    payload = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to: contact_phone,
      type: 'reaction',
      reaction: {
        message_id: message_id,
        emoji: emoji
      }
    }

    Rails.logger.info "[SOCIALWISE-FLOW] WhatsApp reaction payload: #{payload.inspect}"

    response = HTTParty.post(
      "#{whatsapp_api_base_url(inbox)}/#{inbox.channel.provider_config['phone_number_id']}/messages",
      headers: whatsapp_api_headers(inbox),
      body: payload.to_json
    )

    if response.success?
      Rails.logger.info "[SOCIALWISE-FLOW] WhatsApp reaction API response: #{response.parsed_response}"
    else
      Rails.logger.error "[SOCIALWISE-FLOW] WhatsApp reaction API error: #{response.code} - #{response.body}"
    end

    response
  end

  def send_whatsapp_contextual_message_to_api(conversation, reply_to_message_id, text)
    inbox = conversation.inbox
    contact_phone = conversation.contact.get_source_id(inbox.id)

    payload = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to: contact_phone,
      context: {
        message_id: reply_to_message_id
      },
      type: 'text',
      text: {
        body: text
      }
    }

    Rails.logger.info "[SOCIALWISE-FLOW] WhatsApp contextual message payload: #{payload.inspect}"

    response = HTTParty.post(
      "#{whatsapp_api_base_url(inbox)}/#{inbox.channel.provider_config['phone_number_id']}/messages",
      headers: whatsapp_api_headers(inbox),
      body: payload.to_json
    )

    if response.success?
      Rails.logger.info "[SOCIALWISE-FLOW] WhatsApp contextual message API response: #{response.parsed_response}"
    else
      Rails.logger.error "[SOCIALWISE-FLOW] WhatsApp contextual message API error: #{response.code} - #{response.body}"
    end

    response
  end

  # API call methods for Instagram reactions and messages
  def send_instagram_reaction_to_api(conversation, message_id, reaction)
    Rails.logger.info '[SOCIALWISE-FLOW] === INSTAGRAM API CALL START ==='

    inbox = conversation.inbox
    contact_source_id = conversation.contact.get_source_id(inbox.id)

    Rails.logger.info "[SOCIALWISE-FLOW] Inbox ID: #{inbox.id}, Channel type: #{inbox.channel_type}"
    Rails.logger.info "[SOCIALWISE-FLOW] Contact source ID: #{contact_source_id}"
    Rails.logger.info "[SOCIALWISE-FLOW] Instagram channel class: #{inbox.channel.class}"

    # Check if we have the required configuration
    instagram_id = inbox.channel.instagram_id.presence || 'me'
    page_access_token = channel_access_token(inbox)

    Rails.logger.info "[SOCIALWISE-FLOW] Instagram ID: #{instagram_id}"
    Rails.logger.info "[SOCIALWISE-FLOW] Has access token: #{page_access_token.present?}"

    if instagram_id.blank?
      Rails.logger.error '[SOCIALWISE-FLOW] CRITICAL: Missing instagram_id in channel'
      return
    end

    if page_access_token.blank?
      Rails.logger.error '[SOCIALWISE-FLOW] CRITICAL: Missing access_token in channel'
      return
    end

    payload = {
      recipient: {
        id: contact_source_id
      },
      sender_action: 'react',
      payload: {
        message_id: message_id,
        reaction: reaction  # 'love' for Instagram
      }
    }

    api_url = "#{instagram_api_base_url}/#{instagram_id}/messages"
    Rails.logger.info "[SOCIALWISE-FLOW] API URL: #{api_url}"
    Rails.logger.info "[SOCIALWISE-FLOW] Instagram reaction payload: #{payload.inspect}"

    response = HTTParty.post(
      api_url,
      headers: instagram_api_headers(inbox),
      body: payload.to_json
    )

    Rails.logger.info "[SOCIALWISE-FLOW] API Response Code: #{response.code}"

    if response.success?
      Rails.logger.info "[SOCIALWISE-FLOW] Instagram reaction API SUCCESS: #{response.parsed_response}"
    else
      Rails.logger.error "[SOCIALWISE-FLOW] Instagram reaction API ERROR: #{response.code} - #{response.body}"
    end

    response
  end

  def send_instagram_text_message_to_api(conversation, text)
    inbox = conversation.inbox
    contact_source_id = conversation.contact.get_source_id(inbox.id)

    payload = {
      recipient: {
        id: contact_source_id
      },
      message: {
        text: text
      }
    }

    Rails.logger.info "[SOCIALWISE-FLOW] Instagram text message payload: #{payload.inspect}"

    instagram_id = inbox.channel.instagram_id.presence || 'me'
    api_url = "#{instagram_api_base_url}/#{instagram_id}/messages"

    Rails.logger.info "[SOCIALWISE-FLOW] Instagram text API URL: #{api_url}"

    response = HTTParty.post(
      api_url,
      headers: instagram_api_headers(inbox),
      body: payload.to_json
    )

    if response.success?
      Rails.logger.info "[SOCIALWISE-FLOW] Instagram text message API response: #{response.parsed_response}"
    else
      Rails.logger.error "[SOCIALWISE-FLOW] Instagram text message API error: #{response.code} - #{response.body}"
    end

    response
  end

  # Helper methods for API configuration
  def whatsapp_api_base_url(_inbox)
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com/v23.0')
  end

  def whatsapp_api_headers(inbox)
    {
      'Authorization' => "Bearer #{inbox.channel.provider_config['api_key']}",
      'Content-Type' => 'application/json'
    }
  end

  def instagram_api_base_url
    ENV.fetch('INSTAGRAM_API_BASE_URL', 'https://graph.instagram.com/v23.0')
  end

  def instagram_api_headers(inbox)
    token = channel_access_token(inbox)
    {
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json'
    }
  end

  # API call methods for Facebook reactions and messages
  def send_facebook_reaction_to_api(conversation, _message_id, _reaction)
    Rails.logger.info '[SOCIALWISE-FLOW] === FACEBOOK API REACTION CALL START ==='

    inbox = conversation.inbox
    contact_source_id = conversation.contact.get_source_id(inbox.id)

    Rails.logger.info "[SOCIALWISE-FLOW] Facebook Inbox ID: #{inbox.id}, Channel type: #{inbox.channel_type}"
    Rails.logger.info "[SOCIALWISE-FLOW] Facebook Contact source ID: #{contact_source_id}"
    Rails.logger.info "[SOCIALWISE-FLOW] Facebook channel class: #{inbox.channel.class}"

    # Check if we have the required configuration
    page_access_token = channel_access_token(inbox)

    Rails.logger.info "[SOCIALWISE-FLOW] Facebook Has access token: #{page_access_token.present?}"

    if page_access_token.blank?
      Rails.logger.error '[SOCIALWISE-FLOW] CRITICAL: Missing access_token for Facebook channel'
      return
    end

    # Facebook Messenger uses different API format for reactions
    payload = {
      recipient: {
        id: contact_source_id
      },
      sender_action: 'mark_seen'  # Facebook doesn't have direct reaction API like Instagram
    }

    api_url = "#{facebook_api_base_url}/#{inbox.channel.page_id}/messages"
    Rails.logger.info "[SOCIALWISE-FLOW] Facebook API URL: #{api_url}"
    Rails.logger.info "[SOCIALWISE-FLOW] Facebook reaction payload: #{payload.inspect}"

    response = HTTParty.post(
      api_url,
      headers: facebook_api_headers(inbox),
      body: payload.to_json
    )

    Rails.logger.info "[SOCIALWISE-FLOW] Facebook API Response Code: #{response.code}"

    if response.success?
      Rails.logger.info "[SOCIALWISE-FLOW] Facebook reaction API SUCCESS: #{response.parsed_response}"
    else
      Rails.logger.error "[SOCIALWISE-FLOW] Facebook reaction API ERROR: #{response.code} - #{response.body}"
    end

    response
  end

  def send_facebook_text_message_to_api(conversation, text)
    inbox = conversation.inbox
    contact_source_id = conversation.contact.get_source_id(inbox.id)

    payload = {
      recipient: {
        id: contact_source_id
      },
      message: {
        text: text
      }
    }

    Rails.logger.info "[SOCIALWISE-FLOW] Facebook text message payload: #{payload.inspect}"

    api_url = "#{facebook_api_base_url}/#{inbox.channel.page_id}/messages"

    Rails.logger.info "[SOCIALWISE-FLOW] Facebook text API URL: #{api_url}"

    response = HTTParty.post(
      api_url,
      headers: facebook_api_headers(inbox),
      body: payload.to_json
    )

    if response.success?
      Rails.logger.info "[SOCIALWISE-FLOW] Facebook text message API response: #{response.parsed_response}"
    else
      Rails.logger.error "[SOCIALWISE-FLOW] Facebook text message API error: #{response.code} - #{response.body}"
    end

    response
  end

  def facebook_api_base_url
    ENV.fetch('FACEBOOK_API_BASE_URL', 'https://graph.facebook.com/v23.0')
  end

  def facebook_api_headers(inbox)
    token = channel_access_token(inbox)
    {
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json'
    }
  end

  # Helper to resolve the correct access token for Instagram/Facebook channels
  def channel_access_token(inbox)
    ch = inbox.channel
    # Prefer dedicated accessor if available (Channel::Instagram)
    return ch.access_token if ch.respond_to?(:access_token)
    # Facebook Page stores token as page_access_token
    return ch.page_access_token if ch.respond_to?(:page_access_token)
    # Fallback to provider_config keys when present
    if ch.respond_to?(:provider_config) && ch.provider_config.is_a?(Hash)
      return ch.provider_config['access_token'] || ch.provider_config['page_access_token']
    end

    nil
  end
end
