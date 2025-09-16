class Api::V1::AuthController < Api::BaseController
  skip_before_action :authenticate_user!, only: [:saml_login]

  def saml_login
    email = params[:email]&.downcase&.strip

    if email.blank?
      render json: { error: 'Please enter a valid email address' }, status: :bad_request
      return
    end

    # Find user by email
    user = User.find_by(email: email)

    if user.blank?
      # Generic error - don't reveal if email exists
      render json: { error: 'Please check your email and try again' }, status: :unauthorized
      return
    end

    # Find first account with SAML enabled for this user
    account_user = user.account_users
                       .joins(account: :saml_settings)
                       .where.not(saml_settings: { sso_url: [nil, ''] })
                       .where.not(saml_settings: { certificate: [nil, ''] })
                       .first

    if account_user.blank?
      render json: { error: 'SSO authentication not configured for your account' }, status: :unauthorized
      return
    end

    account = account_user.account

    # Check if account has enterprise features and SAML enabled
    unless account.feature_enabled?('saml')
      render json: { error: 'SSO authentication not available' }, status: :unauthorized
      return
    end

    # Return the OmniAuth SAML initiation URL
    # This triggers OmniAuth to generate SAML AuthnRequest and redirect to IdP
    saml_initiation_url = "/auth/saml?account_id=#{account.id}"

    render json: {
      redirect_url: saml_initiation_url
    }
  end
end
