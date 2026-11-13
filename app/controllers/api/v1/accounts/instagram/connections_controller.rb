class Api::V1::Accounts::Instagram::ConnectionsController < Api::V1::Accounts::OauthAuthorizationController
  rescue_from Instagram::UnifiedLoginService::Error, with: :render_connection_error

  def accounts
    render json: { accounts: pending_connection.accounts }
  end

  def create
    raise Instagram::UnifiedLoginService::Error, I18n.t('instagram.invalid_account') unless params[:instagram_id].is_a?(String)

    result = pending_connection.connect(params[:instagram_id])
    render json: { redirect_url: connection_redirect_url(result) }
  end

  private

  def pending_connection
    token = params[:connection_token]
    raise Instagram::UnifiedLoginService::Error, I18n.t('instagram.connection_expired') unless token.is_a?(String) && token.match?(/\A[0-9a-f]{64}\z/)

    @pending_connection ||= Instagram::PendingConnection.new(account: Current.account, token: token)
  end

  def connection_redirect_url(result)
    return app_onboarding_inbox_setup_url(account_id: Current.account.id) if result[:return_to] == 'onboarding'

    args = { account_id: Current.account.id, inbox_id: result[:inbox].id }
    result[:already_exists] ? app_instagram_inbox_settings_url(**args) : app_instagram_inbox_agents_url(**args)
  end

  def render_connection_error(error)
    render json: { error: error.message }, status: :unprocessable_entity
  end
end
