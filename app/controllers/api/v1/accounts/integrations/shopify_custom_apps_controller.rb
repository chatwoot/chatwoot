class Api::V1::Accounts::Integrations::ShopifyCustomAppsController < Api::V1::Accounts::Integrations::BaseController
  before_action -> { authorize(:hook, :create?) }
  before_action :ensure_shopify_enabled

  def show
    render_configuration(Current.account.shopify_custom_app)
  end

  rescue_from ActiveRecord::RecordInvalid, ActionController::BadRequest do
    render json: { error: 'Invalid Shopify custom app configuration' }, status: :unprocessable_entity
  end

  def create
    return head :conflict if Current.account.shopify_custom_app

    custom_app = Current.account.build_shopify_custom_app(configuration_params.merge(enabled: false))
    custom_app.save!
    render_configuration(custom_app)
  end

  def update
    custom_app = Current.account.shopify_custom_app || raise(ActiveRecord::RecordNotFound)
    attributes = configuration_params
    attributes.delete(:client_secret) if attributes[:client_secret] == ''
    custom_app.with_lock do
      custom_app.update!(attributes)
      custom_app.invalidate_authorizations!
    end
    render_configuration(custom_app)
  end

  def destroy
    Current.account.with_lock do
      return head :conflict if Current.account.hooks.exists?(app_id: 'shopify')

      Current.account.shopify_custom_app&.destroy!
    end
    head :ok
  end

  private

  def ensure_shopify_enabled
    return head :not_found unless Shopify::FeatureGate.custom_apps_enabled?(account: Current.account)
    return unless Current.account.internal_attributes['billing_provider'] == 'shopify'

    render json: { error: 'Shopify billing cannot use a custom app' }, status: :unprocessable_entity
  end

  def configuration_params
    permitted = action_name == 'create' ? %i[shop_domain client_id client_secret install_url] : %i[client_secret install_url enabled]
    params.permit(*permitted).tap do |attributes|
      attributes.each do |key, value|
        valid = key == 'enabled' ? [true, false].include?(value) : value.is_a?(String)
        raise ActionController::BadRequest, "Invalid #{key}" unless valid
      end
    end
  end

  def render_configuration(custom_app)
    return render json: { custom_app: nil } unless custom_app

    origin = ENV.fetch('FRONTEND_URL')
    render json: { custom_app: {
      shop_domain: custom_app.shop_domain, client_id: custom_app.client_id, enabled: custom_app.enabled?,
      callback_url: "#{origin}#{custom_app.callback_path}", webhook_url: "#{origin}#{custom_app.webhook_path}"
    } }
  end
end
