class Stripe::CallbacksController < ApplicationController
  OAUTH_ERROR_CODES = %w[invalid_request invalid_client invalid_grant unauthorized_client unsupported_grant_type
                         invalid_scope access_denied server_error temporarily_unavailable].freeze

  before_action :load_installation

  def show
    return authorization_failed('provider_error') if params[:error].present?
    return authorization_failed('missing_code') if params[:code].blank?

    token = Integrations::Stripe::Oauth.client.auth_code.get_token(params[:code], redirect_uri: Integrations::Stripe::Oauth.callback_url)
    return authorization_failed('token_mode_mismatch') unless token.params.fetch('livemode') == @livemode

    save_connection(token)
    redirect_to destination
  rescue OAuth2::Error => e
    authorization_failed('token_exchange_failed', oauth_error: safe_oauth_error_code(e.code), http_status: e.response.status)
  end

  private

  def safe_oauth_error_code(code)
    # Provider messages and response bodies can contain credentials. Only log known error codes.
    OAUTH_ERROR_CODES.include?(code) ? code : 'unknown'
  end

  def authorization_failed(reason, **details)
    Rails.logger.warn({ event: 'stripe_oauth_authorization_failed', reason: reason, account_id: @account.id,
                        request_id: request.request_id, expected_livemode: @livemode }.merge(details).to_json)
    redirect_to "#{destination}?error=authorization_failed"
  end

  def save_connection(token)
    @account.with_lock do
      hook = @account.hooks.find_or_initialize_by(app_id: 'stripe')
      hook.reference_id = token.params.fetch('stripe_user_id')
      hook.status = :enabled
      hook.settings = hook.settings.merge('livemode' => @livemode, 'connected_at' => Time.current.iso8601)
      Integrations::Stripe::Connection.new(hook).store_token!(token)
    end
  end

  def load_installation
    return head :not_found unless Integrations::Stripe::Oauth.configured?

    state = Integrations::Stripe::Oauth.consume_state(params[:state])
    return head :bad_request unless state

    @account = Account.find(state.fetch('account_id'))
    return head :not_found unless @account.feature_enabled?('stripe_integration')

    @livemode = state.fetch('livemode')
    return head :bad_request unless @livemode == Integrations::Stripe::Oauth.livemode?

    head :forbidden unless @account.account_users.exists?(user_id: state.fetch('user_id'), role: :administrator)
  end

  def destination
    "#{ENV.fetch('FRONTEND_URL')}/app/accounts/#{@account.id}/settings/integrations/stripe"
  end
end
