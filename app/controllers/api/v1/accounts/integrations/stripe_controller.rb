class Api::V1::Accounts::Integrations::StripeController < Api::V1::Accounts::Integrations::BaseController
  before_action :ensure_configured
  before_action :check_admin_authorization?, only: [:show, :auth, :destroy]

  def show
    hook = Current.account.hooks.find_by!(app_id: 'stripe', status: :enabled)
    mode = Integrations::Stripe::Connection.new(hook).livemode? ? 'live' : 'sandbox'
    render json: { account_id: hook.reference_id, connected_at: hook.created_at, mode: mode }
  end

  def auth
    render json: { url: Integrations::Stripe::Oauth.authorize_url(account: Current.account, user: Current.user) }
  end

  def destroy
    Current.account.hooks.find_by!(app_id: 'stripe').destroy!
    head :no_content
  end

  def customer
    conversation = Current.account.conversations.find_by!(display_id: params.require(:conversation_id))
    authorize conversation, :show?
    hook = Current.account.hooks.find_by!(app_id: 'stripe', status: :enabled)
    connection = Integrations::Stripe::Connection.new(hook)
    render json: Integrations::Stripe::CustomerSummary.new(connection: connection,
                                                           contact: conversation.contact).perform(customer_id: params[:customer_id])
  rescue ::Stripe::StripeError, OAuth2::Error
    render json: { error: 'stripe_unavailable' }, status: :unprocessable_entity
  end

  private

  def ensure_configured
    head :not_found unless Integrations::Stripe::Oauth.configured?
  end
end
