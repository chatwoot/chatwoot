class Captain::ToolCatalog::ConnectionRevoker
  def initialize(account:, registry: Captain::ToolCatalog::ProviderPackRegistry.default)
    @account = account
    @registry = registry
  end

  def perform(provider_key:)
    registry.find(provider_key)
    hook = account.hooks.account_hooks.find_by(app_id: provider_key)
    return if hook.blank?

    revoke_provider_token(hook)
    Integrations::Hook.transaction do
      cancel_active_installations(provider_key)
      hook.destroy!
    end
  end

  private

  attr_reader :account, :registry

  def cancel_active_installations(provider_key)
    account.captain_tool_catalog_installations.active.where(provider_key: provider_key).find_each do |installation|
      installation.update!(status: 'expired', oauth_nonce_digest: nil, error_code: nil)
    end
  end

  def revoke_provider_token(hook)
    return unless hook.app_id == 'linear' && hook.access_token.present?

    refresh_token = hook.refresh_token.presence || hook.settings.to_h.with_indifferent_access[:refresh_token]
    Linear.new(hook.access_token, refresh_token: refresh_token).revoke_token
  rescue StandardError => e
    Rails.logger.error "Failed to revoke #{hook.app_id} catalog connection: #{e.message}"
  end
end
