class Api::V1::Accounts::Integrations::StripeController < Api::V1::Accounts::Integrations::BaseController
  before_action :ensure_configured, only: [:auth, :customer]
  before_action :check_admin_authorization?, only: [:show, :auth, :destroy]

  def show
    hook = Current.account.hooks.find_by!(app_id: 'stripe')
    mode = Integrations::Stripe::Connection.new(hook).livemode? ? 'live' : 'sandbox'
    render json: { account_id: hook.reference_id, connected_at: hook.settings.fetch('connected_at', hook.created_at), mode: mode,
                   reauthorization_required: hook.reauthorization_required? }
  end

  def auth
    url = Integrations::Stripe::Oauth.authorize_url(account: Current.account, user: Current.user)
    state = URI.decode_www_form(URI(url).query).to_h.fetch('state')
    cookies.signed[:stripe_oauth_state] = { value: state, httponly: true, secure: request.ssl?, same_site: :lax,
                                            expires: Integrations::Stripe::Oauth::STATE_TTL.from_now }
    render json: { url: url }
  end

  def destroy
    Current.account.hooks.find_by!(app_id: 'stripe').destroy!
    head :no_content
  end

  def customer
    conversation_id = params.require(:conversation_id)
    unless conversation_id.is_a?(String) && conversation_id.match?(/\A[1-9]\d*\z/)
      return render_could_not_create_error('conversation_id must be a positive integer')
    end

    conversation = Current.account.conversations.find_by!(display_id: conversation_id)
    authorize conversation, :show?
    hook = Current.account.hooks.find_by!(app_id: 'stripe', status: :enabled)
    render json: Integrations::Stripe::CustomerSummary.new(connection: Integrations::Stripe::Connection.new(hook),
                                                           contact: conversation.contact).perform(customer_id: params[:customer_id])
  rescue Integrations::Stripe::Connection::ReauthorizationRequired, ::Stripe::AuthenticationError
    hook.prompt_reauthorization!
    render json: { error: 'stripe_reauthorization_required' }, status: :unprocessable_entity
  rescue OAuth2::Error => e
    hook.prompt_reauthorization! if e.code == 'invalid_grant'
    render json: { error: 'stripe_unavailable' }, status: :unprocessable_entity
  rescue ::Stripe::StripeError, Faraday::TimeoutError, Faraday::ConnectionFailed => e
    render_customer_failure(e)
  end

  private

  def render_customer_failure(error)
    details = { event: 'stripe_customer_fetch_failed', account_id: Current.account.id,
                request_id: request.request_id, error_class: error.class.name }
    if error.is_a?(::Stripe::StripeError)
      details.merge!(stripe_error_code: error.code, http_status: error.http_status, stripe_request_id: error.request_id)
    end
    # Exception messages, response bodies and request parameters can contain credentials or customer data.
    Rails.logger.warn(details.compact.to_json)
    render json: { error: 'stripe_unavailable' }, status: :unprocessable_entity
  end

  def ensure_configured
    head :not_found unless Integrations::App.find(id: 'stripe').active?(Current.account)
  end
end
