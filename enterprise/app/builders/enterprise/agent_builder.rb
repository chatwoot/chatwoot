module Enterprise::AgentBuilder
  def find_or_create_user
    user = User.from_email(email)
    return configure_existing_user_for_saml(user) if user

    create_user_for_saml_account
  end

  private

  def configure_existing_user_for_saml(user)
    if account.saml_enabled? && !(user.provider == 'saml')
      # Convert existing user to SAML if account has SAML enabled
      user.update!(provider: 'saml')
    end
    user
  end

  def create_user_for_saml_account
    if account.saml_enabled?
      # For SAML-enabled accounts, create user with SAML provider and secure password
      temp_password = "1!aA#{SecureRandom.alphanumeric(12)}"
      User.create!(
        email: email,
        name: name,
        password: temp_password,
        password_confirmation: temp_password,
        provider: 'saml'
      )
    else
      # Use the default behavior for non-SAML accounts
      super
    end
  end
end
