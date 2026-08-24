module Enterprise::Api::V1::Accounts::Integrations::LinearController
  def auth
    authorize(:hook, :create?)
    require_catalog_encryption!
    installation = catalog_installation!
    raise Captain::ToolCatalog::WorkflowError, 'linear_oauth_unavailable' if client_id.blank? || client_secret.blank?

    state = catalog_oauth_state(installation)
    raise Captain::ToolCatalog::WorkflowError, 'linear_oauth_unavailable' if state.blank?

    render json: { redirect_url: catalog_authorization_url(state) }
  rescue Captain::ToolCatalog::WorkflowError => e
    render json: { error: { code: e.code } }, status: :unprocessable_entity
  end

  private

  def require_catalog_encryption!
    raise Captain::ToolCatalog::WorkflowError, 'encryption_required' unless Chatwoot.encryption_configured?
  end

  def catalog_installation!
    raise Captain::ToolCatalog::WorkflowError, 'catalog_unavailable' unless Current.account.feature_enabled?('captain_tool_catalog')

    installation = Current.account.captain_tool_catalog_installations.active.find(params[:installation_id])
    installation.expire_if_needed!
    active_statuses = Captain::ToolCatalogInstallation::ACTIVE_STATUSES
    raise Captain::ToolCatalog::WorkflowError, 'installation_expired' unless active_statuses.include?(installation.status)
    return installation if installation.provider_key == 'linear'

    raise Captain::ToolCatalog::WorkflowError, 'provider_mismatch'
  end

  def catalog_oauth_state(installation)
    nonce = SecureRandom.hex(32)
    state = generate_linear_token(
      Current.account.id,
      claims: { installation_id: installation.id, nonce: nonce }
    )
    return if state.blank?

    installation.update!(oauth_nonce_digest: Digest::SHA256.hexdigest(nonce), status: 'awaiting_connection', error_code: nil)
    state
  end

  def catalog_authorization_url(state)
    "https://linear.app/oauth/authorize?#{URI.encode_www_form(
      response_type: 'code',
      client_id: client_id,
      redirect_uri: linear_callback_url,
      state: state,
      scope: 'read,write',
      prompt: 'consent',
      actor: 'app'
    )}"
  end

  def linear_callback_url
    "#{ENV.fetch('FRONTEND_URL', nil)}/linear/callback"
  end
end
