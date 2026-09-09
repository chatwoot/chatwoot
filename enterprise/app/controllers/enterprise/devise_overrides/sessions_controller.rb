module Enterprise::DeviseOverrides::SessionsController
  include SamlAuthenticationHelper

  def create
    if saml_user_attempting_password_auth?(params[:email], sso_auth_token: params[:sso_auth_token])
      render json: {
        success: false,
        message: I18n.t('messages.login_saml_user'),
        errors: [I18n.t('messages.login_saml_user')]
      }, status: :unauthorized
      return
    end

    super
  end

  def render_create_success
    create_audit_event('sign_in')
    super
  end

  def destroy
    create_audit_event('sign_out')
    super
  end

  def create_audit_event(action)
    return unless @resource

    account_ids = @resource.accounts.ids
    return if account_ids.empty?

    Enterprise::AuditLog.insert_all!(audit_event_rows(action, account_ids)) # rubocop:disable Rails/SkipsModelValidations
  end

  def audit_event_rows(action, account_ids)
    base_version = Enterprise::AuditLog.unscoped.auditable_finder(@resource.id, 'User').maximum(:version) || 0
    request_uuid = ::Audited.store[:current_request_uuid] || SecureRandom.uuid
    created_at = Time.zone.now

    account_ids.each_with_index.map do |account_id, index|
      {
        auditable_id: @resource.id,
        auditable_type: 'User',
        user_id: @resource.id,
        user_type: 'User',
        username: @resource.email,
        action: action,
        associated_id: account_id,
        associated_type: 'Account',
        version: base_version + index + 1,
        request_uuid: request_uuid,
        remote_address: ::Audited.store[:current_remote_address],
        created_at: created_at
      }
    end
  end
end
