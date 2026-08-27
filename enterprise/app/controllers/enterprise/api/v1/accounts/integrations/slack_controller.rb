module Enterprise::Api::V1::Accounts::Integrations::SlackController
  def auth
    authorize(:hook, :create?)
    installation = catalog_installation!
    raise Captain::ToolCatalog::WorkflowError, 'slack_oauth_unavailable' if slack_client_id.blank? || slack_client_secret.blank?

    nonce = SecureRandom.hex(32)
    state = slack_oauth_state.generate(account_id: Current.account.id, installation_id: installation.id, nonce: nonce)
    installation.update!(oauth_nonce_digest: Digest::SHA256.hexdigest(nonce), status: 'awaiting_connection', error_code: nil)
    render json: { redirect_url: slack_authorization_url(state, catalog_scopes(installation)) }
  rescue Captain::ToolCatalog::WorkflowError => e
    render json: { error: { code: e.code } }, status: :unprocessable_entity
  end

  def create
    return super if params[:state].blank?

    installation = consume_catalog_state!
    @hook = Integrations::Slack::HookBuilder.new(account: Current.account, code: params[:code], catalog: true).perform
    installation.update!(integration_hook: @hook)
    Captain::ToolCatalog::WorkflowResumer.new.perform(installation)
  rescue Captain::ToolCatalog::WorkflowError => e
    render json: { error: { code: e.code } }, status: :unprocessable_entity
  rescue Slack::Web::Api::Errors::SlackError
    render json: { error: { code: 'slack_oauth_failed' } }, status: :unprocessable_entity
  end

  private

  def catalog_installation!
    raise Captain::ToolCatalog::WorkflowError, 'catalog_unavailable' unless Current.account.feature_enabled?('captain_tool_catalog')

    installation = Current.account.captain_tool_catalog_installations.active.find(params[:installation_id])
    installation.expire_if_needed!
    active_statuses = Captain::ToolCatalogInstallation::ACTIVE_STATUSES
    raise Captain::ToolCatalog::WorkflowError, 'installation_expired' unless active_statuses.include?(installation.status)
    return installation if installation.provider_key == 'slack'

    raise Captain::ToolCatalog::WorkflowError, 'provider_mismatch'
  end

  def consume_catalog_state!
    state = slack_oauth_state.verify(params[:state])
    raise Captain::ToolCatalog::WorkflowError, 'invalid_oauth_state' unless state&.fetch('sub', nil).to_i == Current.account.id

    installation = Current.account.captain_tool_catalog_installations.find_by(id: state['installation_id'])
    valid = false
    installation&.with_lock do
      installation.expire_if_needed!
      valid = valid_catalog_state?(installation, state['nonce'])
      installation.update!(oauth_nonce_digest: nil) if valid
    end
    raise Captain::ToolCatalog::WorkflowError, 'invalid_oauth_state' unless valid

    installation
  end

  def valid_catalog_state?(installation, nonce)
    Captain::ToolCatalogInstallation::ACTIVE_STATUSES.include?(installation.status) &&
      installation.provider_key == 'slack' && nonce.present? &&
      ActiveSupport::SecurityUtils.secure_compare(
        installation.oauth_nonce_digest.to_s,
        Digest::SHA256.hexdigest(nonce)
      )
  end

  def slack_authorization_url(state, scopes)
    "https://slack.com/oauth/v2/authorize?#{URI.encode_www_form(
      client_id: slack_client_id,
      scope: scopes.join(','),
      redirect_uri: Integrations::App.slack_integration_url,
      state: state
    )}"
  end

  def catalog_scopes(installation)
    (selected_scopes(installation) + existing_scopes).uniq.sort
  end

  def selected_scopes(installation)
    return installed_tool_scopes(installation) if installation.workflow_reconnect?

    Captain::ToolCatalog::TemplateSelection.new.resolve(
      provider_key: installation.provider_key,
      templates: installation.selected_templates,
      validate_configuration: !installation.workflow_connect?
    ).required_scopes
  end

  def installed_tool_scopes(installation)
    template_keys = installation.selected_templates.pluck('template_key')
    Current.account.captain_custom_tools.catalog.where(provider_key: 'slack', template_key: template_keys).flat_map do |tool|
      tool.definition.fetch('operations').flat_map { |operation| operation.fetch('scopes') }
    end
  end

  def existing_scopes
    hook = Current.account.hooks.account_hooks.find_by(app_id: 'slack')
    value = hook&.settings.to_h&.with_indifferent_access&.[](:scope)
    value.to_s.split(/[\s,]+/).compact_blank
  end

  def slack_oauth_state
    raise Captain::ToolCatalog::WorkflowError, 'slack_oauth_unavailable' if slack_client_secret.blank?

    @slack_oauth_state ||= Captain::ToolCatalog::SlackOauthState.new(secret: slack_client_secret)
  end

  def slack_client_id
    @slack_client_id ||= GlobalConfigService.load('SLACK_CLIENT_ID', nil)
  end

  def slack_client_secret
    @slack_client_secret ||= GlobalConfigService.load('SLACK_CLIENT_SECRET', nil)
  end
end
