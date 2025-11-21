class Api::V1::Accounts::PayzahSettingsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_payzah_settings

  def show; end

  def create
    @payzah_settings = Current.account.build_payzah_settings(payzah_settings_params)
    if @payzah_settings.save
      render :show
    else
      render json: { errors: @payzah_settings.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @payzah_settings.update(payzah_settings_params)
      render :show
    else
      render json: { errors: @payzah_settings.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @payzah_settings.destroy!
    head :no_content
  end

  private

  def set_payzah_settings
    @payzah_settings = Current.account.payzah_settings ||
                       Current.account.build_payzah_settings
  end

  def payzah_settings_params
    params.require(:payzah_settings).permit(
      :api_key,
      :enabled
    )
  end

  def check_authorization
    authorize(AccountPayzahSettings)
  end
end
