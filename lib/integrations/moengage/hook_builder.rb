class Integrations::Moengage::HookBuilder
  attr_reader :account, :params

  def initialize(account:, params:)
    @account = account
    @params = params
  end

  def perform
    validate_settings!
    create_hook
  end

  private

  def validate_settings!
    settings = params[:settings]
    raise ArgumentError, 'Workspace ID is required' if settings[:workspace_id].blank?
    raise ArgumentError, 'Default inbox is required' if settings[:default_inbox_id].blank?

    inbox = account.inboxes.find_by(id: settings[:default_inbox_id])
    raise ArgumentError, 'Invalid inbox' unless inbox

    return unless settings[:enable_ai_response] && settings[:ai_agent_id].present?

    agent = account.agent_bots.find_by(id: settings[:ai_agent_id])
    raise ArgumentError, 'Invalid AI agent' unless agent
  end

  def create_hook
    settings_with_token = params[:settings].to_h.merge(
      'webhook_token' => generate_webhook_token
    )

    account.hooks.create!(
      app_id: 'moengage',
      hook_type: 'account',
      settings: settings_with_token,
      status: 'enabled'
    )
  end

  def generate_webhook_token
    SecureRandom.urlsafe_base64(32)
  end
end
