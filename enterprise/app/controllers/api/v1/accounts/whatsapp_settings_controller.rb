class Api::V1::Accounts::WhatsappSettingsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_whatsapp_settings

  def show; end

  def create
    @whatsapp_settings = Current.account.build_whatsapp_settings(whatsapp_settings_params)
    if @whatsapp_settings.save
      render :show
    else
      render json: { errors: @whatsapp_settings.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @whatsapp_settings.update(whatsapp_settings_params)
      render :show
    else
      render json: { errors: @whatsapp_settings.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @whatsapp_settings.destroy!
    head :no_content
  end

  private

  def set_whatsapp_settings
    @whatsapp_settings = Current.account.whatsapp_settings ||
                         Current.account.build_whatsapp_settings
  end

  def whatsapp_settings_params
    params.require(:whatsapp_settings).permit(
      :app_id,
      :app_secret,
      :configuration_id,
      :verify_token,
      :api_version
    )
  end

  def check_authorization
    authorize(AccountWhatsappSettings)
  end
end
