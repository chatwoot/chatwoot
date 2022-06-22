class AgentBot::ValidateBotService
  pattr_initialize [:agent_bot]
  def perform
    return true unless agent_bot.type == :csml

    validate_csml_bot
  end

  private

  def csml_client
    csml_host = GlobalConfigService.load('CSML_BOT_HOST', '')
    csml_bot_api_key = GlobalConfigService.load('CSML_BOT_API_KEY', '')

    return if csml_host.blank? || csml_bot_api_key.blank?

    @csml_client ||= CsmlEngine.new(csml_host, csml_bot_api_key)
  end

  def csml_bot_payload
    {
      id: permitted_payload[:name],
      name: permitted_payload[:name],
      default_flow: 'Default',
      flows: [
        {
          id: SecureRandom.hex,
          name: 'Default',
          content: permitted_params[:bot_config],
          commands: ['trigger keyword']
        }
      ]
    }
  end

  def validate_csml_bot
    return false if csml_client.blank?

    csml_client = CsmlEngine.new(csml_host, csml_bot_api_key)
    response = csml_client.validate(
      csml_bot_payload
    )

    response.blank? || response['valid'].blank?
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: agent_bot).capture_exception
    false
  end
end
