module Enterprise::Linear::CallbacksController
  private

  def verify_catalog_state!
    installation_id = linear_oauth_state&.[]('installation_id')
    return if installation_id.blank?

    consume_catalog_nonce!(installation_id, linear_oauth_state['nonce'])
  end

  def consume_catalog_nonce!(installation_id, nonce)
    installation = account.captain_tool_catalog_installations.find(installation_id)
    valid = false
    installation.with_lock do
      installation.expire_if_needed!
      valid = valid_catalog_nonce?(installation, nonce)
      installation.update!(oauth_nonce_digest: nil) if valid
    end
    raise Captain::ToolCatalog::WorkflowError, 'invalid_oauth_state' unless valid

    @catalog_installation = installation
  end

  def valid_catalog_nonce?(installation, nonce)
    Captain::ToolCatalogInstallation::ACTIVE_STATUSES.include?(installation.status) &&
      installation.provider_key == 'linear' && nonce.present? &&
      ActiveSupport::SecurityUtils.secure_compare(
        installation.oauth_nonce_digest.to_s,
        Digest::SHA256.hexdigest(nonce)
      )
  end

  def after_linear_connection(hook)
    return if @catalog_installation.blank?

    @catalog_installation.update!(integration_hook: hook)
    Captain::ToolCatalog::WorkflowResumer.new.perform(@catalog_installation)
  end

  def linear_redirect_uri
    return super if @catalog_installation.blank?

    "#{super}?#{URI.encode_www_form(catalog_installation_id: @catalog_installation.id)}"
  end
end
