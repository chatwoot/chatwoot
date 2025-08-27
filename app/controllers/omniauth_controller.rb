class OmniauthController < DeviseOverrides::OmniauthCallbacksController
  # We inherit from Devise's OmniAuth controller to get proper request handling
  
  def request
    # This will be handled by OmniAuth middleware
    # The request will be redirected to the IdP
  end

  def callback
    # OmniAuth populates auth_hash from request.env['omniauth.auth']
    return handle_auth_failure unless auth_hash.present?
    
    account_id = params[:account_id]
    
    # Check if SAML is enabled for this account
    saml_settings = AccountSamlSettings.find_by(account_id: account_id, enabled: true)
    unless saml_settings
      return redirect_to login_page_url(error: 'saml-not-enabled')
    end

    # Find existing user by email
    email = auth_hash['info']['email']
    @resource = User.find_by(email: email)

    if @resource
      # Use the parent class method for SSO token flow
      sign_in_user
    else
      redirect_to login_page_url(error: 'no-account-found')
    end
  end

  def failure
    redirect_to login_page_url(error: params[:message] || 'saml-auth-failed')
  end

  private

  def handle_auth_failure
    error_message = request.env['omniauth.error'] || 'Unknown error'
    redirect_to login_page_url(error: 'saml-auth-failed')
  end
end
