# frozen_string_literal: true

class Integrations::Socialwise::InstagramResponseProcessor
  class << self
    # Main entry point for processing socialwiseResponse payloads
    # @param socialwise_data [Hash] The socialwiseResponse data from Dialogflow OR SocialWise Flow
    # @param message [Message] The message object from the conversation
    # @return [Boolean] true if processing was successful, false otherwise
    def process(socialwise_data, message)
      start_time = Time.current
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] === STARTING SOCIALWISE RESPONSE PROCESSING ==='
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Processing started at: #{start_time.iso8601}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Message ID: #{message.id}, Conversation ID: #{message.conversation.id}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Account ID: #{message.conversation.account_id}, Inbox ID: #{message.conversation.inbox_id}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Contact ID: #{message.conversation.contact_id}, Channel: #{message.conversation.inbox.channel_type}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] SocialWise data: #{socialwise_data.inspect}"

      # Validate that we have the required data
      unless socialwise_data.is_a?(Hash)
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Invalid socialwise_data: expected Hash, got #{socialwise_data.class}"
        return fallback_to_text_message(message, socialwise_data)
      end

      # ADAPTAÇÃO: Suportar tanto formato Dialogflow quanto SocialWise Flow
      normalized_data = normalize_payload_structure(socialwise_data)

      # Se a normalização falhou, usar fallback
      unless normalized_data
        Rails.logger.error '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Payload normalization failed, using fallback'
        return fallback_to_text_message(message, socialwise_data)
      end

      message_format = normalized_data['message_format']
      payload = normalized_data['payload']

      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Normalized message format: #{message_format}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Normalized payload: #{payload.inspect}"

      # Validate payload structure
      unless validate_payload(message_format, payload)
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Invalid payload for format: #{message_format}"
        return fallback_to_text_message(message, socialwise_data)
      end

      # Route message based on format
      route_message(message_format, payload, message)

      end_time = Time.current
      processing_duration = ((end_time - start_time) * 1000).round(2)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] === SOCIALWISE RESPONSE PROCESSING COMPLETED ==='
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Processing completed at: #{end_time.iso8601}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Total processing time: #{processing_duration}ms"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] SUCCESS: Message format '#{message_format}' processed successfully"
      true
    rescue StandardError => e
      end_time = Time.current
      processing_duration = ((end_time - start_time) * 1000).round(2)
      Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Processing failed: #{e.class}: #{e.message}"
      Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Processing failed at: #{end_time.iso8601}"
      Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Processing time before failure: #{processing_duration}ms"
      Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Full context - Message ID: #{message.id}, Account ID: #{message.conversation.account_id}"
      Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Backtrace: #{e.backtrace.join('\n')}"
      fallback_to_text_message(message, socialwise_data)
      false
    end

    private

    # ADAPTAÇÃO: Normaliza payload para funcionar com ambos os formatos
    # @param socialwise_data [Hash] Payload original (Dialogflow ou SocialWise Flow)
    # @return [Hash, nil] Payload normalizado no formato esperado ou nil se falhar
    def normalize_payload_structure(socialwise_data)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Normalizing payload structure'
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Original data keys: #{socialwise_data.keys.inspect}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Full socialwise_data: #{socialwise_data.inspect}"

      begin
        # Verificar se é formato SocialWise Flow (tem 'instagram' wrapper)
        if socialwise_data.is_a?(Hash) && socialwise_data['instagram'].present?
          Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Detected SocialWise Flow format (instagram wrapper)'

          instagram_data = socialwise_data['instagram']
          Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Instagram data: #{instagram_data.inspect}"

          # Validar se instagram_data tem os campos necessários
          unless instagram_data.is_a?(Hash) && instagram_data['message_format'].present?
            Rails.logger.error '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Invalid instagram data structure'
            Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Instagram data: #{instagram_data.inspect}"
            return nil
          end

          # Extrair message_format e construir payload normalizado
          message_format = instagram_data['message_format']
          Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Message format: #{message_format}"

          normalized = {
            'message_format' => message_format,
            'payload' => {}
          }

          # Adicionar template_type se presente
          normalized['payload']['template_type'] = instagram_data['template_type'] if instagram_data['template_type'].present?

          # Adicionar elementos específicos baseado no formato
          case message_format
          when 'GENERIC_TEMPLATE'
            Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Processing GENERIC_TEMPLATE format'
            normalized['payload']['template_type'] = 'generic'
            normalized['payload']['elements'] = instagram_data['elements'] if instagram_data['elements'].present?

          when 'BUTTON_TEMPLATE'
            Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Processing BUTTON_TEMPLATE format'
            normalized['payload']['template_type'] = 'button'
            normalized['payload']['text'] = instagram_data['text'] if instagram_data['text'].present?
            normalized['payload']['buttons'] = instagram_data['buttons'] if instagram_data['buttons'].present?

          when 'QUICK_REPLIES'
            Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Processing QUICK_REPLIES format'
            normalized['payload']['text'] = instagram_data['text'] if instagram_data['text'].present?
            normalized['payload']['quick_replies'] = instagram_data['quick_replies'] if instagram_data['quick_replies'].present?

          else
            Rails.logger.warn "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Unknown message format in SocialWise Flow: #{message_format}"
            # Ainda assim, tenta processar copiando todos os campos
            instagram_data.each do |key, value|
              next if key == 'message_format'

              normalized['payload'][key] = value
            end
          end

          Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Normalized to Dialogflow format: #{normalized.inspect}"
          return normalized

        # Verificar se é formato Dialogflow (tem message_format e payload direto)
        elsif socialwise_data.is_a?(Hash) && socialwise_data['message_format'].present? && socialwise_data['payload'].present?
          Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Detected Dialogflow format (direct message_format and payload)'
          return socialwise_data

        # Verificar se é formato direto do SocialWise Flow (sem wrapper 'instagram')
        elsif socialwise_data.is_a?(Hash) && socialwise_data['message_format'].present?
          Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Detected direct SocialWise Flow format (no instagram wrapper)'

          # Construir payload normalizado
          normalized = {
            'message_format' => socialwise_data['message_format'],
            'payload' => {}
          }

          # Copiar todos os campos exceto message_format para o payload
          socialwise_data.each do |key, value|
            next if key == 'message_format'

            normalized['payload'][key] = value
          end

          Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Normalized direct format: #{normalized.inspect}"
          return normalized

        else
          Rails.logger.error '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Unknown payload format'
          Rails.logger.error '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Expected formats:'
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] 1. SocialWise Flow: {'instagram': {'message_format': '...', ...}}"
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] 2. Dialogflow: {'message_format': '...', 'payload': {...}}"
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] 3. Direct SocialWise: {'message_format': '...', 'elements': [...], ...}"
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Received keys: #{socialwise_data.keys.inspect}"
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Received data: #{socialwise_data.inspect}"

          return nil
        end

      rescue StandardError => e
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Payload normalization failed: #{e.class}: #{e.message}"
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Backtrace: #{e.backtrace.first(5).join('\n')}"
        return nil
      end
    end

    # Routes message to appropriate handler based on message_format
    # @param message_format [String] The format type (GENERIC_TEMPLATE, BUTTON_TEMPLATE, QUICK_REPLIES)
    # @param payload [Hash] The message payload
    # @param message [Message] The message object
    def route_message(message_format, payload, message)
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Routing message with format: #{message_format}"

      platform = detect_platform(message)
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Detected platform: #{platform}"

      case platform
      when :instagram
        validator = InstagramChannelValidator.new(message)
        unless validator.valid_for_rich_messages?
          Rails.logger.warn "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Instagram channel validation failed: #{validator.error_messages}"
          Rails.logger.warn "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Validation status: #{validator.validation_status.inspect}"
          return fallback_to_text_message(message, { 'payload' => payload })
        end
        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Instagram channel validation passed successfully'
      when :facebook
        fb_validator = FacebookChannelValidator.new(message)
        unless fb_validator.valid_for_rich_messages?
          Rails.logger.warn "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Facebook channel validation failed: #{fb_validator.error_messages}"
          Rails.logger.warn "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Validation status: #{fb_validator.validation_status.inspect}"
          return fallback_to_text_message(message, { 'payload' => payload })
        end
        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Facebook channel validation passed successfully'
      else
        Rails.logger.warn '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Unsupported platform for rich messages'
        return fallback_to_text_message(message, { 'payload' => payload })
      end

      case message_format
      when 'GENERIC_TEMPLATE'
        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Processing Generic Template'
        send_generic_template(payload, message, platform: platform)
      when 'BUTTON_TEMPLATE'
        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Processing Button Template'
        send_button_template(payload, message, platform: platform)
      when 'QUICK_REPLIES'
        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Processing Quick Replies'
        send_quick_replies(payload, message, platform: platform)
      else
        Rails.logger.warn "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Unknown message format: #{message_format}"
        log_unknown_format(message_format)
        fallback_to_text_message(message, { 'payload' => payload })
      end
    end

    def detect_platform(message)
      channel = message.conversation.inbox.channel
      return :instagram if channel.is_a?(Channel::Instagram)
      return :facebook if channel.is_a?(Channel::FacebookPage)

      :unknown
    end

    # Validates payload structure for each message format
    # @param message_format [String] The format type
    # @param payload [Hash] The payload to validate
    # @return [Boolean] true if valid, false otherwise
    def validate_payload(message_format, payload)
      validation_start_time = Time.current
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] === STARTING PAYLOAD VALIDATION ==='
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Validating payload for format: #{message_format}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Payload size: #{payload.inspect.length} characters"

      unless payload.is_a?(Hash)
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] VALIDATION FAILED: Payload is not a Hash, got #{payload.class}"
        return false
      end

      validation_result = case message_format
                          when 'GENERIC_TEMPLATE'
                            validate_generic_template(payload)
                          when 'BUTTON_TEMPLATE'
                            validate_button_template(payload)
                          when 'QUICK_REPLIES'
                            validate_quick_replies(payload)
                          else
                            Rails.logger.warn "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Unknown format for validation: #{message_format}"
                            Rails.logger.warn '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Supported formats: GENERIC_TEMPLATE, BUTTON_TEMPLATE, QUICK_REPLIES'
                            false
                          end

      validation_end_time = Time.current
      validation_duration = ((validation_end_time - validation_start_time) * 1000).round(2)

      if validation_result
        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] === PAYLOAD VALIDATION SUCCESSFUL ==='
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Validation time: #{validation_duration}ms"
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Format: #{message_format} validated successfully"
      else
        Rails.logger.error '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] === PAYLOAD VALIDATION FAILED ==='
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Validation time: #{validation_duration}ms"
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Format: #{message_format} validation failed"
      end

      validation_result
    end

    # Validates Generic Template payload structure
    # @param payload [Hash] The payload to validate
    # @return [Boolean] true if valid, false otherwise
    def validate_generic_template(payload)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Validating Generic Template payload'

      # Check required fields
      unless payload['template_type'] == 'generic'
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Invalid template_type: expected 'generic', got '#{payload['template_type']}'"
        return false
      end

      unless payload['elements'].is_a?(Array) && payload['elements'].any?
        Rails.logger.error '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Invalid elements: must be non-empty array'
        return false
      end

      # Instagram API constraint: max 10 elements in carousel
      if payload['elements'].length > 10
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Too many elements: max 10 allowed, got #{payload['elements'].length}"
        return false
      end

      # Validate each element
      payload['elements'].each_with_index do |element, index|
        unless element.is_a?(Hash)
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Element #{index} is not a hash"
          return false
        end

        unless element['title'].present?
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Element #{index} missing required title"
          return false
        end

        # Validate title length (Instagram limit: 80 characters)
        if element['title'].length > 80
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Element #{index} title too long: max 80 characters, got #{element['title'].length}"
          return false
        end

        # Validate subtitle length if present (Instagram limit: 80 characters)
        if element['subtitle'].present? && element['subtitle'].length > 80
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Element #{index} subtitle too long: max 80 characters, got #{element['subtitle'].length}"
          return false
        end

        # Validate image URL format if present
        return false if element['image_url'].present? && !validate_image_url(element['image_url'], "Element #{index} image_url")

        # Validate buttons if present
        next unless element['buttons'].present?

        unless element['buttons'].is_a?(Array) && element['buttons'].length <= 3
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Element #{index} has invalid buttons (max 3 allowed)"
          return false
        end

        element['buttons'].each_with_index do |button, btn_index|
          return false unless validate_button(button, "Element #{index} Button #{btn_index}")
        end
      end

      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Generic Template payload validation passed'
      true
    end

    # Validates Button Template payload structure
    # @param payload [Hash] The payload to validate
    # @return [Boolean] true if valid, false otherwise
    def validate_button_template(payload)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Validating Button Template payload'

      # Check required fields
      unless payload['template_type'] == 'button'
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Invalid template_type: expected 'button', got '#{payload['template_type']}'"
        return false
      end

      unless payload['text'].present?
        Rails.logger.error '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Button Template missing required text'
        return false
      end

      # Validate text length (Instagram limit: 2000 characters)
      if payload['text'].length > 2000
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Button Template text too long: max 2000 characters, got #{payload['text'].length}"
        return false
      end

      unless payload['buttons'].is_a?(Array) && payload['buttons'].any? && payload['buttons'].length <= 3
        Rails.logger.error '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Invalid buttons: must be array with 1-3 buttons'
        return false
      end

      # Validate each button
      payload['buttons'].each_with_index do |button, index|
        return false unless validate_button(button, "Button #{index}")
      end

      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Button Template payload validation passed'
      true
    end

    # Validates Quick Replies payload structure
    # @param payload [Hash] The payload to validate
    # @return [Boolean] true if valid, false otherwise
    def validate_quick_replies(payload)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Validating Quick Replies payload'

      # Check required fields
      unless payload['text'].present?
        Rails.logger.error '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Quick Replies missing required text'
        return false
      end

      # Validate text length (Instagram limit: 2000 characters)
      if payload['text'].length > 2000
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Quick Replies text too long: max 2000 characters, got #{payload['text'].length}"
        return false
      end

      unless payload['quick_replies'].is_a?(Array) && payload['quick_replies'].any? && payload['quick_replies'].length <= 13
        Rails.logger.error '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Invalid quick_replies: must be array with 1-13 quick replies'
        return false
      end

      # Validate each quick reply
      payload['quick_replies'].each_with_index do |quick_reply, index|
        unless quick_reply.is_a?(Hash)
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Quick reply #{index} is not a hash"
          return false
        end

        unless quick_reply['content_type'] == 'text'
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Quick reply #{index} invalid content_type: expected 'text', got '#{quick_reply['content_type']}'"
          return false
        end

        unless quick_reply['title'].present?
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Quick reply #{index} missing required title"
          return false
        end

        # Validate title length (Instagram limit: 20 characters for quick reply titles)
        if quick_reply['title'].length > 20
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Quick reply #{index} title too long: max 20 characters, got #{quick_reply['title'].length}"
          return false
        end

        unless quick_reply['payload'].present?
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Quick reply #{index} missing required payload"
          return false
        end

        # Validate payload length (Instagram limit: 1000 characters)
        if quick_reply['payload'].length > 1000
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Quick reply #{index} payload too long: max 1000 characters, got #{quick_reply['payload'].length}"
          return false
        end
      end

      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Quick Replies payload validation passed'
      true
    end

    # Validates individual button structure
    # @param button [Hash] The button to validate
    # @param context [String] Context for error messages
    # @return [Boolean] true if valid, false otherwise
    def validate_button(button, context)
      unless button.is_a?(Hash)
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] #{context} is not a hash"
        return false
      end

      unless button['type'].present?
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] #{context} missing required type"
        return false
      end

      unless button['title'].present?
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] #{context} missing required title"
        return false
      end

      # Validate title length (Instagram limit: 20 characters for button titles)
      if button['title'].length > 20
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] #{context} title too long: max 20 characters, got #{button['title'].length}"
        return false
      end

      case button['type']
      when 'postback'
        unless button['payload'].present?
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] #{context} postback button missing required payload"
          return false
        end

        # Validate payload length (Instagram limit: 1000 characters)
        if button['payload'].length > 1000
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] #{context} postback payload too long: max 1000 characters, got #{button['payload'].length}"
          return false
        end
      when 'web_url'
        unless button['url'].present?
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] #{context} web_url button missing required url"
          return false
        end

        # Enhanced URL validation
        return false unless validate_web_url(button['url'], context)
      else
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] #{context} has invalid type: #{button['type']} (must be 'postback' or 'web_url')"
        return false
      end

      true
    end

    # Validates web URL format and constraints
    # @param url [String] The URL to validate
    # @param context [String] Context for error messages
    # @return [Boolean] true if valid, false otherwise
    def validate_web_url(url, context)
      # Basic URL format validation
      unless url&.match?(URI::DEFAULT_PARSER.make_regexp(%w[http https]))
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] #{context} has invalid URL format: #{url}"
        return false
      end

      # URL length validation (Instagram limit: 2000 characters)
      if url.length > 2000
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] #{context} URL too long: max 2000 characters, got #{url.length}"
        return false
      end

      # Parse URL to validate structure
      begin
        parsed_uri = URI.parse(url)

        # Ensure scheme is present and valid
        unless %w[http https].include?(parsed_uri.scheme)
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] #{context} URL must use http or https scheme: #{url}"
          return false
        end

        # Ensure host is present
        unless parsed_uri.host.present?
          Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] #{context} URL missing host: #{url}"
          return false
        end

        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] #{context} URL validation passed: #{url}"
        true
      rescue URI::InvalidURIError => e
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] #{context} invalid URL structure: #{e.message}"
        false
      end
    end

    # Validates image URL format and constraints
    # @param image_url [String] The image URL to validate
    # @param context [String] Context for error messages
    # @return [Boolean] true if valid, false otherwise
    def validate_image_url(image_url, context)
      # Basic URL validation first
      return false unless validate_web_url(image_url, context)

      # Check for common image file extensions
      valid_extensions = %w[.jpg .jpeg .png .gif .webp]
      url_path = URI.parse(image_url).path.downcase

      unless valid_extensions.any? { |ext| url_path.end_with?(ext) }
        Rails.logger.warn "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] #{context} may not be a valid image URL (no recognized extension): #{image_url}"
        # Don't fail validation, just warn - some image URLs don't have extensions
      end

      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] #{context} image URL validation passed: #{image_url}"
      true
    end

    # Build Instagram API compatible Generic Template payload
    # @param payload [Hash] The original Generic Template payload
    # @return [Hash] Instagram API compatible payload
    def build_generic_template_payload(payload)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Building Instagram Generic Template payload'
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Original payload: #{payload.inspect}"

      # Apply character limit validation and truncation for Generic Template
      processed_payload = apply_character_limits(payload, 'GENERIC_TEMPLATE')

      instagram_payload = {
        'template_type' => 'generic',
        'elements' => build_generic_template_elements(processed_payload['elements'])
      }

      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Built Instagram payload: #{instagram_payload.inspect}"
      instagram_payload
    end

    # Build elements array for Generic Template
    # @param elements [Array] The original elements array
    # @return [Array] Instagram API compatible elements
    def build_generic_template_elements(elements)
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Building #{elements&.length} Generic Template elements"

      return [] unless elements.is_a?(Array)

      instagram_elements = elements.map.with_index do |element, index|
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Building element #{index}: #{element.inspect}"

        instagram_element = {
          'title' => element['title']
        }

        # Add optional fields
        instagram_element['subtitle'] = element['subtitle'] if element['subtitle'].present?
        instagram_element['image_url'] = element['image_url'] if element['image_url'].present?

        # Handle buttons if present
        if element['buttons'].present? && element['buttons'].is_a?(Array)
          Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Element #{index} has #{element['buttons'].length} buttons"
          instagram_element['buttons'] = build_generic_template_buttons(element['buttons'], index)
        end

        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Built element #{index}: #{instagram_element.inspect}"
        instagram_element
      end

      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Built #{instagram_elements.length} Instagram elements"
      instagram_elements
    end

    # Build buttons array for Generic Template elements
    # @param buttons [Array] The original buttons array
    # @param element_index [Integer] The element index for logging
    # @return [Array] Instagram API compatible buttons
    def build_generic_template_buttons(buttons, element_index)
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Building buttons for element #{element_index}"

      return [] unless buttons.is_a?(Array)

      instagram_buttons = buttons.map.with_index do |button, button_index|
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Building element #{element_index} button #{button_index}: #{button.inspect}"

        instagram_button = {
          'type' => button['type'],
          'title' => button['title']
        }

        # Handle button type specific fields
        case button['type']
        when 'postback'
          instagram_button['payload'] = button['payload']
          Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Added postback payload: #{button['payload']}"
        when 'web_url'
          instagram_button['url'] = button['url']
          Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Added web URL: #{button['url']}"
        end

        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Built element #{element_index} button #{button_index}: #{instagram_button.inspect}"
        instagram_button
      end

      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Built #{instagram_buttons.length} buttons for element #{element_index}"
      instagram_buttons
    end

    # Build Instagram API compatible Button Template payload
    # @param payload [Hash] The original Button Template payload
    # @return [Hash] Instagram API compatible payload
    def build_button_template_payload(payload)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Building Instagram Button Template payload'
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Original payload: #{payload.inspect}"

      # Apply character limit validation and truncation for Button Template
      processed_payload = apply_character_limits(payload, 'BUTTON_TEMPLATE')

      instagram_payload = {
        'template_type' => 'button',
        'text' => processed_payload['text'],
        'buttons' => build_button_template_buttons(processed_payload['buttons'])
      }

      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Built Instagram payload: #{instagram_payload.inspect}"
      instagram_payload
    end

    # Build buttons array for Button Template
    # @param buttons [Array] The original buttons array
    # @return [Array] Instagram API compatible buttons
    def build_button_template_buttons(buttons)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Building Button Template buttons'

      return [] unless buttons.is_a?(Array)

      instagram_buttons = buttons.map.with_index do |button, button_index|
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Building Button Template button #{button_index}: #{button.inspect}"

        instagram_button = {
          'type' => button['type'],
          'title' => button['title']
        }

        # Handle button type specific fields
        case button['type']
        when 'postback'
          instagram_button['payload'] = button['payload']
          Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Added postback payload: #{button['payload']}"
        when 'web_url'
          instagram_button['url'] = button['url']
          Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Added web URL: #{button['url']}"
        end

        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Built Button Template button #{button_index}: #{instagram_button.inspect}"
        instagram_button
      end

      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Built #{instagram_buttons.length} buttons for Button Template"
      instagram_buttons
    end

    # Send Generic Template message using Instagram Rich Message Service
    # @param payload [Hash] The Generic Template payload
    # @param message [Message] The message object
    def send_generic_template(payload, message, platform: :instagram)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] === STARTING GENERIC TEMPLATE SEND ==='
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Generic Template payload: #{payload.inspect}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Message ID: #{message.id}, Conversation ID: #{message.conversation.id}"

      begin
        # Build Instagram API compatible Generic Template structure
        instagram_payload = build_generic_template_payload(payload)
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Built Instagram payload: #{instagram_payload.inspect}"

        # Create outgoing message for rich message service
        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Creating outgoing message for rich message service'
        conversation = message.conversation
        outgoing_message = create_rich_outgoing_message(conversation, instagram_payload, payload)
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Created outgoing message ID: #{outgoing_message.id} with skip_send_reply flag"

        # Perform the send operation (platform-specific)
        send_start_time = Time.current
        rich_message_service = if platform == :instagram
                                 Instagram::RichMessageService.new(message: outgoing_message, rich_payload: instagram_payload)
                               else
                                 Facebook::RichMessageService.new(message: outgoing_message, rich_payload: instagram_payload)
                               end
        rich_message_service.perform
        send_end_time = Time.current

        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Generic Template sent successfully'

        # Log performance metrics for the send operation
        log_performance_metrics(
          'Generic Template Send',
          send_start_time,
          send_end_time,
          message,
          {
            elements_count: payload['elements']&.length || 0,
            total_buttons: payload['elements']&.sum { |e| e['buttons']&.length || 0 } || 0
          }
        )

        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] === GENERIC TEMPLATE SEND COMPLETED ==='
        true
      rescue StandardError => e
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Generic Template send failed: #{e.class}: #{e.message}"
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Backtrace: #{e.backtrace.join('\n')}"
        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Falling back to text message due to error'

        fallback_to_text_message(message, { 'payload' => payload })
        false
      end
    end

    # Send Button Template message using Instagram Rich Message Service
    # @param payload [Hash] The Button Template payload
    # @param message [Message] The message object
    def send_button_template(payload, message, platform: :instagram)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] === STARTING BUTTON TEMPLATE SEND ==='
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Button Template payload: #{payload.inspect}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Message ID: #{message.id}, Conversation ID: #{message.conversation.id}"

      begin
        # Build Instagram API compatible Button Template structure
        instagram_payload = build_button_template_payload(payload)
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Built Instagram payload: #{instagram_payload.inspect}"

        # Create outgoing message for rich message service
        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Creating outgoing message for rich message service'
        conversation = message.conversation
        outgoing_message = create_rich_outgoing_message(conversation, instagram_payload, payload)
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Created outgoing message ID: #{outgoing_message.id} with skip_send_reply flag"

        # Send using platform-specific service
        rich_message_service = if platform == :instagram
                                 Instagram::RichMessageService.new(message: outgoing_message, rich_payload: instagram_payload)
                               else
                                 Facebook::RichMessageService.new(message: outgoing_message, rich_payload: instagram_payload)
                               end

        # Perform the send operation
        send_start_time = Time.current
        rich_message_service.perform
        send_end_time = Time.current

        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Button Template sent successfully'

        # Log performance metrics for the send operation
        log_performance_metrics(
          'Button Template Send',
          send_start_time,
          send_end_time,
          message,
          {
            buttons_count: payload['buttons']&.length || 0,
            text_length: payload['text']&.length || 0
          }
        )

        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] === BUTTON TEMPLATE SEND COMPLETED ==='
        true
      rescue StandardError => e
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Button Template send failed: #{e.class}: #{e.message}"
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Backtrace: #{e.backtrace.join('\n')}"
        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Falling back to text message due to error'

        fallback_to_text_message(message, { 'payload' => payload })
        false
      end
    end

    # Build Instagram API compatible Quick Replies payload
    # @param payload [Hash] The original Quick Replies payload
    # @return [Hash] Instagram API compatible payload
    def build_quick_replies_payload(payload)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Building Instagram Quick Replies payload'
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Original payload: #{payload.inspect}"

      # Apply character limit validation and truncation for Quick Replies
      processed_payload = apply_character_limits(payload, 'QUICK_REPLIES')

      instagram_payload = {
        'text' => processed_payload['text'],
        'quick_replies' => build_quick_replies_options(processed_payload['quick_replies'])
      }

      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Built Instagram payload: #{instagram_payload.inspect}"
      instagram_payload
    end

    # Build quick replies options array
    # @param quick_replies [Array] The original quick replies array
    # @return [Array] Instagram API compatible quick replies
    def build_quick_replies_options(quick_replies)
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Building #{quick_replies&.length} Quick Replies options"

      return [] unless quick_replies.is_a?(Array)

      instagram_quick_replies = quick_replies.map.with_index do |quick_reply, index|
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Building quick reply #{index}: #{quick_reply.inspect}"

        instagram_quick_reply = {
          'content_type' => quick_reply['content_type'],
          'title' => quick_reply['title'],
          'payload' => quick_reply['payload']
        }

        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Built quick reply #{index}: #{instagram_quick_reply.inspect}"
        instagram_quick_reply
      end

      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Built #{instagram_quick_replies.length} Instagram quick replies"
      instagram_quick_replies
    end

    # Send Quick Replies message using Instagram Rich Message Service
    # @param payload [Hash] The Quick Replies payload
    # @param message [Message] The message object
    def send_quick_replies(payload, message, platform: :instagram)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] === STARTING QUICK REPLIES SEND ==='
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Quick Replies payload: #{payload.inspect}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Message ID: #{message.id}, Conversation ID: #{message.conversation.id}"

      begin
        # Build Instagram API compatible Quick Replies structure
        instagram_payload = build_quick_replies_payload(payload)
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Built Instagram payload: #{instagram_payload.inspect}"

        # Create outgoing message for rich message service
        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Creating outgoing message for rich message service'
        conversation = message.conversation
        outgoing_message = create_rich_outgoing_message(conversation, instagram_payload, payload)
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Created outgoing message ID: #{outgoing_message.id} with skip_send_reply flag"

        # Send using platform-specific service
        rich_message_service = if platform == :instagram
                                 Instagram::RichMessageService.new(message: outgoing_message, rich_payload: instagram_payload)
                               else
                                 Facebook::RichMessageService.new(message: outgoing_message, rich_payload: instagram_payload)
                               end

        # Perform the send operation
        send_start_time = Time.current
        rich_message_service.perform
        send_end_time = Time.current

        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Quick Replies sent successfully'

        # Log performance metrics for the send operation
        log_performance_metrics(
          'Quick Replies Send',
          send_start_time,
          send_end_time,
          message,
          {
            quick_replies_count: payload['quick_replies']&.length || 0,
            text_length: payload['text']&.length || 0
          }
        )

        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] === QUICK REPLIES SEND COMPLETED ==='
        true
      rescue StandardError => e
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Quick Replies send failed: #{e.class}: #{e.message}"
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Backtrace: #{e.backtrace.join('\n')}"
        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Falling back to text message due to error'

        fallback_to_text_message(message, { 'payload' => payload })
        false
      end
    end

    # Logs unknown message format
    # @param message_format [String] The unknown format
    def log_unknown_format(message_format)
      Rails.logger.warn "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Unknown message format received: #{message_format}"
      Rails.logger.warn '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Supported formats: GENERIC_TEMPLATE, BUTTON_TEMPLATE, QUICK_REPLIES'
    end

    # Fallback to text message when rich message processing fails
    # @param message [Message] The original message
    # @param socialwise_data [Hash] The socialwise data for text extraction
    # @return [Boolean] true if fallback was successful
    def fallback_to_text_message(message, socialwise_data)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Falling back to text message'

      begin
        fallback_text = extract_fallback_text(socialwise_data)

        # Validate that fallback maintains conversation flow
        unless validate_fallback_flow(message, fallback_text)
          Rails.logger.error '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Fallback flow validation failed, using emergency fallback'
          fallback_text = 'Message received' # Emergency fallback
        end

        conversation = message.conversation
        fallback_message = conversation.messages.create!(
          content: fallback_text,
          message_type: :outgoing,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id
        )

        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Fallback text message created successfully: #{fallback_text}"
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Fallback message ID: #{fallback_message.id}, maintains conversation flow"
        true
      rescue StandardError => e
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Fallback to text message failed: #{e.class}: #{e.message}"
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Fallback backtrace: #{e.backtrace.join('\n')}"
        Rails.logger.error '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] CRITICAL: Fallback failed, conversation flow may be broken'
        false
      end
    end

    # Logs performance metrics for monitoring and optimization
    # @param operation [String] The operation being measured
    # @param start_time [Time] The start time of the operation
    # @param end_time [Time] The end time of the operation
    # @param message [Message] The message object for context
    # @param additional_data [Hash] Additional data to log
    def log_performance_metrics(operation, start_time, end_time, message, additional_data = {})
      duration_ms = ((end_time - start_time) * 1000).round(2)

      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] === PERFORMANCE METRICS ==='
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Operation: #{operation}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Duration: #{duration_ms}ms"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Start time: #{start_time.iso8601}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] End time: #{end_time.iso8601}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Message ID: #{message.id}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Conversation ID: #{message.conversation.id}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Account ID: #{message.conversation.account_id}"

      # Log additional performance data
      additional_data.each do |key, value|
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] #{key.to_s.humanize}: #{value}"
      end

      # Performance warnings
      if duration_ms > 5000
        Rails.logger.warn "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] PERFORMANCE WARNING: #{operation} took #{duration_ms}ms (>5s)"
      elsif duration_ms > 2000
        Rails.logger.warn "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] PERFORMANCE NOTICE: #{operation} took #{duration_ms}ms (>2s)"
      end

      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] === END PERFORMANCE METRICS ==='
    end

    # Logs success details with comprehensive information
    # @param message_format [String] The message format that was processed
    # @param message [Message] The message object
    # @param payload [Hash] The processed payload
    # @param processing_time [Float] The processing time in milliseconds
    def log_success_details(message_format, message, payload, processing_time)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] === SUCCESS DETAILS ==='
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Message format: #{message_format}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Processing time: #{processing_time}ms"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Message ID: #{message.id}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Conversation ID: #{message.conversation.id}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Account ID: #{message.conversation.account_id}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Inbox ID: #{message.conversation.inbox_id}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Contact ID: #{message.conversation.contact_id}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Channel type: #{message.conversation.inbox.channel_type}"

      # Log recipient details
      contact = message.conversation.contact
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Recipient name: #{contact.name}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Recipient source ID: #{contact.get_source_id(message.conversation.inbox_id)}"

      # Log payload summary
      case message_format
      when 'GENERIC_TEMPLATE'
        elements_count = payload['elements']&.length || 0
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Generic Template with #{elements_count} elements"
      when 'BUTTON_TEMPLATE'
        buttons_count = payload['buttons']&.length || 0
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Button Template with #{buttons_count} buttons"
      when 'QUICK_REPLIES'
        replies_count = payload['quick_replies']&.length || 0
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Quick Replies with #{replies_count} options"
      end

      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] === END SUCCESS DETAILS ==='
    end

    # Tests fallback scenarios to ensure user experience is maintained
    # @param message [Message] The original message
    # @param socialwise_data [Hash] The socialwise data
    # @return [Hash] Test results for different fallback scenarios
    def test_fallback_scenarios(message, socialwise_data)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Testing fallback scenarios for user experience'

      test_results = {
        text_extraction: false,
        flow_validation: false,
        message_creation: false,
        conversation_continuity: false
      }

      begin
        # Test text extraction
        fallback_text = extract_fallback_text(socialwise_data)
        test_results[:text_extraction] = fallback_text.present?
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Text extraction test: #{test_results[:text_extraction]} (text: '#{fallback_text}')"

        # Test flow validation
        test_results[:flow_validation] = validate_fallback_flow(message, fallback_text)
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Flow validation test: #{test_results[:flow_validation]}"

        # Test message creation (dry run)
        conversation = message.conversation
        if conversation&.account_id && conversation&.inbox_id
          test_results[:message_creation] = true
          Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Message creation test: #{test_results[:message_creation]}"
        end

        # Test conversation continuity
        if conversation&.status != 'resolved' && conversation&.messages&.any?
          test_results[:conversation_continuity] = true
          Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Conversation continuity test: #{test_results[:conversation_continuity]}"
        end

        overall_success = test_results.values.all?
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Fallback scenarios test overall: #{overall_success ? 'PASSED' : 'FAILED'}"
        Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Test results: #{test_results.inspect}"

        test_results
      rescue StandardError => e
        Rails.logger.error "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Fallback scenarios test failed: #{e.class}: #{e.message}"
        test_results[:error] = e.message
        test_results
      end
    end

    # Validates that fallback maintains conversation flow
    # @param message [Message] The original message
    # @param fallback_text [String] The fallback text to be sent
    # @return [Boolean] true if fallback is valid for conversation flow
    def validate_fallback_flow(message, fallback_text)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Validating fallback flow for conversation'

      # Ensure fallback text is not empty
      unless fallback_text.present?
        Rails.logger.error '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Fallback text is empty, this would break conversation flow'
        return false
      end

      # Ensure message and conversation are valid
      unless message&.conversation
        Rails.logger.error '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Invalid message or conversation, cannot maintain flow'
        return false
      end

      # Ensure conversation is still active
      conversation = message.conversation
      if conversation.status == 'resolved'
        Rails.logger.warn '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Conversation is resolved, but fallback will still be sent'
      end

      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Fallback flow validation passed'
      true
    end

    # Applies character limits and truncation based on message format
    # @param payload [Hash] The original payload
    # @param message_format [String] The message format (GENERIC_TEMPLATE, BUTTON_TEMPLATE, QUICK_REPLIES)
    # @return [Hash] Processed payload with character limits applied
    def apply_character_limits(payload, message_format)
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Applying character limits for format: #{message_format}"

      processed_payload = Marshal.load(Marshal.dump(payload))

      case message_format
      when 'GENERIC_TEMPLATE'
        apply_generic_template_limits(processed_payload)
      when 'BUTTON_TEMPLATE'
        apply_button_template_limits(processed_payload)
      when 'QUICK_REPLIES'
        apply_quick_replies_limits(processed_payload)
      else
        Rails.logger.warn "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Unknown format for character limits: #{message_format}"
        processed_payload
      end
    end

    # Applies character limits for Generic Template (80 characters for titles/subtitles)
    # @param payload [Hash] The payload to process
    # @return [Hash] Processed payload
    def apply_generic_template_limits(payload)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Applying Generic Template character limits (80 chars for titles/subtitles)'

      if payload['elements'].is_a?(Array)
        payload['elements'].each_with_index do |element, index|
          next unless element.is_a?(Hash)

          # Truncate title if needed
          if element['title'].present? && element['title'].length > 80
            original_length = element['title'].length
            element['title'] = truncate_text(element['title'], 80)
            Rails.logger.warn "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Generic Template element #{index} title truncated from #{original_length} to 80 characters"
          end

          # Truncate subtitle if needed
          next unless element['subtitle'].present? && element['subtitle'].length > 80

          original_length = element['subtitle'].length
          element['subtitle'] = truncate_text(element['subtitle'], 80)
          Rails.logger.warn "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Generic Template element #{index} subtitle truncated from #{original_length} to 80 characters"
        end
      end

      payload
    end

    # Applies character limits for Button Template (640 characters for text)
    # @param payload [Hash] The payload to process
    # @return [Hash] Processed payload
    def apply_button_template_limits(payload)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Applying Button Template character limits (640 chars for text)'

      if payload['text'].present? && payload['text'].length > 640
        original_length = payload['text'].length
        payload['text'] = truncate_text(payload['text'], 640)
        Rails.logger.warn "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Button Template text truncated from #{original_length} to 640 characters"
      end

      payload
    end

    # Applies character limits for Quick Replies (1000 characters for text)
    # @param payload [Hash] The payload to process
    # @return [Hash] Processed payload
    def apply_quick_replies_limits(payload)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Applying Quick Replies character limits (1000 chars for text)'

      if payload['text'].present? && payload['text'].length > 1000
        original_length = payload['text'].length
        payload['text'] = truncate_text(payload['text'], 1000)
        Rails.logger.warn "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Quick Replies text truncated from #{original_length} to 1000 characters"
      end

      payload
    end

    # Truncates text to specified limit and adds truncation notice
    # @param text [String] The text to truncate
    # @param limit [Integer] The character limit
    # @return [String] Truncated text with notice
    def truncate_text(text, limit)
      return text if text.length <= limit

      truncation_notice = ' (mensagem truncada)'
      available_chars = limit - truncation_notice.length

      # Ensure we have enough space for the notice
      return text[0, limit] if available_chars < 10

      truncated_text = text[0, available_chars].strip
      "#{truncated_text}#{truncation_notice}"
    end

    # Extracts meaningful text from failed rich message payloads
    # @param socialwise_data [Hash] The socialwise data
    # @return [String] Extracted text or generic fallback
    def extract_fallback_text(socialwise_data)
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Extracting fallback text from: #{socialwise_data.inspect}"

      return 'Message received' unless socialwise_data.is_a?(Hash)

      # Try SocialWise Flow format first (instagram wrapper)
      if socialwise_data['instagram'].present?
        instagram_data = socialwise_data['instagram']
        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Extracting from SocialWise Flow format'

        # Try text field first
        if instagram_data['text'].present?
          Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Using instagram.text field for fallback'
          return instagram_data['text']
        end

        # For Generic Template, try to extract from first element
        if instagram_data['elements'].is_a?(Array) && instagram_data['elements'].first.is_a?(Hash)
          element = instagram_data['elements'].first
          if element['title'].present?
            Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Using first element title for fallback'
            return element['title']
          end
        end
      end

      # Try Dialogflow format (payload wrapper)
      payload = socialwise_data['payload']
      if payload.is_a?(Hash)
        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Extracting from Dialogflow format'

        # Try to extract text from different payload types
        if payload['text'].present?
          Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Using payload.text field for fallback'
          return payload['text']
        end

        # For Generic Template, try to extract from first element
        if payload['elements'].is_a?(Array) && payload['elements'].first.is_a?(Hash)
          element = payload['elements'].first
          if element['title'].present?
            Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Using first element title for fallback'
            return element['title']
          end
        end
      end

      # Try direct format (no wrapper)
      if socialwise_data['text'].present?
        Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Using direct text field for fallback'
        return socialwise_data['text']
      end

      # For direct Generic Template format
      if socialwise_data['elements'].is_a?(Array) && socialwise_data['elements'].first.is_a?(Hash)
        element = socialwise_data['elements'].first
        if element['title'].present?
          Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Using direct element title for fallback'
          return element['title']
        end
      end

      # Generic fallback
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Using generic fallback text'
      'Message received'
    end

    # Create outgoing message with rich content directly to avoid flash effect
    # @param conversation [Conversation] The conversation to create the message in
    # @param instagram_payload [Hash] The Instagram API payload
    # @param original_payload [Hash] The original Dialogflow payload
    # @return [Message] The created message
    def create_rich_outgoing_message(conversation, instagram_payload, original_payload)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Creating rich outgoing message'

      # ALWAYS create rich messages - feature flag dependency removed
      # This is a core system feature and should always be enabled
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Creating rich message directly (feature flag dependency removed)'

      # Create message directly as rich cards to avoid flash effect
      create_rich_message_directly(conversation, instagram_payload, original_payload)
    end

    # Create message directly as rich cards
    # @param conversation [Conversation] The conversation to create the message in
    # @param instagram_payload [Hash] The Instagram API payload
    # @param original_payload [Hash] The original Dialogflow payload
    # @return [Message] The created message
    def create_rich_message_directly(conversation, instagram_payload, _original_payload)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Creating message directly as rich cards'

      # Use the Instagram Renderer Mapper to convert payload to Chatwoot format
      mapped_result = Messages::InstagramRendererMapper.map(instagram_payload)

      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Mapped content_type: #{mapped_result.content_type}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Mapped fallback_text: #{mapped_result.fallback_text}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Mapped content_attributes keys: #{mapped_result.content_attributes.keys}"

      # Create message directly with rich content
      message = conversation.messages.create!(
        content: mapped_result.fallback_text,
        content_type: mapped_result.content_type,
        content_attributes: mapped_result.content_attributes,
        message_type: :outgoing,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        additional_attributes: { skip_send_reply: true }
      )

      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Created rich message directly with ID: #{message.id}"
      Rails.logger.info "[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Message content_type: #{message.content_type}"

      message
    end

    # Create regular text message (existing behavior)
    # @param conversation [Conversation] The conversation to create the message in
    # @param original_payload [Hash] The original Dialogflow payload
    # @return [Message] The created message
    def create_text_message(conversation, original_payload)
      Rails.logger.info '[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Creating regular text message'

      conversation.messages.create!(
        content: extract_fallback_text({ 'payload' => original_payload }),
        message_type: :outgoing,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        additional_attributes: { skip_send_reply: true }
      )
    end
  end
end
