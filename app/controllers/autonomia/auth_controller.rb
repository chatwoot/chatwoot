# frozen_string_literal: true

require 'base64'
require 'digest'

class Autonomia::AuthController < ApplicationController
  STATE_TTL = 10.minutes
  SESSION_STATES_KEY = :autonomia_sso_states

  skip_before_action :authenticate_user!, raise: false

  def start
    return redirect_to login_page_url(error: 'autonomia-sso-disabled') unless sso_enabled?

    verifier = SecureRandom.urlsafe_base64(64)
    state = store_state(code_verifier: verifier, return_to: permitted_return_to)

    redirect_to authorization_url(state, verifier), allow_other_host: true
  end

  def callback
    return redirect_to login_page_url(error: 'autonomia-sso-error') if params[:error].present?

    state = consume_state
    return redirect_to login_page_url(error: 'autonomia-sso-state') if state.blank?

    client = Autonomia::Sso::Client.new
    token = client.exchange_code!(
      code: params.require(:code),
      redirect_uri: callback_url,
      code_verifier: state[:code_verifier]
    )
    context = client.fetch_context!(token.context_token)
    provisioner = Autonomia::Sso::Provisioner.new(context: context, token: token)
    user = provisioner.perform

    redirect_to login_page_url(
      email: user.email,
      sso_auth_token: user.generate_sso_auth_token,
      redirect_to: provisioner.post_login_redirect_path
    )
  rescue StandardError => e
    Rails.logger.error("[Autonomia SSO] #{e.class}: #{e.message}")
    redirect_to login_page_url(error: 'autonomia-sso-error')
  end

  private

  def authorization_url(state, verifier)
    uri = URI.join(issuer_url, '/login')
    uri.query = {
      client_id: client_id,
      redirect_uri: callback_url,
      response_type: 'code',
      scope: 'openid email profile',
      state: state,
      code_challenge: pkce_challenge(verifier),
      code_challenge_method: 'S256',
      prompt: permitted_prompt,
      return_to: permitted_return_to
    }.compact.to_query
    uri.to_s
  end

  def store_state(code_verifier:, return_to:)
    token = SecureRandom.urlsafe_base64(32)
    states = current_states
    states[token] = {
      code_verifier: code_verifier,
      return_to: return_to,
      expires_at: STATE_TTL.from_now.to_i
    }.compact
    session[SESSION_STATES_KEY] = states
    token
  end

  def consume_state
    states = current_states
    state = states.delete(params[:state].to_s)
    session[SESSION_STATES_KEY] = states

    return if state.blank?

    state = state.with_indifferent_access
    return if state[:expires_at].to_i < Time.current.to_i
    return if state[:code_verifier].blank?

    state
  end

  def pkce_challenge(verifier)
    Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
  end

  def current_states
    states = (session[SESSION_STATES_KEY] || {}).to_h
    states.select do |_token, state|
      state.to_h.with_indifferent_access[:expires_at].to_i >= Time.current.to_i
    end
  end

  def callback_url
    ENV.fetch('AUTONOMIA_AUTH_REDIRECT_URI', "#{frontend_url}/auth/autonomia/callback")
  end

  def permitted_return_to
    return nil if params[:return_to].blank?

    value = params[:return_to].to_s
    value.start_with?('/app') ? value : nil
  end

  def permitted_prompt
    params[:prompt].to_s == 'login' ? 'login' : nil
  end

  def login_page_url(error: nil, email: nil, sso_auth_token: nil, redirect_to: nil)
    query = {
      email: email,
      sso_auth_token: sso_auth_token,
      redirect_to: permitted_login_redirect(redirect_to)
    }.compact
    query[:error] = error if error.present?
    "#{frontend_url}/app/login?#{query.to_query}"
  end

  def permitted_login_redirect(value)
    return if value.blank?

    value.to_s.start_with?('/app/') ? value : nil
  end

  def frontend_url
    ENV.fetch('FRONTEND_URL', request.base_url)
  end

  def issuer_url
    ENV.fetch('AUTONOMIA_AUTH_ISSUER', 'https://auth.autonomia.site').delete_suffix('/')
  end

  def client_id
    ENV.fetch('AUTONOMIA_AUTH_CLIENT_ID', 'talkai')
  end

  def sso_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('AUTONOMIA_SSO_ENABLED', true))
  end
end
