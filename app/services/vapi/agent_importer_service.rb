class Vapi::AgentImporterService
  pattr_initialize [:account!, :vapi_agent_id!, :inbox_id!]

  def perform
    validate_inputs!
    fetch_and_create_agent
  end

  private

  def validate_inputs!
    raise 'VAPI_API_KEY not configured' if ENV.fetch('VAPI_API_KEY', nil).blank?
    raise 'Vapi Agent ID is required' if vapi_agent_id.blank?
    raise 'Inbox ID is required' if inbox_id.blank?

    @inbox = account.inboxes.find_by(id: inbox_id)
    raise 'Inbox not found or does not belong to account' if @inbox.blank?
  end

  def fetch_and_create_agent
    # Fetch agent data from Vapi
    api_client = Vapi::ApiClient.new
    vapi_data = api_client.get_agent(vapi_agent_id)

    # Debug logging to see what Vapi returns
    Rails.logger.info '=' * 80
    Rails.logger.info "Vapi API Response for agent #{vapi_agent_id}:"
    Rails.logger.info vapi_data.inspect
    Rails.logger.info '=' * 80
    Rails.logger.info 'Extracted fields:'
    Rails.logger.info "  name: #{vapi_data['name'].inspect}"
    Rails.logger.info "  phoneNumber: #{vapi_data['phoneNumber'].inspect}"
    Rails.logger.info "  firstMessage: #{vapi_data['firstMessage'].inspect}"
    Rails.logger.info "  model: #{vapi_data['model'].inspect}"
    Rails.logger.info "  voice: #{vapi_data['voice'].inspect}"
    Rails.logger.info "  transcriber: #{vapi_data['transcriber'].inspect}"
    Rails.logger.info '=' * 80

    # Check if agent already exists in this account
    existing_agent = account.vapi_agents.find_by(vapi_agent_id: vapi_agent_id)
    return { error: 'Agent already exists in this account', agent: existing_agent } if existing_agent.present?

    settings = build_settings(vapi_data)
    Rails.logger.info "Built settings: #{settings.inspect}"

    # Create agent in database
    agent = account.vapi_agents.create!(
      name: vapi_data['name'] || 'Imported Agent',
      vapi_agent_id: vapi_agent_id,
      inbox_id: inbox_id,
      phone_number: vapi_data['phoneNumber'],
      active: true,
      settings: settings
    )

    Rails.logger.info "Created agent: #{agent.inspect}"

    # Configure webhook on VAPI agent if webhook URL is available
    configure_webhook_on_vapi(api_client) if webhook_url.present?

    { success: true, agent: agent }
  rescue StandardError => e
    Rails.logger.error "Failed to import Vapi agent: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    { error: e.message }
  end

  def build_settings(vapi_data)
    # Try multiple possible field names for flexibility
    first_message = vapi_data['firstMessage'] || vapi_data['first_message']

    # Extract system prompt from model messages
    system_prompt = extract_system_prompt(vapi_data)

    # Extract voice configuration
    voice_provider = vapi_data.dig('voice', 'provider')
    voice_id = vapi_data.dig('voice', 'voiceId') || vapi_data.dig('voice', 'voice_id')

    # Extract model configuration
    model_provider = vapi_data.dig('model', 'provider')
    model_name = vapi_data.dig('model', 'model') || vapi_data.dig('model', 'name')

    # Extract transcriber configuration
    transcriber_provider = vapi_data.dig('transcriber', 'provider')
    transcriber_language = vapi_data.dig('transcriber', 'language')

    Rails.logger.info 'Extracted settings values:'
    Rails.logger.info "  first_message: #{first_message.inspect}"
    Rails.logger.info "  system_prompt: #{system_prompt.inspect}"
    Rails.logger.info "  voice_provider: #{voice_provider.inspect}, voice_id: #{voice_id.inspect}"
    Rails.logger.info "  model_provider: #{model_provider.inspect}, model_name: #{model_name.inspect}"
    Rails.logger.info "  transcriber_provider: #{transcriber_provider.inspect}, language: #{transcriber_language.inspect}"

    {
      first_message: first_message,
      system_prompt: system_prompt,
      voice_provider: voice_provider,
      voice_id: voice_id,
      model_provider: model_provider,
      model_name: model_name,
      transcriber_provider: transcriber_provider,
      transcriber_language: transcriber_language
    }.compact
  end

  def extract_system_prompt(vapi_data)
    # Try to find system prompt in various locations
    if vapi_data.dig('model', 'messages').is_a?(Array)
      system_msg = vapi_data.dig('model', 'messages').find { |m| m['role'] == 'system' }
      return system_msg['content'] if system_msg

      # Fallback to first message
      return vapi_data.dig('model', 'messages', 0, 'content')
    end
    vapi_data.dig('model', 'systemPrompt') || vapi_data.dig('model', 'system_prompt')
  end

  def configure_webhook_on_vapi(api_client)
    update_params = {
      server: {
        url: webhook_url,
        timeoutSeconds: 20
      },
      serverMessages: ['end-of-call-report']
    }

    Rails.logger.info "Configuring webhook on VAPI agent: #{webhook_url}"
    api_client.update_agent(vapi_agent_id, update_params)
    Rails.logger.info 'Webhook configured successfully'
  rescue StandardError => e
    Rails.logger.error "Failed to configure webhook: #{e.message}"
    # Don't fail the import if webhook configuration fails
  end

  def webhook_url
    # Get from ENV or use provided URL
    base_url = ENV.fetch('VAPI_WEBHOOK_URL', nil) || ENV.fetch('FRONTEND_URL', nil)
    return nil if base_url.blank?

    # Ensure it's a proper URL
    base_url = "https://#{base_url}" unless base_url.start_with?('http://', 'https://')
    # Only return if it's HTTPS
    base_url.start_with?('https://') ? "#{base_url}/webhooks/vapi" : nil
  end
end
