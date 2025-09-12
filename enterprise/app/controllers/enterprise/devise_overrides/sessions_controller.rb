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

  def saml_user_attempting_password_login?
    return false if params[:email].blank?

    user = User.from_email(params[:email])
    return false unless user&.provider == 'saml'

    return false if params[:sso_auth_token].present? && user.valid_sso_auth_token?(params[:sso_auth_token])

    true
  end
end
