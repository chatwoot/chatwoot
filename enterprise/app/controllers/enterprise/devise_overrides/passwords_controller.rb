module Enterprise::DeviseOverrides::PasswordsController
  def create
    check_saml_user
    super
  rescue CustomExceptions::Base => e
    build_response(e.message, e.http_status_code)
  end

  private

  def check_saml_user
    return if params[:email].blank?

    user = User.from_email(params[:email])
    return unless user&.provider == 'saml'

    raise CustomExceptions::Base.new(I18n.t('messages.reset_password_saml_user'), :forbidden)
  end
end
