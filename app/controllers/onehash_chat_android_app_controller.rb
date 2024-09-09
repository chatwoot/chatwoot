class OnehashChatAndroidAppController < ApplicationController
  include EmailHelper
  include AuthHelper

  def authenticate
    headers = request.headers
    body = request.body.read
    parsed_body = JSON.parse(body)
    email = parsed_body['email']
    return unless valid_access_token?(headers['Authorization'], email)

    send_auth_headers(@user)
    render json: { success: true, message: 'Mobile authentication successful', user: @payload }
  end

  private

  def valid_access_token?(bearer_token, email)
    realm = ENV.fetch('KEYCLOAK_REALM', nil)
    keycloak_url = ENV.fetch('KEYCLOAK_URL', nil)
    introspect_url = URI.join(keycloak_url, "/realms/#{realm}/protocol/openid-connect/token/introspect").to_s
    client_id = ENV.fetch('KEYCLOAK_CLIENT_ID', nil)
    client_secret = ENV.fetch('KEYCLOAK_CLIENT_SECRET', nil)
    access_token = bearer_token.split(' ').last
    introspect_res = HTTParty.post(
      introspect_url,
      body: URI.encode_www_form({
                                  client_id: client_id,
                                  client_secret: client_secret,
                                  token: access_token

                                }),
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    )
    return unless introspect_res['active']

    get_resource(email)
    create_account(email) if @user.blank?
    account = AccountUser.find_by(user_id: @user.id)
    all_accounts_of_user = AccountUser.where(user_id: @user.id)
    all_accounts_of_user_transformed = all_accounts_of_user.map do |account_user|
      account_user.attributes.merge(
        id: account_user.account_id,
        status: Account.find_by(id: account_user.account_id).status,
        name: Account.find_by(id: account_user.account_id).name,
        availability_status: account_user.availability_status
      )
    end
    @payload = {
      name: @user.name,
      id: @user.id,
      account_id: account.account_id,
      accounts: all_accounts_of_user_transformed,
      email: @user.email,
      pubsub_token: @user.pubsub_token,
      avatar_url: @user.avatar_url,
      available_name: @user.name,
      role: account.role
    }
    @payload
  end

  def get_resource(email)
    # find the user with their email
    @user = User.where(email: email).first
  end

  def create_account(email)
    @user, @account = AccountBuilder.new(
      account_name: extract_domain_without_tld(email),
      user_full_name: email,
      email: email,
      locale: I18n.locale,
      confirmed: true
    ).perform
  end
end
