module Enterprise::Shopify::CallbacksController
  private

  def verify_account!
    super
    state = verify_shopify_state(params[:state])
    installation_id = state&.[]('installation_id')
    return if installation_id.blank?

    @catalog_oauth_state = state
  end

  def verify_shop!
    super
    return if @catalog_oauth_state.blank?

    raise Captain::ToolCatalog::WorkflowError, 'encryption_required' unless Chatwoot.encryption_configured?

    consume_catalog_nonce!(@catalog_oauth_state.fetch('installation_id'), @catalog_oauth_state['nonce'])
  end

  def consume_catalog_nonce!(installation_id, nonce)
    installation = account.captain_tool_catalog_installations.find(installation_id)
    installation.with_lock do
      installation.expire_if_needed!
      valid = Captain::ToolCatalogInstallation::ACTIVE_STATUSES.include?(installation.status) &&
              installation.provider_key == 'shopify' && nonce.present? &&
              ActiveSupport::SecurityUtils.secure_compare(
                installation.oauth_nonce_digest.to_s,
                Digest::SHA256.hexdigest(nonce)
              )
      raise Captain::ToolCatalog::WorkflowError, 'invalid_oauth_state' unless valid

      installation.update!(oauth_nonce_digest: nil)
    end
    @catalog_installation = installation
  end

  def after_shopify_connection(hook)
    return if @catalog_installation.blank?

    @catalog_installation.update!(integration_hook: hook)
    Captain::ToolCatalog::WorkflowResumer.new.perform(@catalog_installation)
  end

  def shopify_integration_url
    return super if @catalog_installation.blank?

    "#{super}?#{URI.encode_www_form(catalog_installation_id: @catalog_installation.id)}"
  end
end
