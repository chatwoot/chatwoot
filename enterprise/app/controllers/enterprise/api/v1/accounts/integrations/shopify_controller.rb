module Enterprise::Api::V1::Accounts::Integrations::ShopifyController
  def auth
    return super if params[:installation_id].blank?

    authorize(:hook, :create?)
    require_catalog_encryption!
    installation = catalog_installation!
    state = catalog_oauth_state(installation)
    raise Captain::ToolCatalog::WorkflowError, 'shopify_oauth_unavailable' if state.blank?

    render json: { redirect_url: catalog_authorization_url(catalog_shop_domain!, state, installation) }
  rescue Captain::ToolCatalog::WorkflowError => e
    render json: { error: { code: e.code } }, status: :unprocessable_entity
  end

  private

  def require_catalog_encryption!
    raise Captain::ToolCatalog::WorkflowError, 'encryption_required' unless Chatwoot.encryption_configured?
  end

  def catalog_installation!
    installation = Current.account.captain_tool_catalog_installations.active.find(params[:installation_id])
    return installation if installation.provider_key == 'shopify'

    raise Captain::ToolCatalog::WorkflowError, 'provider_mismatch'
  end

  def catalog_shop_domain!
    shop_domain = Shopify::ShopDomain.normalize(params[:shop_domain])
    return shop_domain if Shopify::ShopDomain.valid?(shop_domain)

    raise Captain::ToolCatalog::WorkflowError, 'invalid_shopify_domain'
  end

  def catalog_oauth_state(installation)
    nonce = SecureRandom.hex(32)
    installation.update!(oauth_nonce_digest: Digest::SHA256.hexdigest(nonce), status: 'awaiting_connection', error_code: nil)
    generate_shopify_token(
      Current.account.id,
      claims: { installation_id: installation.id, nonce: nonce }
    )
  end

  def catalog_authorization_url(shop_domain, state, installation)
    "https://#{shop_domain}/admin/oauth/authorize?#{URI.encode_www_form(
      client_id: client_id,
      scope: catalog_scopes(installation).join(','),
      redirect_uri: redirect_uri,
      state: state
    )}"
  end

  def catalog_scopes(installation)
    (Shopify::IntegrationHelper::REQUIRED_SCOPES + selected_scopes(installation) + existing_scopes).uniq.sort
  end

  def selected_scopes(installation)
    return installed_tool_scopes(installation) if installation.workflow_reconnect?

    selection = Captain::ToolCatalog::TemplateSelection.new.resolve(
      provider_key: installation.provider_key,
      templates: installation.selected_templates
    )
    selection.required_scopes
  end

  def installed_tool_scopes(installation)
    template_keys = installation.selected_templates.pluck('template_key')
    Current.account.captain_custom_tools.catalog.where(provider_key: 'shopify', template_key: template_keys).flat_map do |tool|
      tool.definition.fetch('operations').flat_map { |operation| operation.fetch('scopes') }
    end
  end

  def existing_scopes
    hook = Current.account.hooks.account_hooks.find_by(app_id: 'shopify')
    value = hook&.settings.to_h&.with_indifferent_access&.[](:scope)
    value.to_s.split(/[\s,]+/).compact_blank
  end
end
