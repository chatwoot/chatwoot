class Api::V1::Accounts::PaymentLinkSettingsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_payment_link_settings

  def show; end

  def create
    @payment_link_settings = Current.account.build_payment_link_settings(payment_link_settings_params)
    if @payment_link_settings.save
      render :show
    else
      render json: { errors: @payment_link_settings.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @payment_link_settings.update(payment_link_settings_params)
      render :show
    else
      render json: { errors: @payment_link_settings.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_payment_link_settings
    @payment_link_settings = Current.account.payment_link_settings ||
                             Current.account.build_payment_link_settings
  end

  def payment_link_settings_params
    params.require(:payment_link_settings).permit(
      :default_provider,
      :default_currency,
      :notification_email
    )
  end

  def check_authorization
    authorize(AccountPaymentLinkSettings)
  end
end
