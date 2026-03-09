# frozen_string_literal: true

class Integrations::SocialwiseFlow::WhatsappResponseProcessor
  class << self
    # Main entry point for processing WhatsApp responses from SocialWise Flow
    # @param whatsapp_data [Hash] The WhatsApp response data from SocialWise Flow
    # @param message [Message] The message object from the conversation
    # @return [Boolean] true if processing was successful, false otherwise
    def process(whatsapp_data, message)
      start_time = Time.current
      Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] === STARTING WHATSAPP RESPONSE PROCESSING ==='
      Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Processing started at: #{start_time.iso8601}"
      Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Message ID: #{message.id}, Conversation ID: #{message.conversation.id}"
      Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Account ID: #{message.conversation.account_id}, Inbox ID: #{message.conversation.inbox_id}"
      Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Contact ID: #{message.conversation.contact_id}, Channel: #{message.conversation.inbox.channel_type}"
      Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] WhatsApp data: #{whatsapp_data.inspect}"

      # Validate that we have the required data
      unless whatsapp_data.is_a?(Hash)
        Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Invalid whatsapp_data: expected Hash, got #{whatsapp_data.class}"
        return fallback_to_text_message(message, whatsapp_data)
      end

      # Validate WhatsApp channel
      conversation = message.conversation
      unless conversation.inbox.channel_type == 'Channel::Whatsapp'
        Rails.logger.warn "[SOCIALWISE-FLOW-WHATSAPP] Rich messages only supported for WhatsApp channels, got: #{conversation.inbox.channel_type}"
        return fallback_to_text_message(message, whatsapp_data)
      end

      # Determine message type
      message_type = whatsapp_data['type']
      Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Message type: #{message_type}"

      # Route message based on type
      success = route_message(message_type, whatsapp_data, message)

      end_time = Time.current
      processing_duration = ((end_time - start_time) * 1000).round(2)
      Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] === WHATSAPP RESPONSE PROCESSING COMPLETED ==='
      Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Processing completed at: #{end_time.iso8601}"
      Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Total processing time: #{processing_duration}ms"
      Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] SUCCESS: Message type '#{message_type}' processed successfully"
      success
    rescue StandardError => e
      end_time = Time.current
      processing_duration = ((end_time - start_time) * 1000).round(2)
      Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Processing failed: #{e.class}: #{e.message}"
      Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Processing failed at: #{end_time.iso8601}"
      Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Processing time before failure: #{processing_duration}ms"
      Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Full context - Message ID: #{message.id}, Account ID: #{message.conversation.account_id}"
      Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Backtrace: #{e.backtrace.join('\n')}"
      fallback_to_text_message(message, whatsapp_data)
      false
    end

    private

    # Routes message to appropriate handler based on message type
    # @param message_type [String] The message type (interactive, text, template)
    # @param whatsapp_data [Hash] The WhatsApp payload
    # @param message [Message] The message object
    def route_message(message_type, whatsapp_data, message)
      Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Routing message with type: #{message_type}"

      case message_type
      when 'interactive'
        Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] Processing Interactive Message'
        send_interactive_message(whatsapp_data, message)
      when 'text'
        Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] Processing Text Message'
        send_text_message(whatsapp_data, message)
      when 'template'
        Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] Processing Template Message'
        send_template_message(whatsapp_data, message)
      else
        Rails.logger.warn "[SOCIALWISE-FLOW-WHATSAPP] Unknown message type: #{message_type}"
        # For unknown types, try to process as interactive if interactive payload exists
        if whatsapp_data['interactive'].present?
          Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] Unknown type but interactive payload found, processing as interactive'
          send_interactive_message(whatsapp_data, message)
        elsif whatsapp_data['template'].present?
          Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] Unknown type but template payload found, processing as template'
          send_template_message(whatsapp_data, message)
        else
          Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] No interactive/template payload, falling back to text message'
          fallback_to_text_message(message, whatsapp_data)
        end
      end
    end

    # Send Interactive Message using WhatsApp Rich Message Service
    # @param whatsapp_data [Hash] The WhatsApp payload
    # @param message [Message] The message object
    def send_interactive_message(whatsapp_data, message)
      Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] === STARTING INTERACTIVE MESSAGE SEND ==='
      Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Interactive payload: #{whatsapp_data['interactive'].inspect}"
      Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Message ID: #{message.id}, Conversation ID: #{message.conversation.id}"

      begin
        conversation = message.conversation
        interactive_payload = whatsapp_data['interactive']

        unless interactive_payload.present?
          Rails.logger.error '[SOCIALWISE-FLOW-WHATSAPP] Missing interactive payload'
          return fallback_to_text_message(message, whatsapp_data)
        end

        # Extract text content for dashboard display
        text_content = extract_text_content(whatsapp_data)
        Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Extracted text content: #{text_content}"

        # Create message for dashboard display (Requirement 7.1, 7.2)
        outgoing_message = nil
        begin
          # Para mensagens interativas, usar content_type 'integrations' com payload completo
          # O WhatsApp service pode usar send_interactive_payload para payloads prontos
          outgoing_message = conversation.messages.create!(
            message_type: :outgoing,
            content: text_content,
            content_type: 'integrations',
            content_attributes: {
              'interactive' => interactive_payload,
              'type' => whatsapp_data['type'],
              'whatsapp_interactive_payload' => interactive_payload
            },
            account_id: conversation.account_id,
            inbox_id: conversation.inbox_id,
            additional_attributes: { skip_send_reply: true }
          )
          Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Interactive message created: #{outgoing_message.id}"

        rescue StandardError => e
          # Requirement 6.2: Continue processing even if message creation fails
          Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Message creation failed: #{e.class}: #{e.message}"
          Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Text content: #{text_content}"
          Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Backtrace: #{e.backtrace.first(3).join('\n')}"

          # Try to create a simple fallback message
          begin
            outgoing_message = conversation.messages.create!(
              message_type: :outgoing,
              content: text_content || 'WhatsApp message',
              content_type: 'text',
              account_id: conversation.account_id,
              inbox_id: conversation.inbox_id,
              additional_attributes: { skip_send_reply: true }
            )
            Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Fallback message created: #{outgoing_message.id}"
          rescue StandardError => fallback_error
            Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Fallback message creation also failed: #{fallback_error.class}: #{fallback_error.message}"
            return false # Can't create message, abort processing
          end
        end

        # Send message using native WhatsApp service
        if outgoing_message
          begin
            # Para mensagens interativas, usar o método send_interactive_payload diretamente
            contact_source_id = conversation.contact.get_source_id(conversation.inbox.id)
            channel = conversation.inbox.channel

            Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] Sending interactive message via send_interactive_payload'
            Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Contact source ID: #{contact_source_id}"

            message_id = channel.provider_service.send_interactive_payload(contact_source_id, outgoing_message, interactive_payload)

            if message_id.present?
              outgoing_message.update!(source_id: message_id)
              Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Interactive message sent successfully, source_id: #{message_id}"
            else
              Rails.logger.warn '[SOCIALWISE-FLOW-WHATSAPP] Interactive message sent but no message_id returned'
            end

          rescue StandardError => e
            # Requirement 6.2: Log rich message sending failures but continue processing
            Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Message sending failed: #{e.class}: #{e.message}"
            Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Message ID: #{outgoing_message.id}"
            Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Contact source ID: #{begin
              conversation.contact.get_source_id(conversation.inbox.id)
            rescue StandardError
              'unknown'
            end}"
            Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Backtrace: #{e.backtrace.first(5).join('\n')}"
            # Message is created in dashboard, sending failure doesn't affect that
          end
        end

        Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] === INTERACTIVE MESSAGE SEND COMPLETED ==='
        true
      rescue StandardError => e
        Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Interactive message send failed: #{e.class}: #{e.message}"
        Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Backtrace: #{e.backtrace.join('\n')}"
        Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] Falling back to text message due to error'

        fallback_to_text_message(message, whatsapp_data)
        false
      end
    end

    # Send Text Message
    # @param whatsapp_data [Hash] The WhatsApp payload
    # @param message [Message] The message object
    def send_text_message(whatsapp_data, message)
      Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] === STARTING TEXT MESSAGE SEND ==='
      Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Text payload: #{whatsapp_data.inspect}"

      begin
        conversation = message.conversation
        text_content = extract_text_content(whatsapp_data)
        Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Extracted text content: #{text_content}"

        # Create message for dashboard display (Requirement 7.1, 7.2)
        outgoing_message = nil
        begin
          # Para mensagens de texto simples
          outgoing_message = conversation.messages.create!(
            message_type: :outgoing,
            content: text_content,
            content_type: 'text',
            account_id: conversation.account_id,
            inbox_id: conversation.inbox_id,
            additional_attributes: { skip_send_reply: true }
          )
          Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Text message created: #{outgoing_message.id}"

        rescue StandardError => e
          # Requirement 6.2: Continue processing even if message creation fails
          Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Message creation failed: #{e.class}: #{e.message}"
          Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Text content: #{text_content}"
          Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Backtrace: #{e.backtrace.first(3).join('\n')}"

          # Try to create a simple fallback message
          begin
            outgoing_message = conversation.messages.create!(
              message_type: :outgoing,
              content: text_content || 'WhatsApp message',
              content_type: 'text',
              account_id: conversation.account_id,
              inbox_id: conversation.inbox_id,
              additional_attributes: { skip_send_reply: true }
            )
            Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Fallback message created: #{outgoing_message.id}"
          rescue StandardError => fallback_error
            Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Fallback message creation also failed: #{fallback_error.class}: #{fallback_error.message}"
            return false # Can't create message, abort processing
          end
        end

        # Send message using native WhatsApp service
        if outgoing_message
          begin
            # Para mensagens de texto, usar o serviço padrão
            Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] Sending text message via SendOnWhatsappService'
            Whatsapp::SendOnWhatsappService.new(message: outgoing_message).perform
            Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] Text message sent successfully'

          rescue StandardError => e
            # Requirement 6.2: Log rich message sending failures but continue processing
            Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Message sending failed: #{e.class}: #{e.message}"
            Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Message ID: #{outgoing_message.id}"
            Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Contact source ID: #{begin
              conversation.contact.get_source_id(conversation.inbox.id)
            rescue StandardError
              'unknown'
            end}"
            Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Backtrace: #{e.backtrace.first(5).join('\n')}"
            # Message is created in dashboard, sending failure doesn't affect that
          end
        end

        Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] === TEXT MESSAGE SEND COMPLETED ==='
        true
      rescue StandardError => e
        Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Text message send failed: #{e.class}: #{e.message}"
        Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Backtrace: #{e.backtrace.join('\n')}"
        false
      end
    end

    # Send Template Message (e.g., coupon codes)
    # @param whatsapp_data [Hash] The WhatsApp payload with template data
    # @param message [Message] The message object
    def send_template_message(whatsapp_data, message)
      Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] === STARTING TEMPLATE MESSAGE SEND ==='
      Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Template payload: #{whatsapp_data.inspect}"

      begin
        conversation = message.conversation
        template_payload = whatsapp_data['template']

        unless template_payload.present?
          Rails.logger.error '[SOCIALWISE-FLOW-WHATSAPP] Missing template payload'
          return fallback_to_text_message(message, whatsapp_data)
        end

        template_name = template_payload['name']
        Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Template name: #{template_name}"

        # Extract text content for dashboard display
        text_content = extract_template_text_content(template_payload)
        Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Extracted template text: #{text_content}"

        # Create message for dashboard display
        outgoing_message = nil
        begin
          outgoing_message = conversation.messages.create!(
            message_type: :outgoing,
            content: text_content,
            content_type: 'integrations',
            content_attributes: {
              'template' => template_payload,
              'type' => 'template',
              'whatsapp_template_payload' => template_payload
            },
            account_id: conversation.account_id,
            inbox_id: conversation.inbox_id,
            additional_attributes: { skip_send_reply: true }
          )
          Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Template message created in dashboard: #{outgoing_message.id}"

        rescue StandardError => e
          Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Message creation failed: #{e.class}: #{e.message}"
          Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Text content: #{text_content}"
          Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Backtrace: #{e.backtrace.first(3).join('\n')}"

          # Fallback to simple text message
          begin
            outgoing_message = conversation.messages.create!(
              message_type: :outgoing,
              content: text_content || "WhatsApp template: #{template_name}",
              content_type: 'text',
              account_id: conversation.account_id,
              inbox_id: conversation.inbox_id,
              additional_attributes: { skip_send_reply: true }
            )
            Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Fallback message created: #{outgoing_message.id}"
          rescue StandardError => fallback_error
            Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Fallback message creation also failed: #{fallback_error.class}: #{fallback_error.message}"
            return false
          end
        end

        # Send template using WhatsApp API directly (não usar send_template nativo para preservar compatibilidade)
        if outgoing_message
          begin
            contact_source_id = conversation.contact.get_source_id(conversation.inbox.id)
            channel = conversation.inbox.channel

            Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] Sending template directly to WhatsApp API'
            Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Contact source ID: #{contact_source_id}"
            Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Template payload: #{template_payload.to_json}"

            # Enviar direto para API da Meta usando HTTParty (preserva template nativo do Chatwoot)
            message_id = send_template_to_whatsapp_api(channel, contact_source_id, template_payload)

            if message_id.present?
              outgoing_message.update!(source_id: message_id)
              Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Template sent successfully, source_id: #{message_id}"
            else
              Rails.logger.warn '[SOCIALWISE-FLOW-WHATSAPP] Template sent but no message_id returned'
            end

          rescue StandardError => e
            Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Template sending failed: #{e.class}: #{e.message}"
            Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Message ID: #{outgoing_message.id}"
            Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Contact source ID: #{begin
              contact_source_id
            rescue StandardError
              'unknown'
            end}"
            Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Backtrace: #{e.backtrace.first(5).join('\n')}"
            # Message is created in dashboard, sending failure doesn't affect that
          end
        end

        Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] === TEMPLATE MESSAGE SEND COMPLETED ==='
        true
      rescue StandardError => e
        Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Template message send failed: #{e.class}: #{e.message}"
        Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Backtrace: #{e.backtrace.join('\n')}"
        Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] Falling back to text message due to error'

        fallback_to_text_message(message, whatsapp_data)
        false
      end
    end

    # Extract text content from WhatsApp payload
    # @param whatsapp_data [Hash] The WhatsApp payload
    # @return [String] Extracted text content
    def extract_text_content(whatsapp_data)
      # Try different locations for text content
      whatsapp_data.dig('interactive', 'body', 'text') ||
        whatsapp_data.dig('text', 'body') ||
        whatsapp_data['text'] ||
        'WhatsApp message'
    end

    # Extract text content from template payload for dashboard display
    # @param template_payload [Hash] The template payload
    # @return [String] Extracted text content
    def extract_template_text_content(template_payload)
      template_name = template_payload['name']

      # Extract coupon code if present
      coupon_code = template_payload.dig('components')&.find { |c| c['type'] == 'button' }&.dig('parameters', 0, 'coupon_code')

      if coupon_code.present?
        "Template: #{template_name} - Código: #{coupon_code}"
      else
        "Template: #{template_name}"
      end
    end

    # Send template directly to WhatsApp API (Meta Graph API)
    # Não usa o send_template nativo do Chatwoot para preservar compatibilidade
    # @param channel [Channel::Whatsapp] The WhatsApp channel
    # @param phone_number [String] The recipient phone number
    # @param template_payload [Hash] The template payload from SocialWise Flow
    # @return [String, nil] The message ID from WhatsApp API or nil on failure
    def send_template_to_whatsapp_api(channel, phone_number, template_payload)
      channel.provider_service

      # Build API URL (usando mesma estrutura do WhatsappCloudService)
      api_base_path = ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
      phone_id = channel.provider_config['phone_number_id']
      api_url = "#{api_base_path}/v23.0/#{phone_id}/messages"

      # Build headers
      api_key = channel.provider_config['api_key']
      headers = {
        'Authorization' => "Bearer #{api_key}",
        'Content-Type' => 'application/json'
      }

      # Build request body no formato exato da Meta API
      body = {
        messaging_product: 'whatsapp',
        to: phone_number,
        type: 'template',
        template: template_payload
      }

      Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] API URL: #{api_url}"
      Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Request body: #{body.to_json}"

      # Send request to WhatsApp API
      response = HTTParty.post(
        api_url,
        headers: headers,
        body: body.to_json
      )

      Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] WhatsApp API Response status: #{response.code}"
      Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] WhatsApp API Response body: #{response.body}"

      # Process response (mesma lógica do WhatsappCloudService)
      if response.success?
        message_id = response.parsed_response&.dig('messages', 0, 'id')
        Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Template sent successfully, message_id: #{message_id}"
        message_id
      else
        error_message = response.parsed_response&.dig('error', 'message')
        Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] WhatsApp API error: #{error_message}"
        nil
      end
    rescue StandardError => e
      Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Exception sending template to API: #{e.class}: #{e.message}"
      Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Backtrace: #{e.backtrace.first(5).join('\n')}"
      nil
    end

    # Fallback to text message when rich message processing fails
    # @param message [Message] The original message
    # @param whatsapp_data [Hash] The WhatsApp data for text extraction
    # @return [Boolean] true if fallback was successful
    def fallback_to_text_message(message, whatsapp_data)
      Rails.logger.info '[SOCIALWISE-FLOW-WHATSAPP] Falling back to text message'

      begin
        fallback_text = extract_text_content(whatsapp_data)

        conversation = message.conversation
        fallback_message = conversation.messages.create!(
          content: fallback_text,
          message_type: :outgoing,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id
        )

        Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Fallback text message created successfully: #{fallback_text}"
        Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] Fallback message ID: #{fallback_message.id}"
        true
      rescue StandardError => e
        Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Fallback to text message failed: #{e.class}: #{e.message}"
        Rails.logger.error "[SOCIALWISE-FLOW-WHATSAPP] Fallback backtrace: #{e.backtrace.join('\n')}"
        false
      end
    end
  end
end