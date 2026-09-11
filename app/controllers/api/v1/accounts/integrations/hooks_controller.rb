class Api::V1::Accounts::Integrations::HooksController < Api::V1::Accounts::Integrations::BaseController
  before_action :fetch_hook, except: [:create]
  before_action :check_authorization
  before_action :ensure_shopify_enabled, if: :shopify_hook?
  before_action :ensure_stripe_enabled

  def create
    @hook = Current.account.hooks.create!(permitted_params)
  end

  def update
    @hook.update!(permitted_params.slice(:status, :settings))
  end

  def process_event
    response = @hook.process_event(params[:event])

    # for cases like an invalid event, or when conversation does not have enough messages
    # for a label suggestion, the response is nil
    if response.nil?
      render json: { message: nil }
    elsif response[:error]
      render json: { error: response[:error] }, status: :unprocessable_entity
    else
      render json: { message: response[:message] }
    end
  end

  def destroy
    @hook.destroy!
    head :ok
  end

  private

  def ensure_stripe_enabled
    app_id = action_name == 'create' ? permitted_params[:app_id] : @hook.app_id
    return unless app_id == 'stripe'

    head :not_found unless Integrations::App.find(id: 'stripe').active?(Current.account)
  end

  def fetch_hook
    @hook = Current.account.hooks.find(params[:id])
  end

  def permitted_params
    params.require(:hook).permit(:app_id, :inbox_id, :status, settings: {})
  end

  def shopify_hook?
    action_name == 'create' ? permitted_params[:app_id] == 'shopify' : @hook.app_id == 'shopify'
  end

  def ensure_shopify_enabled
    head :not_found unless Shopify::FeatureGate.enabled?(account: Current.account)
  end
end
