module Enterprise::DeviseOverrides::SessionsController
  include SamlAuthenticationHelper

  def create
    if saml_user_attempting_password_auth?(params[:email], sso_auth_token: params[:sso_auth_token])
      render json: {
        success: false,
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

    associated_type = 'Account'
    @resource.accounts.each do |account|
      @resource.audits.create(
        action: action,
        user_id: @resource.id,
        associated_id: account.id,
        associated_type: associated_type
      )
    end
  end

  private

  def check_saml_user
    # Skip if using SSO token (SAML users can use SSO tokens)
    return if params[:sso_auth_token].present?
    return if params[:email].blank?

    user = User.from_email(params[:email])
    return unless user&.provider == 'saml'

    check_saml_enabled_accounts(user)
  end

  def check_saml_enabled_accounts(user)
    # Allow regular login if SAML is not configured/enabled for the account
    user.accounts.each do |account|
      saml_settings = account.account_saml_settings
      raise CustomExceptions::Base.new(I18n.t('messages.login_saml_user'), :unauthorized) if saml_settings&.saml_enabled?
    end
  end
end
