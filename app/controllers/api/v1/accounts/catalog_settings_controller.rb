class Api::V1::Accounts::CatalogSettingsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_catalog_settings

  def show; end

  def create
    @catalog_settings = Current.account.build_catalog_settings(catalog_settings_params)
    if @catalog_settings.save
      render :show
    else
      render json: { errors: @catalog_settings.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @catalog_settings.update(catalog_settings_params)
      render :show
    else
      render json: { errors: @catalog_settings.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_catalog_settings
    @catalog_settings = Current.account.catalog_settings ||
                        Current.account.build_catalog_settings
  end

  def catalog_settings_params
    params.require(:catalog_settings).permit(
      :enabled,
      :payment_provider,
      :currency
    )
  end

  def check_authorization
    authorize(AccountCatalogSettings)
  end
end
