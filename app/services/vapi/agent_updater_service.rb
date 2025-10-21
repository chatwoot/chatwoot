class Vapi::AgentUpdaterService
  pattr_initialize [:vapi_agent!, :params!]

  def perform
    update_vapi_agent if should_update_vapi?
    update_local_agent
  end

  private

  def should_update_vapi?
    ENV.fetch('VAPI_API_KEY', nil).present? && vapi_fields?
  end

  def vapi_fields?
    [:first_message, :system_prompt, :voice_provider, :voice_id, :model_provider, :model_name, :transcriber_provider,
     :transcriber_language].any? do |key|
      params.key?(key)
    end
  end

  def update_vapi_agent
    vapi_params = build_vapi_params
    api_client = Vapi::ApiClient.new
    api_client.update_agent(vapi_agent.vapi_agent_id, vapi_params)
  end

  def update_local_agent
    update_attrs = {
      name: params[:name],
      inbox_id: params[:inbox_id],
      phone_number: params[:phone_number],
      active: params[:active]
    }.compact

    update_attrs[:settings] = build_settings if vapi_fields?

    vapi_agent.update!(update_attrs)
    vapi_agent
  end

  def build_vapi_params
    vapi_params = {
      name: params[:name],
      firstMessage: params[:first_message],
      transcriber: build_transcriber_params,
      model: {
        provider: params[:model_provider] || 'openai',
        model: params[:model_name] || 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: params[:system_prompt]
          }
        ]
      },
      voice: {
        provider: params[:voice_provider] || '11labs',
        voiceId: params[:voice_id]
      }
    }

    # Add server configuration for webhooks
    # Only add if webhook_url is present and valid (https)
    if webhook_url.present? && webhook_url.start_with?('https://')
      vapi_params[:server] = {
        url: webhook_url,
        timeoutSeconds: 20
      }
      vapi_params[:serverMessages] = ['end-of-call-report']
      Rails.logger.info "Configuring VAPI webhook: #{webhook_url}"
    else
      Rails.logger.warn 'Skipping VAPI webhook configuration - no valid HTTPS URL configured (set VAPI_WEBHOOK_URL or FRONTEND_URL)'
    end

    vapi_params
  end

  def build_transcriber_params
    transcriber = {
      provider: params[:transcriber_provider] || 'deepgram'
    }
    transcriber[:language] = params[:transcriber_language] if params[:transcriber_language].present?
    transcriber
  end

  def build_settings
    {
      first_message: params[:first_message],
      system_prompt: params[:system_prompt],
      voice_provider: params[:voice_provider],
      voice_id: params[:voice_id],
      model_provider: params[:model_provider],
      model_name: params[:model_name],
      transcriber_provider: params[:transcriber_provider],
      transcriber_language: params[:transcriber_language]
    }.compact
  end

  def webhook_url
    # Get from ENV or use provided URL
    base_url = ENV.fetch('VAPI_WEBHOOK_URL', nil) || ENV.fetch('FRONTEND_URL', nil)
    return nil if base_url.blank?

    # Ensure it's a proper URL
    base_url = "https://#{base_url}" unless base_url.start_with?('http://', 'https://')
    "#{base_url}/webhooks/vapi"
  end
end
