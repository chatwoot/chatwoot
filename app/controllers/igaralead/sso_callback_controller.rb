# frozen_string_literal: true

# Handles the OAuth2 callback from the IgaraLead SSO service.
#
# Flow:
#   1. User clicks "Sign in with SSO" → Nexus redirects to SSO /authorize
#   2. SSO authenticates user → redirects back here with ?code=...
#   3. This controller exchanges the code for a JWT at SSO /token
#   4. Validates JWT, finds/creates local Nexus User
#   5. Generates sso_auth_token → redirects to frontend login page
#   6. Frontend calls POST /auth/sign_in with sso_auth_token (standard Devise flow)
class Igaralead::SsoCallbackController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  # GET /igaralead/sso/callback?code=...&state=...
  def show # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    code = params[:code]
    redirect_to login_page_url(error: 'missing-code') and return if code.blank?

    # Exchange auth code for JWT
    token_data = exchange_code(code)
    redirect_to login_page_url(error: 'token-exchange-failed') and return unless token_data

    access_token = token_data['access_token']
    payload = Igaralead::HubTokenValidator.validate(access_token)
    redirect_to login_page_url(error: 'invalid-token') and return unless payload

    email = payload['email']
    name = payload['name']
    hub_user_id = payload['user_id']&.to_s
    roles = payload['roles'] || []
    memberships = payload['memberships'] || []

    # Find account with nexus active
    nexus_membership = memberships.find { |m| m.dig('active_products', 'nexus') }
    client_slug = nexus_membership&.dig('slug')
    account = client_slug.present? ? Account.find_by(hub_client_slug: client_slug) : nil

    unless account
      Rails.logger.warn("[Igaralead::SsoCallback] No account for slug=#{client_slug} user=#{email}")
      redirect_to login_page_url(error: 'no-account-found') and return
    end

    is_super_admin = roles.include?('super_admin')
    redirect_to login_page_url(error: 'product-not-active') and return unless is_super_admin || nexus_membership.present?

    user = find_or_create_user(hub_user_id, email, name, roles, account)
    redirect_to login_page_url(error: 'user-creation-failed') and return unless user

    sso_token = user.generate_sso_auth_token
    redirect_to login_page_url(
      email: user.email,
      sso_auth_token: sso_token,
      account_id: account.id
    )
  end

  # GET /igaralead/sso — initiates SSO flow by redirecting to SSO /authorize
  def create
    state = SecureRandom.hex(16)
    session[:sso_state] = state

    redirect_to sso_authorize_url(state), allow_other_host: true
  end

  private

  def exchange_code(code)
    uri = URI("#{sso_url}/token")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = Net::HTTP::Post.new(uri)
    request.set_form_data(
      grant_type: 'authorization_code',
      code: code,
      client_id: sso_client_id,
      client_secret: sso_client_secret,
      redirect_uri: sso_redirect_uri
    )

    response = http.request(request)
    return nil unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error("[Igaralead::SsoCallback] Token exchange failed: #{e.message}")
    nil
  end

  def find_or_create_user(hub_user_id, email, name, roles, account) # rubocop:disable Metrics/MethodLength
    user = hub_user_id.present? ? User.find_by(hub_id: hub_user_id) : nil
    user ||= User.from_email(email) if email.present?

    if user
      user.update(hub_id: hub_user_id, hub_synced_at: Time.current) if user.hub_id.blank? && hub_user_id.present?
    else
      return nil if email.blank?

      user = User.new(
        email: email,
        name: name.presence || email.split('@').first,
        hub_id: hub_user_id,
        hub_synced_at: Time.current,
        password: SecureRandom.alphanumeric(24),
        confirmed_at: Time.current
      )
      user.skip_confirmation!
      user.save!
    end

    ensure_account_user(user, account, roles)
    user
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[Igaralead::SsoCallback] User creation failed: #{e.message}")
    nil
  end

  def ensure_account_user(user, account, hub_roles)
    account_user = AccountUser.find_by(user: user, account: account)
    return account_user if account_user

    role = hub_roles.include?('admin') || hub_roles.include?('super_admin') ? :administrator : :agent
    AccountUser.create!(user: user, account: account, role: role)
  end

  def sso_url
    ENV.fetch('SSO_URL', 'http://localhost:8003')
  end

  def sso_client_id
    ENV.fetch('SSO_CLIENT_ID', 'nexus')
  end

  def sso_client_secret
    ENV.fetch('SSO_CLIENT_SECRET', '')
  end

  def sso_redirect_uri
    "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/igaralead/sso/callback"
  end

  def sso_authorize_url(state)
    params = {
      client_id: sso_client_id,
      redirect_uri: sso_redirect_uri,
      response_type: 'code',
      state: state
    }
    "#{sso_url}/authorize?#{params.to_query}"
  end

  def login_page_url(**params)
    frontend_url = ENV.fetch('FRONTEND_URL', '')
    query = params.any? ? "?#{params.to_query}" : ''
    "#{frontend_url}/app/login#{query}"
  end
end
