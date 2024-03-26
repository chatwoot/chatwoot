require 'httparty'

class DeviseOverrides::OmniauthCallbacksController < DeviseTokenAuth::OmniauthCallbacksController
  include EmailHelper

  def omniauth_success
    get_resource_from_auth_hash

    @resource.present? ? sign_in_user : sign_up_user
  end

  def redirect_callbacks
    get_resource_from_keycloak

    @resource.present? ? sign_in_user : sign_up_user_keycloak
  end

  private

  def sign_in_user
    @resource.skip_confirmation! if confirmable_enabled?

    # once the resource is found and verified
    # we can just send them to the login page again with the SSO params
    # that will log them in
    encoded_email = ERB::Util.url_encode(@resource.email)
    redirect_to login_page_url(email: encoded_email, sso_auth_token: @resource.generate_sso_auth_token)
  end

  def sign_up_user
    return redirect_to login_page_url(error: 'no-account-found') unless account_signup_allowed?

    # return redirect_to login_page_url(error: 'business-account-only') unless validate_business_account?

    create_account_for_user
    token = @resource.send(:set_reset_password_token)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    redirect_to "#{frontend_url}/app/auth/password/edit?config=default&reset_password_token=#{token}"
  end

  def sign_up_user_keycloak
    return redirect_to login_page_url(error: 'no-account-found') unless account_signup_allowed?

    create_account_for_user_keycloak(
      email: @user_email,
      name: @user_data['name'],
      locale: I18n.locale,
      confirmed: @user_data['email_verified'],
      image_url: @user_data['image']
    )

    token = @resource.send(:set_reset_password_token)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    redirect_to "#{frontend_url}/app/auth/password/edit?config=default&reset_password_token=#{token}"
  end

  def login_page_url(error: nil, email: nil, sso_auth_token: nil)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    params = { email: email, sso_auth_token: sso_auth_token }.compact
    params[:error] = error if error.present?

    "#{frontend_url}/app/login?#{params.to_query}"
  end

  def account_signup_allowed?
    # set it to true by default, this is the behaviour across the app
    GlobalConfigService.load('ENABLE_ACCOUNT_SIGNUP', 'false') != 'false'
  end

  def resource_class(_mapping = nil)
    User
  end

  def get_resource_from_auth_hash # rubocop:disable Naming/AccessorMethodName
    # find the user with their email instead of UID and token
    @resource = resource_class.where(
      email: auth_hash['info']['email']
    ).first
  end

  def get_resource_from_keycloak
    keycloak_url = 'https://sso.onehash.ai/realms/OneHash'
    client_id = ENV.fetch('KEYCLOAK_CLIENT_ID', nil)
    client_secret = ENV.fetch('KEYCLOAK_CLIENT_SECRET', nil)
    redirect_uri = ENV.fetch('KEYCLOAK_CALLBACK_URL', nil)
    # Token from params
    token = params['code']

    # Keycloak token endpoint
    token_endpoint = "#{keycloak_url}/protocol/openid-connect/token"

    # Exchange the code for an access token
    token_data = {
      grant_type: 'authorization_code',
      code: token,
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: redirect_uri
    }
    response = HTTParty.post(token_endpoint, body: token_data)
    if response.code == 200
      access_token = response.parsed_response['access_token']

      # Call Keycloak UserInfo endpoint to get user data
      user_info_endpoint = "#{keycloak_url}/protocol/openid-connect/userinfo"
      headers = { 'Authorization' => "Bearer #{access_token}" }

      user_info_response = HTTParty.get(user_info_endpoint, headers: headers)

      if user_info_response.code == 200
        @user_data = user_info_response.parsed_response
        @user_email = @user_data['email']
        @resource = resource_class.where(
          email: @user_email
        ).first
      else
        puts "Failed to get user data: #{user_info_response.body}"
      end
    else
      puts "Failed to exchange code for access token: #{response.body}"
    end
  end

  def validate_business_account?
    # return true if the user is a business account, false if it is a gmail account
    auth_hash['info']['email'].exclude?('@gmail.com')
  end

  def create_account_for_user
    @resource, @account = AccountBuilder.new(
      account_name: extract_domain_without_tld(auth_hash['info']['email']),
      user_full_name: auth_hash['info']['name'],
      email: auth_hash['info']['email'],
      locale: I18n.locale,
      confirmed: auth_hash['info']['email_verified']
    ).perform
    Avatar::AvatarFromUrlJob.perform_later(@resource, auth_hash['info']['image'])
  end

  def create_account_for_user_keycloak(email:, name:, locale:, confirmed:, image_url:)
    @resource, @account = AccountBuilder.new(
      account_name: extract_domain_without_tld(email),
      user_full_name: name,
      email: email,
      locale: locale,
      confirmed: confirmed
    ).perform

    # Perform avatar-related tasks, assuming image_url is the URL of the user's avatar
    Avatar::AvatarFromUrlJob.perform_later(@resource, image_url)
  end

  def default_devise_mapping
    'user'
  end
end
