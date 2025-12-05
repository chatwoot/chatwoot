require 'net/http'

class Evolution::ManagerService
  # HTTParty timeout configurations
  TIMEOUT_OPTIONS = {
    timeout: 30, # 30 seconds total timeout
    open_timeout: 10, # 10 seconds connection timeout
    read_timeout: 20 # 20 seconds read timeout
  }.freeze

  def api_headers(api_key)
    { 'apikey' => api_key, 'Content-Type' => 'application/json' }
  end

  def create(account_id, name, webhook_url, api_key, access_token)
    validate_inputs!(webhook_url, api_key, name)

    frontend_url = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
    internal_api_url = ENV.fetch('INTERNAL_API_URL', nil) || frontend_url

    Rails.logger.info("Creating Evolution API instance: #{name} for account: #{account_id}")

    response = with_error_handling(name) do
      HTTParty.post(
        "#{webhook_url}/instance/create",
        headers: api_headers(api_key),
        body: build_instance_payload(account_id, name, access_token, internal_api_url, frontend_url).to_json,
        **TIMEOUT_OPTIONS
      )
    end

    process_response(response, name)
  end

  def destroy(webhook_url, api_key, instance_name)
    return if instance_name.blank?

    validate_destroy_inputs!(webhook_url, api_key, instance_name)

    Rails.logger.info("Starting Evolution API instance destruction: #{instance_name}")

    # Step 1: Logout instance first (disconnect from WhatsApp Web)
    logout_instance(webhook_url, api_key, instance_name)

    # Step 2: Delete instance
    Rails.logger.info("Deleting Evolution API instance: #{instance_name}")

    response = with_graceful_error_handling(instance_name) do
      HTTParty.delete(
        "#{webhook_url}/instance/delete/#{instance_name}",
        headers: api_headers(api_key),
        **TIMEOUT_OPTIONS
      )
    end

    process_destroy_response(response, instance_name) if response

    # Step 3: Verify instance was completely destroyed
    verify_instance_destroyed(webhook_url, api_key, instance_name)
  end

  def logout_instance(webhook_url, api_key, instance_name)
    Rails.logger.info("Logging out Evolution API instance: #{instance_name}")

    response = with_graceful_error_handling(instance_name) do
      HTTParty.delete(
        "#{webhook_url}/instance/logout/#{instance_name}",
        headers: api_headers(api_key),
        **TIMEOUT_OPTIONS
      )
    end

    process_logout_response(response, instance_name) if response
  end

  def instance_status(webhook_url, api_key, instance_name)
    response = with_graceful_error_handling(instance_name) do
      HTTParty.get(
        "#{webhook_url}/instance/fetchInstances",
        headers: api_headers(api_key),
        **TIMEOUT_OPTIONS
      )
    end

    return nil unless response

    instances = response.parsed_response
    return nil unless instances.is_a?(Array)

    instances.find { |i| i.dig('instance', 'instanceName') == instance_name }
  end

  def verify_instance_destroyed(webhook_url, api_key, instance_name)
    status = instance_status(webhook_url, api_key, instance_name)

    if status.nil?
      Rails.logger.info("Evolution instance successfully destroyed: #{instance_name}")
      true
    else
      Rails.logger.error("Evolution instance still exists after deletion: #{instance_name}")
      false
    end
  rescue StandardError => e
    Rails.logger.warn("Could not verify Evolution instance destruction for #{instance_name}: #{e.message}")
    # Don't fail the deletion if verification fails
    true
  end

  private

  def validate_inputs!(webhook_url, api_key, name)
    raise CustomExceptions::Evolution::InvalidConfiguration.new(details: 'API URL is required') if webhook_url.blank?
    raise CustomExceptions::Evolution::InvalidConfiguration.new(details: 'API key is required') if api_key.blank?
    raise CustomExceptions::Evolution::InvalidConfiguration.new(details: 'Instance name is required') if name.blank?

    # Validate URL format
    begin
      uri = URI.parse(webhook_url)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        raise CustomExceptions::Evolution::InvalidConfiguration.new(details: 'Invalid API URL format')
      end
    rescue URI::InvalidURIError
      raise CustomExceptions::Evolution::InvalidConfiguration.new(details: 'Invalid API URL format')
    end
  end

  def build_instance_payload(account_id, name, access_token, internal_api_url, frontend_url)
    {
      instanceName: name,
      qrcode: true,
      integration: 'WHATSAPP-BAILEYS',
      groupsIgnore: true,
      chatwootAutoCreate: true, # needs to be true to auto-create bot conversation
      chatwootAccountId: account_id.to_s,
      chatwootToken: access_token,
      chatwootUrl: internal_api_url,
      chatwootSignMsg: true,
      chatwootReopenConversation: false,
      chatwootConversationPending: false,
      chatwootImportContacts: false,
      chatwootNameInbox: name,
      chatwootMergeBrazilContacts: true,
      chatwootImportMessages: false,
      chatwootDaysLimitImportMessages: 0,
      chatwootOrganization: 'WhatsApp Bot',
      chatwootLogo: "#{frontend_url}/assets/images/dashboard/channels/whatsapp.png"
    }
  end

  def with_error_handling(instance_name)
    yield
  rescue Net::ReadTimeout, Net::OpenTimeout => e
    Rails.logger.error("Evolution API timeout for instance #{instance_name}: #{e.message}")
    raise CustomExceptions::Evolution::NetworkTimeout.new(instance_name: instance_name)
  rescue Timeout::Error => e
    Rails.logger.error("Evolution API timeout for instance #{instance_name}: #{e.message}")
    raise CustomExceptions::Evolution::NetworkTimeout.new(instance_name: instance_name)
  rescue Errno::ECONNREFUSED => e
    Rails.logger.error("Evolution API connection refused for instance #{instance_name}: #{e.message}")
    raise CustomExceptions::Evolution::ConnectionRefused.new(instance_name: instance_name)
  rescue SocketError => e
    Rails.logger.error("Evolution API DNS/network error for instance #{instance_name}: #{e.message}")
    raise CustomExceptions::Evolution::ServiceUnavailable.new(instance_name: instance_name)
  rescue HTTParty::Error => e
    Rails.logger.error("Evolution API HTTP error for instance #{instance_name}: #{e.message}")
    raise CustomExceptions::Evolution::ServiceUnavailable.new(instance_name: instance_name)
  rescue StandardError => e
    Rails.logger.error("Unexpected Evolution API error for instance #{instance_name}: #{e.message}")
    raise CustomExceptions::Evolution::InvalidConfiguration.new(details: e.message, instance_name: instance_name)
  end

  def process_response(response, instance_name)
    case response.code
    when 200, 201
      Rails.logger.info("Evolution API instance created successfully: #{instance_name}")
      handle_success_response(response)
    when 400
      Rails.logger.error("Evolution API bad request for instance #{instance_name}: #{response.body}")
      raise CustomExceptions::Evolution::InvalidConfiguration.new(
        details: extract_error_message(response),
        instance_name: instance_name
      )
    when 401, 403
      Rails.logger.error("Evolution API authentication failed for instance #{instance_name}: #{response.body}")
      raise CustomExceptions::Evolution::AuthenticationError.new(instance_name: instance_name)
    when 409
      Rails.logger.error("Evolution API instance conflict for instance #{instance_name}: #{response.body}")
      raise CustomExceptions::Evolution::InstanceConflict.new(instance_name: instance_name)
    when 422
      Rails.logger.error("Evolution API instance creation failed for instance #{instance_name}: #{response.body}")
      raise CustomExceptions::Evolution::InstanceCreationFailed.new(
        reason: extract_error_message(response),
        instance_name: instance_name
      )
    when 503
      Rails.logger.error("Evolution API service unavailable for instance #{instance_name}: #{response.body}")
      raise CustomExceptions::Evolution::ServiceUnavailable.new(instance_name: instance_name)
    else
      Rails.logger.error("Evolution API unexpected response for instance #{instance_name}: #{response.code} - #{response.body}")
      raise CustomExceptions::Evolution::ServiceUnavailable.new(instance_name: instance_name)
    end
  end

  def handle_success_response(response)
    response_body = begin
      JSON.parse(response.body)
    rescue StandardError
      {}
    end
    Rails.logger.info("Evolution instance creation response: #{response_body}")
    response_body
  end

  def extract_error_message(response)
    parsed_body = begin
      JSON.parse(response.body)
    rescue StandardError
      {}
    end
    parsed_body['message'] || parsed_body['error'] || response.body.presence || 'Unknown error'
  end

  def validate_destroy_inputs!(webhook_url, api_key, instance_name)
    raise CustomExceptions::Evolution::InvalidConfiguration.new(details: 'API URL is required') if webhook_url.blank?
    raise CustomExceptions::Evolution::InvalidConfiguration.new(details: 'API key is required') if api_key.blank?
    raise CustomExceptions::Evolution::InvalidConfiguration.new(details: 'Instance name is required') if instance_name.blank?

    # Validate URL format
    begin
      uri = URI.parse(webhook_url)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        raise CustomExceptions::Evolution::InvalidConfiguration.new(details: 'Invalid API URL format')
      end
    rescue URI::InvalidURIError
      raise CustomExceptions::Evolution::InvalidConfiguration.new(details: 'Invalid API URL format')
    end
  end

  def with_graceful_error_handling(instance_name)
    yield
  rescue Net::ReadTimeout, Net::OpenTimeout => e
    Rails.logger.warn("Evolution API timeout during instance #{instance_name} deletion: #{e.message}")
    # Don't raise exception - allow deletion to continue
    nil
  rescue Timeout::Error => e
    Rails.logger.warn("Evolution API timeout during instance #{instance_name} deletion: #{e.message}")
    # Don't raise exception - allow deletion to continue
    nil
  rescue Errno::ECONNREFUSED => e
    Rails.logger.warn("Evolution API connection refused during instance #{instance_name} deletion: #{e.message}")
    # Don't raise exception - allow deletion to continue
    nil
  rescue SocketError => e
    Rails.logger.warn("Evolution API DNS/network error during instance #{instance_name} deletion: #{e.message}")
    # Don't raise exception - allow deletion to continue
    nil
  rescue HTTParty::Error => e
    Rails.logger.warn("Evolution API HTTP error during instance #{instance_name} deletion: #{e.message}")
    # Don't raise exception - allow deletion to continue
    nil
  rescue StandardError => e
    Rails.logger.warn("Unexpected Evolution API error during instance #{instance_name} deletion: #{e.message}")
    # Don't raise exception - allow deletion to continue
    nil
  end

  def process_logout_response(response, instance_name)
    case response.code
    when 200, 201, 204
      Rails.logger.info("Evolution API instance logged out successfully: #{instance_name}")
      true
    when 404
      Rails.logger.info("Evolution API instance not found during logout (may already be logged out): #{instance_name}")
      true
    when 401, 403
      Rails.logger.warn("Evolution API authentication failed during logout for instance #{instance_name}: #{response.body}")
      # Don't block deletion for auth errors
      false
    else
      Rails.logger.warn("Evolution API unexpected response during logout for instance #{instance_name}: #{response.code} - #{response.body}")
      # Don't block deletion for other errors
      false
    end
  end

  def process_destroy_response(response, instance_name)
    case response.code
    when 200, 201, 204
      Rails.logger.info("Evolution API instance destroyed successfully: #{instance_name}")
      true
    when 404
      Rails.logger.info("Evolution API instance not found (already deleted): #{instance_name}")
      true
    when 401, 403
      Rails.logger.warn("Evolution API authentication failed during deletion for instance #{instance_name}: #{response.body}")
      # Don't block deletion for auth errors
      false
    else
      Rails.logger.warn("Evolution API unexpected response during deletion for instance #{instance_name}: #{response.code} - #{response.body}")
      # Don't block deletion for other errors
      false
    end
  end
end
