require 'httparty'
require 'jwt'

class DeviseOverrides::OmniauthCallbacksController < DeviseTokenAuth::OmniauthCallbacksController
  include EmailHelper

  def redirect_callbacks
    get_resource_from_keycloak

    @resource.present? ? sign_in_user : sign_up_user
  end

  private

  def sign_in_user
    @resource.skip_confirmation! if confirmable_enabled?

    # once the resource is found and verified
    # we can just send them to the login page again with the SSO params
    # that will log them in
    encoded_email = ERB::Util.url_encode(@resource.email)
    token = @resource.send(:set_reset_password_token)
    redirect_to login_page_url(email: encoded_email, sso_auth_token: @resource.generate_sso_auth_token)
  end

  def sign_up_user
    return redirect_to login_page_url(error: 'no-account-found') unless account_signup_allowed?

    create_account_for_user
    token = @resource.send(:set_reset_password_token)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    redirect_to "#{frontend_url}"
  end

  def login_page_url(error: nil, email: nil, sso_auth_token: nil)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    params = { email: email, sso_auth_token: sso_auth_token }.compact
    params[:error] = error if error.present?

    "#{frontend_url}/app/login?#{params.to_query}"
  end

  def resource_class(_mapping = nil)
    User
  end

  def get_resource_from_keycloak
    code = params[:code]
    redirect_to 'https://www.onehash.ai', allow_other_host: true unless code
    # Exchange code for auth token
    realm = ENV.fetch('KEYCLOAK_REALM', nil)
    keycloak_url = ENV.fetch('KEYCLOAK_URL', nil)
    token_url = URI.join(keycloak_url, "/realms/#{realm}/protocol/openid-connect/token").to_s
    userinfo_url = URI.join(keycloak_url, "/realms/#{realm}/protocol/openid-connect/userinfo").to_s
    redirect_uri = ENV.fetch('KEYCLOAK_CALLBACK_URL', nil)
    client_id = ENV.fetch('KEYCLOAK_CLIENT_ID', nil)
    client_secret = ENV.fetch('KEYCLOAK_CLIENT_SECRET', nil)

    response = HTTParty.post(token_url, {
                               body: {
                                 grant_type: 'authorization_code',
                                 client_id: client_id,
                                 client_secret: client_secret,
                                 redirect_uri: redirect_uri,
                                 code: code
                               }
                             })

    if response.success?
      # Token exchange successful
      auth_token = response.parsed_response['access_token']
      # Split the JWT token and extract the payload part
      token_payload = auth_token.split('.')[1]

      # Base64 decode the payload
      decoded_payload = Base64.urlsafe_decode64(token_payload)

      # Parse the decoded payload as JSON
      session_state = JSON.parse(decoded_payload)['session_state']
      # Use the auth token to get user info
      user_info_response = HTTParty.get(userinfo_url, {
                                          headers: {
                                            'Authorization' => "Bearer #{auth_token}"
                                          }
                                        })
      if user_info_response.success?
        # User info retrieval successful
        @user_info = user_info_response.parsed_response
        session_info = KeycloakSessionInfo.find_or_initialize_by(email: @user_info['email'])
        session_info.session_state = session_state
        session_info.token_info = response
        session_info.save
        get_resource_from_user_info
      else
        # User info retrieval failed
        redirect_to 'https://www.onehash.ai', allow_other_host: true
      end
    else
      # Token exchange failed
      redirect_to 'https://www.onehash.ai', allow_other_host: true
    end
  end

  def account_signup_allowed?
    # set it to true by default, this is the behaviour across the app
    GlobalConfigService.load('ENABLE_ACCOUNT_SIGNUP', 'false') != 'false'
  end

  def get_resource_from_user_info
    # find the user with their email
    @resource = resource_class.where(
      email: @user_info['email']
    ).first
  end

  def create_account_for_user
    @resource, @account = AccountBuilder.new(
      account_name: extract_domain_without_tld(@user_info['email']),
      user_full_name: @user_info['email'],
      email: @user_info['email'],
      locale: I18n.locale,
      confirmed: @user_info['email_verified']
    ).perform
  end

  def default_devise_mapping
    'user'
  end
end