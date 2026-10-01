# Custom apps attach only to the account/store provisioned by an operator. They never create accounts.
class Shopify::CustomCallbacksController < Shopify::CallbacksController
  def show
    @custom_app = Shopify::CustomApp.enabled.find(request.path_parameters.fetch(:custom_app_id))
    @account = @custom_app.account
    @account_id = @account.id
    validate_installation!

    Shopify::InstallationGeneration.with_shop_lock(@custom_app.shop_domain) do
      @custom_app.with_lock do
        raise 'Custom app is disabled' unless @custom_app.enabled?

        params[:code].present? ? complete_authorization : begin_authorization
      end
    end
  rescue StandardError => e
    Rails.logger.warn("Shopify custom app callback failed: #{e.class.name}")
    redirect_to error_redirect_url, allow_other_host: true
  end

  private

  def validate_installation!
    ensure_shopify_enabled!(account: account)
    raise 'Shopify billing cannot use a custom app' if account.internal_attributes['billing_provider'] == 'shopify'
    raise 'Invalid shop domain' unless params[:shop] == @custom_app.shop_domain
    raise 'Invalid HMAC signature' unless valid_hmac?
    raise 'Shopify authorization was denied' if params[:error].present?
  end

  def begin_authorization
    hook = account.hooks.find_by(app_id: 'shopify')
    if hook&.settings&.fetch('custom_app_id', nil) == @custom_app.id && reusable_hook?(hook)
      return redirect_to shopify_integration_url, allow_other_host: true
    end

    state = SecureRandom.hex(16)
    Redis::SecureStorage.set(
      oauth_state_key(state),
      { generation: Shopify::InstallationGeneration.current(account), app_generation: @custom_app.installation_generation },
      10.minutes
    )
    redirect_to oauth_client.auth_code.authorize_url(
      redirect_uri: redirect_callback_uri, scope: REQUIRED_SCOPES.join(','), state: state
    ), allow_other_host: true
  end

  def complete_authorization
    state = params[:state].to_s
    raise 'Invalid state parameter' unless state.match?(/\A[0-9a-f]{32}\z/)

    stored_state = JSON.parse(Redis::SecureStorage.get(oauth_state_key(state)).to_s)
    Redis::SecureStorage.delete(oauth_state_key(state))
    raise 'Custom app installation changed' unless stored_state.fetch('app_generation') == @custom_app.installation_generation

    @shopify_installation_generation = stored_state.fetch('generation')
    exchange_access_token
    create_hook
    redirect_to shopify_integration_url, allow_other_host: true
  end

  def client_id = @custom_app.client_id
  def client_secret = @custom_app.client_secret
  def redirect_callback_uri = "#{frontend_url}#{@custom_app.callback_path}"
  def oauth_state_key(state) = "shopify_custom_oauth:#{@custom_app.id}:#{state}"

  def shopify_hook_settings
    super.merge(custom_app_id: @custom_app.id)
  end

  # The base implementation intentionally refuses to reuse custom-app tokens for the public app.
  def reusable_hook?(hook)
    hook&.enabled? && hook.access_token.present? &&
      (REQUIRED_SCOPES - hook.settings['scope'].to_s.split(',').map(&:strip)).empty?
  end

  def ensure_shopify_enabled!(account: nil)
    raise 'Shopify integration is disabled' unless Shopify::FeatureGate.enabled?(account: account)
  end
end
