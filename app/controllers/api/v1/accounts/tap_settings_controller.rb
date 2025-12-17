class Api::V1::Accounts::TapSettingsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_tap_settings

  def show; end

  def create
    @tap_settings = Current.account.build_tap_settings(tap_settings_params)
    if @tap_settings.save
      render :show
    else
      render json: { errors: @tap_settings.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @tap_settings.update(tap_settings_params)
      render :show
    else
      render json: { errors: @tap_settings.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @tap_settings.destroy!
    head :no_content
  end

  private

  def set_tap_settings
    @tap_settings = Current.account.tap_settings ||
                    Current.account.build_tap_settings
  end

  def tap_settings_params
    params.require(:tap_settings).permit(
      :secret_key,
      :enabled
    )
  end

  def check_authorization
    authorize(AccountTapSettings)
  end
end
