module Enterprise::DeviseOverrides::PasswordsController
  include SamlAuthenticationHelper

  def create
    if saml_user_attempting_password_auth?(params[:email])
      render json: {
        success: false,
        message: I18n.t('messages.reset_password_saml_user'),
        errors: [I18n.t('messages.reset_password_saml_user')]
      }, status: :forbidden
      return
    end

    super
  end
end
