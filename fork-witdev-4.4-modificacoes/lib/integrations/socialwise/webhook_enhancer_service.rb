# frozen_string_literal: true

class Integrations::Socialwise::WebhookEnhancerService
  class << self
    # Enhances webhook payload with SocialWise data if the integration is active
    # @param payload [Hash] The original webhook payload
    # @param account [Account] The account to check for SocialWise integration
    # @return [Hash] Enhanced payload with socialwise-chatwit data or original payload
    def enhance_payload(payload, account)
      Rails.logger.info "[SOCIALWISE] enhance_payload called for account #{account&.id}"
      
      unless socialwise_active?(account)
        Rails.logger.info "[SOCIALWISE] Socialwise not active for account #{account&.id}, skipping enhancement"
        return payload
      end

      # Check if webhook enhancement is enabled
      unless webhook_enhancement_enabled?(account)
        Rails.logger.info "[SOCIALWISE] Webhook enhancement disabled for account #{account&.id}, skipping enhancement"
        return payload
      end
      
      Rails.logger.info "[SOCIALWISE] Starting payload enhancement for account #{account&.id}"

      enhanced_payload = payload.dup
      socialwise_data = build_socialwise_data(payload, account)
      
      # Validate the socialwise-chatwit data structure before adding to payload
      if validate_socialwise_data(socialwise_data)
        enhanced_payload['socialwise-chatwit'] = socialwise_data
        
        # Also add flat structure for easier webhook consumption
        enhanced_payload = add_flat_socialwise_data(enhanced_payload, socialwise_data)
      else
        Rails.logger.warn "[SOCIALWISE] Validation failed for socialwise-chatwit data, using fallback"
        fallback_data = build_fallback_data_structure(StandardError.new('Validation failed'), account)
        enhanced_payload['socialwise-chatwit'] = fallback_data
        enhanced_payload = add_flat_socialwise_data(enhanced_payload, fallback_data)
      end
      
      enhanced_payload
    rescue => e
      Rails.logger.error "[SOCIALWISE] Enhancement failed: #{e.message}"
      Rails.logger.error "[SOCIALWISE] Backtrace: #{e.backtrace.join('\n')}"
      payload # Return original payload on error
    end

    # Add flat socialwise data to payload for easier webhook consumption
    # @param payload [Hash] The enhanced payload
    # @param socialwise_data [Hash] The socialwise-chatwit data
    # @return [Hash] Payload with flat socialwise fields
    def add_flat_socialwise_data(payload, socialwise_data)
      flat_payload = payload.dup
      
      # WhatsApp identifiers (removendo duplicação - mantendo apenas wamid)
      if socialwise_data['whatsapp_identifiers']
        flat_payload['wamid'] = socialwise_data['whatsapp_identifiers']['wamid']
        flat_payload['contact_source'] = socialwise_data['whatsapp_identifiers']['contact_source']
      end
      
      # Contact data
      if socialwise_data['contact_data']
        flat_payload['contact_name'] = socialwise_data['contact_data']['name']
        flat_payload['contact_phone'] = socialwise_data['contact_data']['phone_number']
        flat_payload['contact_email'] = socialwise_data['contact_data']['email']
        flat_payload['contact_identifier'] = socialwise_data['contact_data']['identifier']
        flat_payload['contact_id'] = socialwise_data['contact_data']['id']
        
        # Merge custom attributes at root level for backward compatibility
        if socialwise_data['contact_data']['custom_attributes'].is_a?(Hash)
          flat_payload.merge!(socialwise_data['contact_data']['custom_attributes'])
        end
      end
      
      # Conversation data
      if socialwise_data['conversation_data']
        flat_payload['conversation_id'] = socialwise_data['conversation_data']['id']
        flat_payload['conversation_status'] = socialwise_data['conversation_data']['status']
        flat_payload['conversation_assignee_id'] = socialwise_data['conversation_data']['assignee_id']
        flat_payload['conversation_created_at'] = socialwise_data['conversation_data']['created_at']
        flat_payload['conversation_updated_at'] = socialwise_data['conversation_data']['updated_at']
      end
      
      # Message data
      if socialwise_data['message_data']
        flat_payload['message_id'] = socialwise_data['message_data']['id']
        flat_payload['message_content'] = socialwise_data['message_data']['content']
        flat_payload['message_type'] = socialwise_data['message_data']['message_type']
        flat_payload['message_created_at'] = socialwise_data['message_data']['created_at']
        flat_payload['message_content_type'] = socialwise_data['message_data']['content_type']
        
        # Interactive data (button/list IDs)
        if socialwise_data['message_data']['interactive_data']
          interactive_data = socialwise_data['message_data']['interactive_data']
          flat_payload['button_id'] = interactive_data['button_id']
          flat_payload['button_title'] = interactive_data['button_title']
          flat_payload['list_id'] = interactive_data['list_id']
          flat_payload['list_title'] = interactive_data['list_title']
          flat_payload['list_description'] = interactive_data['list_description']
          flat_payload['interaction_type'] = interactive_data['interaction_type']
        end

        # Instagram postback/quick_reply data
        if socialwise_data['message_data']['instagram_data']
          instagram_data = socialwise_data['message_data']['instagram_data']
          flat_payload['postback_payload'] = instagram_data['postback_payload']
          flat_payload['quick_reply_payload'] = instagram_data['quick_reply_payload']
          flat_payload['interaction_type'] = instagram_data['interaction_type']
        end
      end
      
      # Inbox data
      if socialwise_data['inbox_data']
        flat_payload['inbox_id'] = socialwise_data['inbox_data']['id']
        flat_payload['inbox_name'] = socialwise_data['inbox_data']['name']
        flat_payload['channel_type'] = socialwise_data['inbox_data']['channel_type']
      end
      
      # Account data
      if socialwise_data['account_data']
        flat_payload['account_id'] = socialwise_data['account_data']['id']
        flat_payload['account_name'] = socialwise_data['account_data']['name']
      end
      
      # WhatsApp API key, phone number ID, business ID and metadata
      flat_payload['whatsapp_api_key'] = socialwise_data['whatsapp_api_key']
      flat_payload['phone_number_id'] = socialwise_data['whatsapp_phone_number_id']
      flat_payload['business_id'] = socialwise_data['whatsapp_business_id']
      
      if socialwise_data['metadata']
        flat_payload['socialwise_active'] = socialwise_data['metadata']['socialwise_active']
        flat_payload['is_whatsapp_channel'] = socialwise_data['metadata']['is_whatsapp_channel']
        flat_payload['has_whatsapp_api_key'] = socialwise_data['metadata']['has_whatsapp_api_key']
        flat_payload['payload_version'] = socialwise_data['metadata']['payload_version']
        flat_payload['timestamp'] = socialwise_data['metadata']['timestamp']
      end
      
      Rails.logger.info "[SOCIALWISE] Flat webhook payload enhanced with #{flat_payload.keys.count} total fields"
      
      flat_payload
    rescue => e
      Rails.logger.error "[SOCIALWISE] Error adding flat socialwise data: #{e.class}: #{e.message}"
      payload
    end

    # Checks if SocialWise integration is enabled for the given account
    # @param account [Account] The account to check
    # @return [Boolean] true if SocialWise is active, false otherwise
    def socialwise_active?(account)
      Rails.logger.info "[SOCIALWISE] Checking if socialwise is active for account #{account&.id}"
      
      hook = account.hooks.find_by(app_id: 'socialwise_chatwit', status: 'enabled')
      unless hook
        Rails.logger.info "[SOCIALWISE] No enabled socialwise hook found for account #{account&.id}"
        return false
      end

      enabled = hook.settings&.dig('enabled')
      is_active = enabled == true || enabled == 'true'
      Rails.logger.info "[SOCIALWISE] Hook found with enabled=#{enabled}, active=#{is_active}"
      is_active
    rescue => e
      Rails.logger.error "[SOCIALWISE] State check failed: #{e.message}"
      false
    end

    # Checks if webhook enhancement is enabled for the given account
    # @param account [Account] The account to check
    # @return [Boolean] true if webhook enhancement is enabled, false otherwise
    def webhook_enhancement_enabled?(account)
      Rails.logger.info "[SOCIALWISE] Checking webhook enhancement for account #{account&.id}"
      
      hook = account.hooks.find_by(app_id: 'socialwise_chatwit', status: 'enabled')
      unless hook
        Rails.logger.info "[SOCIALWISE] No enabled socialwise hook found for webhook enhancement check"
        return false
      end

      # Check if webhook enhancement is specifically enabled
      webhook_enabled = hook.settings&.dig('webhook_enhancement_enabled')
      
      # Default to true for backward compatibility if not set
      if webhook_enabled.nil?
        Rails.logger.info "[SOCIALWISE] webhook_enhancement_enabled not set, defaulting to true"
        return true
      end
      
      is_enabled = webhook_enabled == true || webhook_enabled == 'true'
      Rails.logger.info "[SOCIALWISE] webhook_enhancement_enabled=#{webhook_enabled}, enabled=#{is_enabled}"
      is_enabled
    rescue => e
      Rails.logger.error "[SOCIALWISE] Webhook enhancement check failed: #{e.message}"
      true # Default to enabled on error for backward compatibility
    end

    private

    # Builds the socialwise-chatwit data structure from the webhook payload
    # @param payload [Hash] The webhook payload
    # @param account [Account] The account
    # @return [Hash] The socialwise-chatwit data structure
    def build_socialwise_data(payload, account)
      Rails.logger.info "[SOCIALWISE] Building socialwise-chatwit data for account #{account&.id}"
      Rails.logger.info "[SOCIALWISE] Payload structure: #{payload.keys.inspect}"
      
      # Extract core objects from payload with error handling
      message = safe_extract_message_from_payload(payload)
      conversation = safe_extract_conversation_from_payload(payload)
      contact = safe_extract_contact_from_payload(payload)
      inbox = safe_extract_inbox_from_payload(payload)

      Rails.logger.info "[SOCIALWISE] Extracted objects - Message: #{message.class}, Conversation: #{conversation.class}, Contact: #{contact.class}, Inbox: #{inbox.class}"

      # Build comprehensive data structure with individual error handling
      data = {}
      
      data['whatsapp_identifiers'] = build_whatsapp_identifiers(message, contact)
      data['contact_data'] = build_contact_data(contact)
      data['conversation_data'] = build_conversation_data(conversation)
      data['message_data'] = build_message_data(message)
      data['inbox_data'] = build_inbox_data(inbox)
      data['account_data'] = build_account_data(account)
      data['metadata'] = build_metadata(inbox)
      data['whatsapp_api_key'] = extract_whatsapp_api_key(inbox)
      data['whatsapp_phone_number_id'] = extract_whatsapp_phone_number_id(inbox)
      data['whatsapp_business_id'] = extract_whatsapp_business_id(inbox)
      
      Rails.logger.info "[SOCIALWISE] Successfully built socialwise-chatwit data"
      data
    rescue => e
      Rails.logger.error "[SOCIALWISE] Critical error building socialwise-chatwit data: #{e.class}: #{e.message}"
      Rails.logger.error "[SOCIALWISE] Backtrace: #{e.backtrace.join('\n')}"
      Rails.logger.error "[SOCIALWISE] Payload keys: #{payload&.keys&.inspect}"
      Rails.logger.error "[SOCIALWISE] Account ID: #{account&.id}"
      
      # Return comprehensive fallback data structure
      build_fallback_data_structure(e, account)
    end

    # Safe extraction methods with error handling
    
    # Extract message object from payload with error handling
    def safe_extract_message_from_payload(payload)
      extract_message_from_payload(payload)
    rescue => e
      Rails.logger.error "[SOCIALWISE] Error extracting message from payload: #{e.class}: #{e.message}"
      nil
    end

    # Extract conversation object from payload with error handling
    def safe_extract_conversation_from_payload(payload)
      extract_conversation_from_payload(payload)
    rescue => e
      Rails.logger.error "[SOCIALWISE] Error extracting conversation from payload: #{e.class}: #{e.message}"
      nil
    end

    # Extract contact object from payload with error handling
    def safe_extract_contact_from_payload(payload)
      extract_contact_from_payload(payload)
    rescue => e
      Rails.logger.error "[SOCIALWISE] Error extracting contact from payload: #{e.class}: #{e.message}"
      nil
    end

    # Extract inbox object from payload with error handling
    def safe_extract_inbox_from_payload(payload)
      extract_inbox_from_payload(payload)
    rescue => e
      Rails.logger.error "[SOCIALWISE] Error extracting inbox from payload: #{e.class}: #{e.message}"
      nil
    end

    # Original extraction methods (kept for backward compatibility)
    
    # Extract message object from payload
    def extract_message_from_payload(payload)
      Rails.logger.info "[SOCIALWISE] Extracting message from payload with keys: #{payload.keys.inspect}"
      
      # For webhook payloads, the message data is at the root level
      if payload.key?('id') && payload.key?('content') && payload.key?('message_type')
        Rails.logger.info "[SOCIALWISE] Creating mock message from root level data"
        return create_mock_message_from_webhook_data(payload)
      end
      
      # For Dialogflow payloads, look for nested message object
      message = payload[:message] || payload['message']
      
      # If it's a webhook_data format (Hash), convert to a mock object
      if message.is_a?(Hash)
        Rails.logger.info "[SOCIALWISE] Creating mock message from nested message data"
        return create_mock_message_from_webhook_data(message)
      end
      
      # If message is nil, try to extract from the payload structure
      if message.nil?
        Rails.logger.warn "[SOCIALWISE] Message is nil, attempting to extract from payload structure"
        Rails.logger.info "[SOCIALWISE] Payload has id: #{payload.key?(:id)}, content: #{payload.key?(:content)}, message_type: #{payload.key?(:message_type)}"
        # The payload might have the message data directly
        return create_mock_message_from_webhook_data(payload)
      end
      
      Rails.logger.info "[SOCIALWISE] Returning message as-is: #{message.class}"
      message
    end

    # Extract conversation object from payload
    def extract_conversation_from_payload(payload)
      # For webhook payloads, look for conversation data
      conversation = payload[:conversation] || payload['conversation']
      
      # If it's a webhook_data format (Hash), convert to a mock object
      if conversation.is_a?(Hash)
        return create_mock_conversation_from_webhook_data(conversation)
      end
      
      conversation
    end

    # Extract contact object from payload
    def extract_contact_from_payload(payload)
      # For webhook payloads, contact might be nested in sender or conversation
      contact = payload[:contact] || payload['contact']
      
      # If not found, try to get from sender
      if contact.nil?
        contact = payload[:sender] || payload['sender']
      end
      
      # If still not found, try to get from conversation.meta.sender
      if contact.nil? && payload['conversation'].is_a?(Hash)
        contact = payload['conversation'].dig('meta', 'sender')
      end
      
      # If it's a webhook_data format (Hash), convert to a mock object
      if contact.is_a?(Hash)
        return create_mock_contact_from_webhook_data(contact)
      end
      
      contact
    end

    # Extract inbox object from payload
    def extract_inbox_from_payload(payload)
      # For webhook payloads, look for inbox data
      inbox = payload[:inbox] || payload['inbox']
      
      # If it's a webhook_data format (Hash), convert to a mock object
      if inbox.is_a?(Hash)
        # Pass the full payload as conversation_data since channel info is at root level
        conversation_data = payload
        return create_mock_inbox_from_webhook_data(inbox, conversation_data)
      end
      
      inbox
    end

    # Create mock objects from webhook_data format
    def create_mock_message_from_webhook_data(webhook_data)
      OpenStruct.new(
        id: webhook_data[:id] || webhook_data['id'],
        content: webhook_data[:content] || webhook_data['content'],
        content_type: webhook_data[:content_type] || webhook_data['content_type'],
        message_type: webhook_data[:message_type] || webhook_data['message_type'],
        created_at: parse_timestamp(webhook_data[:created_at] || webhook_data['created_at']),
        source_id: webhook_data[:source_id] || webhook_data['source_id'],
        content_attributes: webhook_data[:content_attributes] || webhook_data['content_attributes'] || {}
      )
    end

    def create_mock_conversation_from_webhook_data(webhook_data)
      # Extract contact from meta.sender if available
      contact_data = webhook_data.dig('meta', 'sender') || webhook_data[:contact] || webhook_data['contact'] || {}
      
      OpenStruct.new(
        id: webhook_data[:id] || webhook_data['id'],
        status: webhook_data[:status] || webhook_data['status'],
        assignee_id: webhook_data[:assignee_id] || webhook_data['assignee_id'],
        created_at: parse_timestamp(webhook_data[:created_at] || webhook_data['created_at']),
        updated_at: parse_timestamp(webhook_data[:updated_at] || webhook_data['updated_at']),
        contact: create_mock_contact_from_webhook_data(contact_data)
      )
    end

    def create_mock_contact_from_webhook_data(webhook_data)
      OpenStruct.new(
        id: webhook_data[:id] || webhook_data['id'],
        name: webhook_data[:name] || webhook_data['name'],
        phone_number: webhook_data[:phone_number] || webhook_data['phone_number'],
        email: webhook_data[:email] || webhook_data['email'],
        identifier: webhook_data[:identifier] || webhook_data['identifier'],
        custom_attributes: webhook_data[:custom_attributes] || webhook_data['custom_attributes'] || {},
        contact_inboxes: []
      )
    end

    def create_mock_inbox_from_webhook_data(webhook_data, conversation_data = nil)
      # For webhook payloads, we need to determine channel_type from conversation data
      channel_type = nil
      provider_config = {}
      
      Rails.logger.info "[SOCIALWISE] Creating mock inbox - webhook_data keys: #{webhook_data.keys.inspect}"
      Rails.logger.info "[SOCIALWISE] Conversation data present: #{conversation_data.present?}"
      
      # Try to get channel type from conversation if available
      if conversation_data
        Rails.logger.info "[SOCIALWISE] Conversation data keys: #{conversation_data.keys.inspect}" if conversation_data.respond_to?(:keys)
        Rails.logger.info "[SOCIALWISE] Conversation data class: #{conversation_data.class}"
        
        # Try different ways to get channel type
        if conversation_data.respond_to?(:channel)
          channel_type = conversation_data.channel
          Rails.logger.info "[SOCIALWISE] Channel type from conversation_data.channel: #{channel_type}"
        elsif conversation_data.is_a?(Hash) && conversation_data['channel']
          channel_type = conversation_data['channel']
          Rails.logger.info "[SOCIALWISE] Channel type from conversation_data['channel']: #{channel_type}"
        elsif conversation_data.is_a?(Hash) && conversation_data[:channel]
          channel_type = conversation_data[:channel]
          Rails.logger.info "[SOCIALWISE] Channel type from conversation_data[:channel]: #{channel_type}"
        end
      end
      
      # If still not found, try from webhook_data nested conversation
      if channel_type.nil? && webhook_data.dig('conversation', 'channel')
        channel_type = webhook_data['conversation']['channel']
        Rails.logger.info "[SOCIALWISE] Channel type from webhook_data.conversation: #{channel_type}"
      end
      
      # CORREÇÃO: Buscar channel no nível raiz do payload (onde realmente está nos webhooks)
      if channel_type.nil? && conversation_data.is_a?(Hash)
        if conversation_data['channel']
          channel_type = conversation_data['channel']
          Rails.logger.info "[SOCIALWISE] Channel type from root level payload['channel']: #{channel_type}"
        elsif conversation_data[:channel]
          channel_type = conversation_data[:channel]
          Rails.logger.info "[SOCIALWISE] Channel type from root level payload[:channel]: #{channel_type}"
        end
      end
      
      # Get inbox ID for database lookup
      inbox_id = webhook_data[:id] || webhook_data['id']
      Rails.logger.info "[SOCIALWISE] Inbox ID: #{inbox_id}, Channel Type: #{channel_type}"
      
      # CORREÇÃO CRÍTICA: Se não conseguimos determinar o channel_type do payload, 
      # vamos buscar no cache ou banco de dados usando o inbox_id
      if inbox_id && channel_type.nil?
        Rails.logger.info "[SOCIALWISE] Channel type not found in payload, fetching from cache/database for inbox #{inbox_id}"
        
        # Diagnose cache before fetching
        diagnose_cache_issues(inbox_id) if Rails.logger.level <= Logger::DEBUG
        
        channel_type = get_cached_channel_type(inbox_id)
        Rails.logger.info "[SOCIALWISE] Channel type from cache/database: #{channel_type}"
      end
      
      if inbox_id && channel_type == 'Channel::Whatsapp'
        Rails.logger.info "[SOCIALWISE] Fetching provider config for WhatsApp inbox #{inbox_id}"
        provider_config = get_cached_provider_config(inbox_id)
        Rails.logger.info "[SOCIALWISE] Provider config keys: #{provider_config.keys.inspect}"
      else
        Rails.logger.warn "[SOCIALWISE] Not fetching provider config - inbox_id: #{inbox_id}, channel_type: #{channel_type}"
      end
      
      mock_channel = OpenStruct.new(
        provider_config: provider_config
      )
      
      OpenStruct.new(
        id: inbox_id,
        name: webhook_data[:name] || webhook_data['name'],
        channel_type: channel_type,
        channel: mock_channel
      )
    end

    # Get channel type with dedicated SocialWise cache to avoid database hits
    def get_cached_channel_type(inbox_id)
      Integrations::Socialwise::CacheManager.channel_type(inbox_id) do
        begin
          real_inbox = Inbox.find(inbox_id)
          if real_inbox
            Rails.logger.info "[SOCIALWISE] Fetched channel_type from database for inbox #{inbox_id}: #{real_inbox.channel_type}"
            real_inbox.channel_type
          else
            Rails.logger.warn "[SOCIALWISE] Inbox #{inbox_id} not found in database"
            nil
          end
        rescue => e
          Rails.logger.warn "[SOCIALWISE] Could not fetch inbox #{inbox_id} from database: #{e.message}"
          nil
        end
      end
    end

    # Get provider config with dedicated SocialWise cache to avoid database hits
    def get_cached_provider_config(inbox_id)
      Integrations::Socialwise::CacheManager.provider_config(inbox_id) do
        begin
          real_inbox = Inbox.find(inbox_id)
          if real_inbox&.channel&.provider_config
            Rails.logger.info "[SOCIALWISE] Fetched provider_config from database for inbox #{inbox_id}"
            real_inbox.channel.provider_config
          else
            Rails.logger.warn "[SOCIALWISE] No provider config found for inbox #{inbox_id}"
            {}
          end
        rescue => e
          Rails.logger.warn "[SOCIALWISE] Could not fetch real inbox #{inbox_id}: #{e.message}"
          {}
        end
      end
    end

    # Clear cache for a specific inbox (useful when inbox is updated)
    def clear_inbox_cache(inbox_id)
      Integrations::Socialwise::CacheManager.clear_inbox_cache(inbox_id)
    end

    # Legacy method for backward compatibility
    def clear_provider_config_cache(inbox_id)
      clear_inbox_cache(inbox_id)
    end

    # Preload cache for WhatsApp inboxes to improve performance
    def preload_whatsapp_inbox_cache(account_id = nil)
      Integrations::Socialwise::CacheManager.preload_whatsapp_cache(account_id)
    end

    # Force preload cache for a specific inbox
    def force_preload_inbox_cache(inbox_id)
      Rails.logger.info "[SOCIALWISE] Force preloading cache for inbox #{inbox_id}"
      
      begin
        inbox = Inbox.includes(:channel).find(inbox_id)
        
        # Force cache channel type
        Integrations::Socialwise::CacheManager.channel_type(inbox.id) { inbox.channel_type }
        Rails.logger.info "[SOCIALWISE] Force cached channel_type for inbox #{inbox.id}: #{inbox.channel_type}"
        
        # Force cache provider config if available
        if inbox.channel&.provider_config
          Integrations::Socialwise::CacheManager.provider_config(inbox.id) { inbox.channel.provider_config }
          Rails.logger.info "[SOCIALWISE] Force cached provider_config for inbox #{inbox.id}"
        end
        
        # Force cache complete inbox data
        Integrations::Socialwise::CacheManager.inbox_data(inbox.id) do
          {
            id: inbox.id,
            name: inbox.name,
            channel_type: inbox.channel_type,
            provider_config: inbox.channel&.provider_config || {}
          }
        end
        
        Rails.logger.info "[SOCIALWISE] Force preload completed for inbox #{inbox.id}"
        true
      rescue => e
        Rails.logger.error "[SOCIALWISE] Failed to force preload cache for inbox #{inbox_id}: #{e.message}"
        false
      end
    end

    # Get cache statistics using the dedicated cache manager
    def get_cache_stats
      Integrations::Socialwise::CacheManager.cache_stats
    end

    # Diagnose cache issues using the dedicated cache manager
    def diagnose_cache_issues(inbox_id)
      Rails.logger.info "[SOCIALWISE] Diagnosing cache issues for inbox #{inbox_id}"
      
      # Get cache stats
      stats = Integrations::Socialwise::CacheManager.cache_stats
      Rails.logger.info "[SOCIALWISE] Cache statistics: #{stats}"
      
      # Test cache health
      health = Integrations::Socialwise::CacheManager.health_check
      Rails.logger.info "[SOCIALWISE] Cache health check: #{health}"
      
      # Try to get current cached values
      cached_channel = Integrations::Socialwise::CacheManager.channel_type(inbox_id) { nil }
      cached_provider = Integrations::Socialwise::CacheManager.provider_config(inbox_id) { nil }
      
      Rails.logger.info "[SOCIALWISE] Current cached values - Channel: #{cached_channel}, Provider: #{cached_provider.present?}"
    rescue => e
      Rails.logger.error "[SOCIALWISE] Error diagnosing cache: #{e.message}"
    end

    # Legacy method name for backward compatibility
    def diagnose_cache_issues(inbox_id)
      Rails.logger.info "[SOCIALWISE] === CACHE DIAGNOSIS FOR INBOX #{inbox_id} ==="
      
      # Check cache store type
      Rails.logger.info "[SOCIALWISE] Cache store: #{Rails.cache.class.name}"
      
      # Check if cache keys exist
      channel_key = "socialwise:channel_type:#{inbox_id}"
      provider_key = "socialwise:provider_config:#{inbox_id}"
      
      channel_cached = Rails.cache.read(channel_key)
      provider_cached = Rails.cache.read(provider_key)
      
      Rails.logger.info "[SOCIALWISE] Channel type cached: #{channel_cached ? 'YES' : 'NO'} (#{channel_cached})"
      Rails.logger.info "[SOCIALWISE] Provider config cached: #{provider_cached ? 'YES' : 'NO'}"
      
      # Test cache write/read
      test_key = "socialwise:test:#{inbox_id}:#{Time.current.to_i}"
      test_value = "test_#{rand(1000)}"
      
      Rails.cache.write(test_key, test_value, expires_in: 1.hour)
      read_value = Rails.cache.read(test_key)
      
      cache_working = test_value == read_value
      Rails.logger.info "[SOCIALWISE] Cache write/read test: #{cache_working ? 'PASSED' : 'FAILED'}"
      Rails.logger.info "[SOCIALWISE] Written: #{test_value}, Read: #{read_value}"
      
      # Clean up test key
      Rails.cache.delete(test_key)
      
      # Get current stats
      stats = get_cache_stats
      Rails.logger.info "[SOCIALWISE] Current cache stats: #{stats}"
      
      Rails.logger.info "[SOCIALWISE] === END CACHE DIAGNOSIS ==="
      
      {
        cache_store: Rails.cache.class.name,
        channel_cached: channel_cached.present?,
        provider_cached: provider_cached.present?,
        cache_working: cache_working,
        stats: stats
      }
    rescue => e
      Rails.logger.error "[SOCIALWISE] Cache diagnosis failed: #{e.message}"
      { error: e.message }
    end

    def parse_timestamp(timestamp)
      return nil unless timestamp
      return timestamp if timestamp.is_a?(Time)
      
      # Handle Unix timestamps (integers)
      if timestamp.is_a?(Integer) || timestamp.is_a?(Float)
        return Time.at(timestamp)
      end
      
      # Handle string timestamps with timezone
      begin
        parsed_time = Time.parse(timestamp.to_s)
        # Convert to ISO8601 format without timezone for validation
        return parsed_time.utc
      rescue => e
        Rails.logger.warn "[SOCIALWISE] Could not parse timestamp #{timestamp}: #{e.message}"
        nil
      end
    end

    # Extract WhatsApp API key from inbox channel
    def extract_whatsapp_api_key(inbox)
      return nil unless inbox&.channel_type == 'Channel::Whatsapp'
      
      begin
        provider_config = get_provider_config(inbox)
        api_key = provider_config&.dig('api_key')
        Rails.logger.info "[SOCIALWISE] WhatsApp API key extracted: #{api_key.present? ? 'Present' : 'Not found'}"
        api_key
      rescue => e
        Rails.logger.error "[SOCIALWISE] Error extracting WhatsApp API key: #{e.class}: #{e.message}"
        nil
      end
    end

    # Extract WhatsApp phone number ID from inbox channel
    def extract_whatsapp_phone_number_id(inbox)
      return nil unless inbox&.channel_type == 'Channel::Whatsapp'
      
      begin
        provider_config = get_provider_config(inbox)
        phone_number_id = provider_config&.dig('phone_number_id')
        Rails.logger.info "[SOCIALWISE] WhatsApp phone_number_id extracted: #{phone_number_id.present? ? 'Present' : 'Not found'}"
        phone_number_id
      rescue => e
        Rails.logger.error "[SOCIALWISE] Error extracting WhatsApp phone_number_id: #{e.class}: #{e.message}"
        nil
      end
    end

    # Extract WhatsApp business account ID from inbox channel
    def extract_whatsapp_business_id(inbox)
      return nil unless inbox&.channel_type == 'Channel::Whatsapp'
      
      begin
        provider_config = get_provider_config(inbox)
        business_id = provider_config&.dig('business_account_id')
        Rails.logger.info "[SOCIALWISE] WhatsApp business_account_id extracted: #{business_id.present? ? 'Present' : 'Not found'}"
        business_id
      rescue => e
        Rails.logger.error "[SOCIALWISE] Error extracting WhatsApp business_account_id: #{e.class}: #{e.message}"
        nil
      end
    end

    # Get provider config from inbox, handling both ActiveRecord and mock objects
    def get_provider_config(inbox)
      return nil unless inbox
      
      if inbox.respond_to?(:channel) && inbox.channel.respond_to?(:provider_config)
        inbox.channel.provider_config
      elsif inbox.is_a?(OpenStruct) && inbox.channel.is_a?(OpenStruct)
        # For mock objects, try to fetch from database if we have an ID
        if inbox.id && inbox.channel_type == 'Channel::Whatsapp'
          begin
            real_inbox = Inbox.find(inbox.id)
            return real_inbox.channel.provider_config if real_inbox&.channel
          rescue => e
            Rails.logger.warn "[SOCIALWISE] Could not fetch real inbox #{inbox.id}: #{e.message}"
          end
        end
        inbox.channel.provider_config
      else
        nil
      end
    end

    # Build WhatsApp identifiers section
    def build_whatsapp_identifiers(message, contact)
      unless message && contact
        Rails.logger.debug "[SOCIALWISE] Missing message or contact for WhatsApp identifiers"
        return {
          'wamid' => nil,
          'whatsapp_id' => nil,
          'contact_source' => nil
        }
      end

      source_id = message.source_id
      
      # Handle contact_source extraction for both ActiveRecord and mock objects
      contact_source = nil
      if contact.respond_to?(:contact_inboxes) && contact.contact_inboxes.respond_to?(:first)
        contact_source = contact.contact_inboxes&.first&.source_id
      end
      
      {
        'wamid' => source_id,
        'whatsapp_id' => source_id,
        'contact_source' => contact_source
      }
    rescue => e
      Rails.logger.error "[SOCIALWISE] Error building WhatsApp identifiers: #{e.class}: #{e.message}"
      Rails.logger.error "[SOCIALWISE] Message ID: #{message&.id}, Contact ID: #{contact&.id}"
      {
        'wamid' => nil,
        'whatsapp_id' => nil,
        'contact_source' => nil
      }
    end

    # Build contact data section
    def build_contact_data(contact)
      unless contact
        Rails.logger.debug "[SOCIALWISE] No contact provided for contact data"
        return {
          'id' => nil,
          'name' => nil,
          'phone_number' => nil,
          'email' => nil,
          'identifier' => nil,
          'custom_attributes' => {}
        }
      end

      {
        'id' => contact.id,
        'name' => contact.name,
        'phone_number' => contact.phone_number,
        'email' => contact.email,
        'identifier' => contact.identifier,
        'custom_attributes' => contact.custom_attributes || {}
      }
    rescue => e
      Rails.logger.error "[SOCIALWISE] Error building contact data: #{e.class}: #{e.message}"
      Rails.logger.error "[SOCIALWISE] Contact ID: #{contact&.id}, Contact class: #{contact&.class}"
      {
        'id' => contact&.id,
        'name' => nil,
        'phone_number' => nil,
        'email' => nil,
        'identifier' => nil,
        'custom_attributes' => {}
      }
    end

    # Build conversation data section
    def build_conversation_data(conversation)
      unless conversation
        Rails.logger.debug "[SOCIALWISE] No conversation provided for conversation data"
        return {
          'id' => nil,
          'status' => nil,
          'assignee_id' => nil,
          'created_at' => nil,
          'updated_at' => nil
        }
      end

      {
        'id' => conversation.id,
        'status' => conversation.status,
        'assignee_id' => conversation.assignee_id,
        'created_at' => conversation.created_at&.iso8601,
        'updated_at' => conversation.updated_at&.iso8601
      }
    rescue => e
      Rails.logger.error "[SOCIALWISE] Error building conversation data: #{e.class}: #{e.message}"
      Rails.logger.error "[SOCIALWISE] Conversation ID: #{conversation&.id}, Conversation class: #{conversation&.class}"
      {
        'id' => conversation&.id,
        'status' => nil,
        'assignee_id' => nil,
        'created_at' => nil,
        'updated_at' => nil
      }
    end

    # Build message data section
    def build_message_data(message)
      unless message
        Rails.logger.debug "[SOCIALWISE] No message provided for message data"
        return {
          'id' => nil,
          'content' => nil,
          'content_type' => nil,
          'message_type' => nil,
          'created_at' => nil,
          'interactive_data' => {}
        }
      end

      message_data = {
        'id' => message.id,
        'content' => message.content,
        'content_type' => message.content_type,
        'message_type' => message.message_type,
        'created_at' => message.created_at&.iso8601,
        'interactive_data' => extract_interactive_data_from_message(message),
        'instagram_data' => extract_instagram_data_from_message(message)
      }
      
      Rails.logger.info "[SOCIALWISE] Message interactive data: #{message_data['interactive_data']}" if message_data['interactive_data'].any?
      Rails.logger.info "[SOCIALWISE] Message instagram data: #{message_data['instagram_data']}" if message_data['instagram_data'].any?
      
      message_data
    rescue => e
      Rails.logger.error "[SOCIALWISE] Error building message data: #{e.class}: #{e.message}"
      Rails.logger.error "[SOCIALWISE] Message ID: #{message&.id}, Message class: #{message&.class}"
      {
        'id' => message&.id,
        'content' => nil,
        'content_type' => nil,
        'message_type' => nil,
        'created_at' => nil,
        'interactive_data' => {}
      }
    end

    # Extract interactive data from message content_attributes
    def extract_interactive_data_from_message(message)
      return {} unless message&.content_attributes.is_a?(Hash)
      
      interactive_data = {}
      content_attrs = message.content_attributes.with_indifferent_access
      
      # Extract button reply data
      if content_attrs[:button_reply]
        interactive_data['button_id'] = content_attrs[:button_reply][:id]
        interactive_data['button_title'] = content_attrs[:button_reply][:title]
        interactive_data['interaction_type'] = 'button_reply'
      end
      
      # Extract list reply data
      if content_attrs[:list_reply]
        interactive_data['list_id'] = content_attrs[:list_reply][:id]
        interactive_data['list_title'] = content_attrs[:list_reply][:title]
        interactive_data['list_description'] = content_attrs[:list_reply][:description]
        interactive_data['interaction_type'] = 'list_reply'
      end
      
      # Add interaction type if available
      if content_attrs[:interaction_type]
        interactive_data['interaction_type'] = content_attrs[:interaction_type]
      end
      
      interactive_data
    rescue => e
      Rails.logger.error "[SOCIALWISE] Error extracting interactive data from message: #{e.class}: #{e.message}"
      {}
    end

    # Extract Instagram postback/quick_reply data from message content_attributes
    def extract_instagram_data_from_message(message)
      return {} unless message&.content_attributes.is_a?(Hash)
      
      instagram_data = {}
      content_attrs = message.content_attributes.with_indifferent_access
      
      # Extract postback data
      if content_attrs[:postback_payload]
        instagram_data['postback_payload'] = content_attrs[:postback_payload]
        instagram_data['interaction_type'] = 'postback'
      end
      
      # Extract quick_reply data
      if content_attrs[:quick_reply_payload]
        instagram_data['quick_reply_payload'] = content_attrs[:quick_reply_payload]
        instagram_data['interaction_type'] = 'quick_reply'
      end
      
      instagram_data
    rescue => e
      Rails.logger.error "[SOCIALWISE] Error extracting Instagram data from message: #{e.class}: #{e.message}"
      {}
    end

    # Build inbox data section
    def build_inbox_data(inbox)
      unless inbox
        Rails.logger.debug "[SOCIALWISE] No inbox provided for inbox data"
        return {
          'id' => nil,
          'name' => nil,
          'channel_type' => nil
        }
      end

      {
        'id' => inbox.id,
        'name' => inbox.name,
        'channel_type' => inbox.channel_type
      }
    rescue => e
      Rails.logger.error "[SOCIALWISE] Error building inbox data: #{e.class}: #{e.message}"
      Rails.logger.error "[SOCIALWISE] Inbox ID: #{inbox&.id}, Inbox class: #{inbox&.class}"
      {
        'id' => inbox&.id,
        'name' => nil,
        'channel_type' => nil
      }
    end

    # Build account data section
    def build_account_data(account)
      unless account
        Rails.logger.debug "[SOCIALWISE] No account provided for account data"
        return {
          'id' => nil,
          'name' => nil
        }
      end

      {
        'id' => account.id,
        'name' => account.name
      }
    rescue => e
      Rails.logger.error "[SOCIALWISE] Error building account data: #{e.class}: #{e.message}"
      Rails.logger.error "[SOCIALWISE] Account ID: #{account&.id}, Account class: #{account&.class}"
      {
        'id' => account&.id,
        'name' => nil
      }
    end

    # Build metadata section
    def build_metadata(inbox)
      is_whatsapp_channel = inbox&.channel_type == 'Channel::Whatsapp' ||
                           inbox&.channel&.class&.name == 'Channel::Whatsapp'

      {
        'socialwise_active' => true,
        'is_whatsapp_channel' => is_whatsapp_channel,
        'payload_version' => '2.0',
        'timestamp' => Time.current.iso8601,
        'has_whatsapp_api_key' => extract_whatsapp_api_key(inbox).present?
      }
    rescue => e
      Rails.logger.error "[SOCIALWISE] Error building metadata: #{e.message}"
      {
        'socialwise_active' => true,
        'payload_version' => '2.0',
        'timestamp' => Time.current.iso8601
      }
    end

    # Validates the socialwise-chatwit data structure
    # @param data [Hash] The socialwise-chatwit data to validate
    # @return [Boolean] true if valid, false otherwise
    def validate_socialwise_data(data)
      return false unless data.is_a?(Hash)
      
      # Validate required top-level keys
      required_keys = %w[
        whatsapp_identifiers contact_data conversation_data message_data
        inbox_data account_data metadata whatsapp_api_key whatsapp_phone_number_id whatsapp_business_id
      ]
      
      unless required_keys.all? { |key| data.key?(key) }
        Rails.logger.warn "[SOCIALWISE] Missing required keys in socialwise-chatwit data"
        return false
      end
      
      # Validate individual sections
      return false unless validate_whatsapp_identifiers(data['whatsapp_identifiers'])
      return false unless validate_contact_data(data['contact_data'])
      return false unless validate_conversation_data(data['conversation_data'])
      return false unless validate_message_data(data['message_data'])
      return false unless validate_inbox_data(data['inbox_data'])
      return false unless validate_account_data(data['account_data'])
      return false unless validate_metadata(data['metadata'])
      
      # Validate whatsapp_api_key field (can be nil or string)
      unless data['whatsapp_api_key'].nil? || data['whatsapp_api_key'].is_a?(String)
        Rails.logger.warn "[SOCIALWISE] Invalid whatsapp_api_key type: #{data['whatsapp_api_key'].class}"
        return false
      end

      # Validate whatsapp_phone_number_id field (can be nil or string)
      unless data['whatsapp_phone_number_id'].nil? || data['whatsapp_phone_number_id'].is_a?(String)
        Rails.logger.warn "[SOCIALWISE] Invalid whatsapp_phone_number_id type: #{data['whatsapp_phone_number_id'].class}"
        return false
      end

      # Validate whatsapp_business_id field (can be nil or string)
      unless data['whatsapp_business_id'].nil? || data['whatsapp_business_id'].is_a?(String)
        Rails.logger.warn "[SOCIALWISE] Invalid whatsapp_business_id type: #{data['whatsapp_business_id'].class}"
        return false
      end
      
      Rails.logger.debug "[SOCIALWISE] SocialWise data validation passed"
      true
    rescue => e
      Rails.logger.error "[SOCIALWISE] Validation error: #{e.class}: #{e.message}"
      false
    end

    # Validates whatsapp_identifiers section
    def validate_whatsapp_identifiers(data)
      return false unless data.is_a?(Hash)
      
      required_keys = %w[wamid whatsapp_id contact_source]
      unless required_keys.all? { |key| data.key?(key) }
        Rails.logger.warn "[SOCIALWISE] Missing keys in whatsapp_identifiers"
        return false
      end
      
      # Values can be nil or strings
      data.values.each do |value|
        unless value.nil? || value.is_a?(String)
          Rails.logger.warn "[SOCIALWISE] Invalid type in whatsapp_identifiers: #{value.class}"
          return false
        end
      end
      
      true
    end

    # Validates contact_data section
    def validate_contact_data(data)
      return false unless data.is_a?(Hash)
      
      required_keys = %w[id name phone_number email identifier custom_attributes]
      unless required_keys.all? { |key| data.key?(key) }
        Rails.logger.warn "[SOCIALWISE] Missing keys in contact_data"
        return false
      end
      
      # Validate data types
      unless data['id'].nil? || data['id'].is_a?(Integer)
        Rails.logger.warn "[SOCIALWISE] Invalid contact id type: #{data['id'].class}"
        return false
      end
      
      unless data['custom_attributes'].is_a?(Hash)
        Rails.logger.warn "[SOCIALWISE] Invalid custom_attributes type: #{data['custom_attributes'].class}"
        return false
      end
      
      true
    end

    # Validates conversation_data section
    def validate_conversation_data(data)
      return false unless data.is_a?(Hash)
      
      required_keys = %w[id status assignee_id created_at updated_at]
      unless required_keys.all? { |key| data.key?(key) }
        Rails.logger.warn "[SOCIALWISE] Missing keys in conversation_data"
        return false
      end
      
      # Validate data types
      unless data['id'].nil? || data['id'].is_a?(Integer)
        Rails.logger.warn "[SOCIALWISE] Invalid conversation id type: #{data['id'].class}"
        return false
      end
      
      unless data['assignee_id'].nil? || data['assignee_id'].is_a?(Integer)
        Rails.logger.warn "[SOCIALWISE] Invalid assignee_id type: #{data['assignee_id'].class}"
        return false
      end
      
      # Validate timestamp formats
      %w[created_at updated_at].each do |timestamp_field|
        value = data[timestamp_field]
        if value && !value.match?(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})/)
          Rails.logger.warn "[SOCIALWISE] Invalid timestamp format for #{timestamp_field}: #{value}"
          return false
        end
      end
      
      true
    end

    # Validates message_data section
    def validate_message_data(data)
      return false unless data.is_a?(Hash)
      
      required_keys = %w[id content content_type message_type created_at interactive_data]
      unless required_keys.all? { |key| data.key?(key) }
        Rails.logger.warn "[SOCIALWISE] Missing keys in message_data"
        return false
      end
      
      # Validate data types
      unless data['id'].nil? || data['id'].is_a?(Integer)
        Rails.logger.warn "[SOCIALWISE] Invalid message id type: #{data['id'].class}"
        return false
      end
      
      # Validate interactive_data type
      unless data['interactive_data'].is_a?(Hash)
        Rails.logger.warn "[SOCIALWISE] Invalid interactive_data type: #{data['interactive_data'].class}"
        return false
      end
      
      # Validate timestamp format (accept both Z and +00:00 formats)
      created_at = data['created_at']
      if created_at && !created_at.match?(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})/)
        Rails.logger.warn "[SOCIALWISE] Invalid timestamp format for message created_at: #{created_at}"
        return false
      end
      
      true
    end

    # Validates inbox_data section
    def validate_inbox_data(data)
      return false unless data.is_a?(Hash)
      
      required_keys = %w[id name channel_type]
      unless required_keys.all? { |key| data.key?(key) }
        Rails.logger.warn "[SOCIALWISE] Missing keys in inbox_data"
        return false
      end
      
      # Validate data types
      unless data['id'].nil? || data['id'].is_a?(Integer)
        Rails.logger.warn "[SOCIALWISE] Invalid inbox id type: #{data['id'].class}"
        return false
      end
      
      true
    end

    # Validates account_data section
    def validate_account_data(data)
      return false unless data.is_a?(Hash)
      
      required_keys = %w[id name]
      unless required_keys.all? { |key| data.key?(key) }
        Rails.logger.warn "[SOCIALWISE] Missing keys in account_data"
        return false
      end
      
      # Validate data types
      unless data['id'].nil? || data['id'].is_a?(Integer)
        Rails.logger.warn "[SOCIALWISE] Invalid account id type: #{data['id'].class}"
        return false
      end
      
      true
    end

    # Validates metadata section
    def validate_metadata(data)
      return false unless data.is_a?(Hash)
      
      required_keys = %w[socialwise_active is_whatsapp_channel payload_version timestamp has_whatsapp_api_key]
      unless required_keys.all? { |key| data.key?(key) }
        Rails.logger.warn "[SOCIALWISE] Missing keys in metadata"
        return false
      end
      
      # Validate boolean fields
      unless [TrueClass, FalseClass].include?(data['socialwise_active'].class)
        Rails.logger.warn "[SOCIALWISE] Invalid socialwise_active type: #{data['socialwise_active'].class}"
        return false
      end
      
      unless [TrueClass, FalseClass].include?(data['is_whatsapp_channel'].class)
        Rails.logger.warn "[SOCIALWISE] Invalid is_whatsapp_channel type: #{data['is_whatsapp_channel'].class}"
        return false
      end
      
      unless [TrueClass, FalseClass].include?(data['has_whatsapp_api_key'].class)
        Rails.logger.warn "[SOCIALWISE] Invalid has_whatsapp_api_key type: #{data['has_whatsapp_api_key'].class}"
        return false
      end
      
      # Validate payload_version
      unless data['payload_version'] == '2.0'
        Rails.logger.warn "[SOCIALWISE] Invalid payload_version: #{data['payload_version']}"
        return false
      end
      
      # Validate timestamp format
      timestamp = data['timestamp']
      unless timestamp.is_a?(String) && timestamp.match?(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})/)
        Rails.logger.warn "[SOCIALWISE] Invalid timestamp format: #{timestamp}"
        return false
      end
      
      true
    end

    # Builds a comprehensive fallback data structure when full data collection fails
    # This ensures webhook delivery is never blocked by SocialWise failures
    # @param error [Exception] The error that caused the fallback
    # @param account [Account] The account (may be nil)
    # @return [Hash] Fallback socialwise-chatwit data structure
    def build_fallback_data_structure(error, account)
      Rails.logger.warn "[SOCIALWISE] Using fallback data structure due to error: #{error.class}: #{error.message}"
      
      # Build minimal but complete data structure
      fallback_data = {
        'whatsapp_identifiers' => {
          'wamid' => nil,
          'whatsapp_id' => nil,
          'contact_source' => nil
        },
        'contact_data' => {
          'id' => nil,
          'name' => nil,
          'phone_number' => nil,
          'email' => nil,
          'identifier' => nil,
          'custom_attributes' => {}
        },
        'conversation_data' => {
          'id' => nil,
          'status' => nil,
          'assignee_id' => nil,
          'created_at' => nil,
          'updated_at' => nil
        },
        'message_data' => {
          'id' => nil,
          'content' => nil,
          'content_type' => nil,
          'message_type' => nil,
          'created_at' => nil,
          'interactive_data' => {}
        },
        'inbox_data' => {
          'id' => nil,
          'name' => nil,
          'channel_type' => nil
        },
        'account_data' => {
          'id' => account&.id,
          'name' => account&.name
        },
        'metadata' => {
          'socialwise_active' => true,
          'is_whatsapp_channel' => false,
          'payload_version' => '2.0',
          'timestamp' => Time.current.iso8601,
          'error' => "Data collection failed: #{error.class}: #{error.message}",
          'fallback_used' => true,
          'has_whatsapp_api_key' => false
        },
        'whatsapp_api_key' => nil,
        'whatsapp_phone_number_id' => nil,
        'whatsapp_business_id' => nil
      }

      Rails.logger.info "[SOCIALWISE] Fallback data structure created successfully"
      fallback_data
    end
  end
end