class Stripe::CallbacksController < ApplicationController
  before_action :load_installation

  def show
    return redirect_to "#{destination}?error=authorization_failed" if params[:error].present? || params[:code].blank?

    token = Integrations::Stripe::Oauth.client.auth_code.get_token(params[:code], redirect_uri: Integrations::Stripe::Oauth.callback_url)
    return redirect_to "#{destination}?error=authorization_failed" unless token.params.fetch('livemode') == @livemode

    save_connection(token)
    redirect_to destination
  rescue OAuth2::Error
    redirect_to "#{destination}?error=authorization_failed"
  end

  private

  def save_connection(token)
    @account.with_lock do
      hook = @account.hooks.find_or_initialize_by(app_id: 'stripe')
      hook.reference_id = token.params.fetch('stripe_user_id')
      hook.status = :enabled
      hook.settings = hook.settings.merge('livemode' => @livemode)
      Integrations::Stripe::Connection.new(hook).store_token!(token)
    end
  end

  def load_installation
    return head :not_found unless Integrations::Stripe::Oauth.configured?

    state = Integrations::Stripe::Oauth.consume_state(params[:state])
    return head :bad_request unless state

    @account = Account.find(state.fetch('account_id'))
    @livemode = state.fetch('livemode')
    return head :bad_request unless @livemode == Integrations::Stripe::Oauth.livemode?

    head :forbidden unless @account.account_users.exists?(user_id: state.fetch('user_id'), role: :administrator)
  end

  def destination
    "#{ENV.fetch('FRONTEND_URL')}/app/accounts/#{@account.id}/settings/integrations/stripe"
  end
end
