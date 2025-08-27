class OmniauthController < ApplicationController
  skip_before_action :set_current_user

  def request
    # This will be handled by OmniAuth middleware
    # The request will be redirected to the IdP
  end

  def callback
    auth = request.env['omniauth.auth']
    account_id = params[:account_id]

    # Check if SAML is enabled for this account
    saml_settings = AccountSamlSettings.find_by(account_id: account_id, enabled: true)
    return render json: { error: 'SAML not enabled for this account' }, status: :unauthorized unless saml_settings

    if auth.present?
      # Find existing user by email
      email = auth['info']['email']
      user = User.from_email(email)

      if user
        # Create authentication token (DeviseTokenAuth way)
        @resource = user
        @token = @resource.create_token
        @resource.save!

        # Sign in the user
        sign_in(:user, @resource, store: false, bypass: false)

        # Update sign in tracking
        @resource.update_tracked_fields!(request)

        # Render success response using Chatwoot's auth template
        render partial: 'devise/auth', formats: [:json], locals: { resource: @resource }
      else
        render json: {
          error: 'User not found',
          message: "No user exists with email: #{email}"
        }, status: :not_found
      end
    else
      render json: {
        error: 'SAML authentication failed',
        message: request.env['omniauth.error'] || 'Unknown error'
      }, status: :unauthorized
    end
  end

  def failure
    render json: {
      error: 'SAML authentication failed',
      message: params[:message] || request.env['omniauth.error'] || 'Unknown error'
    }, status: :unauthorized
  end
end
