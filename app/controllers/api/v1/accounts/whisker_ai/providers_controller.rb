class Api::V1::Accounts::WhiskerAi::ProvidersController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_provider, only: [:update, :destroy]

  def index
    @providers = current_account.whisker_ai_providers.order(:fallback_order)
  end

  def create
    @provider = current_account.whisker_ai_providers.build(provider_params)
    if @provider.save
      render json: @provider, status: :ok
    else
      render json: { errors: @provider.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @provider.update(provider_params)
      render json: @provider, status: :ok
    else
      render json: { errors: @provider.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @provider.destroy
    head :ok
  end

  def set_primary
    @provider = current_account.whisker_ai_providers.find(params[:id])
    current_account.whisker_ai_providers.find_each { |p| p.update!(is_primary: false) if p.is_primary? }
    @provider.update!(is_primary: true)
    render json: @provider
  end

  private

  def fetch_provider
    @provider = current_account.whisker_ai_providers.find(params[:id])
  end

  def provider_params
    params.require(:provider).permit(:name, :base_url, :api_key, :is_primary, :fallback_order, :monthly_cap, :enabled, models: [])
  end
end
