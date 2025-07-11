class Api::V1::Accounts::Whatsapp::CallbacksController < Api::V1::Accounts::BaseController
  before_action :validate_whatsapp_params, only: [:embedded_signup]

  def embedded_signup
    channel = process_signup
    @inbox = channel.inbox
  rescue StandardError => e
    handle_signup_error(e)
  end

  def config
    render json: {
      status: 'ready',
      app_id: GlobalConfigService.load('WHATSAPP_APP_ID', ''),
      config_id: GlobalConfigService.load('WHATSAPP_CONFIGURATION_ID', '')
    }
  end

  private

  def validate_whatsapp_params
    return render_error('Missing authorization code', 'Authorization code is required') if params[:code].blank?
    return render_error('Missing business_id', 'business_id is required') if params[:business_id].blank?
    return render_error('Missing waba_id', 'waba_id is required') if params[:waba_id].blank?
  end

  def render_error(error, message)
    render json: {
      error: error,
      message: message
    }, status: :bad_request
  end

  def process_signup
    service = Whatsapp::EmbeddedSignupService.new(
      account: Current.account,
      code: params[:code],
      business_id: params[:business_id],
      waba_id: params[:waba_id],
      phone_number_id: params[:phone_number_id]
    )

    service.perform
  end

  def handle_signup_error(error)
    Rails.logger.error("[WHATSAPP] Embedded signup processing error: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))
    render json: {
      error: 'Internal server error',
      message: error.message
    }, status: :internal_server_error
  end
end