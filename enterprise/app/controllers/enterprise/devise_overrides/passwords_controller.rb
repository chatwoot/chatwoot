module Enterprise::DeviseOverrides::PasswordsController
  def create
    if saml_user_attempting_password_reset?
      render json: {
        success: false,
        errors: [I18n.t('messages.reset_password_saml_user')]
      }, status: :forbidden
      return
    end

    super
  end

  private

  def saml_user_attempting_password_reset?
    return false if params[:email].blank?

    user = User.from_email(params[:email])
    return false unless user&.provider == 'saml'

    true
  end
end
