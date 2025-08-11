class Api::V1::Accounts::Whatsapp::AuthorizationsController < Api::V1::Accounts::BaseController
  before_action :validate_feature_enabled!

  # POST /api/v1/accounts/:account_id/whatsapp/authorization
  # Handles the embedded signup callback data from the Facebook SDK
  def create
    validate_embedded_signup_params!
    channel = process_embedded_signup
    render_success_response(channel.inbox)
  rescue StandardError => e
    render_error_response(e)
  end

  private

  def process_embedded_signup
    service = Whatsapp::EmbeddedSignupService.new(
      account: Current.account,
      code: params[:code],
      business_id: params[:business_id],
      waba_id: params[:waba_id],
      phone_number_id: params[:phone_number_id],
      is_business_app_onboarding: params[:is_business_app_onboarding]
    )
    service.perform
  end

  def render_success_response(inbox)
    render json: {
      success: true,
      id: inbox.id,
      name: inbox.name,
      channel_type: 'whatsapp'
    }
  end

  def render_error_response(error)
    Rails.logger.error "[WHATSAPP AUTHORIZATION] Embedded signup error: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    render json: {
      success: false,
      error: error.message
    }, status: :unprocessable_entity
  end

  def validate_feature_enabled!
    return if Current.account.feature_whatsapp_embedded_signup?

    render json: {
      success: false,
      error: 'WhatsApp embedded signup is not enabled for this account'
    }, status: :forbidden
  end

  def validate_embedded_signup_params!
    missing_params = []
    missing_params << 'code' if params[:code].blank?
    missing_params << 'business_id' if params[:business_id].blank?
    missing_params << 'waba_id' if params[:waba_id].blank?

    return if missing_params.empty?

    raise ArgumentError, "Required parameters are missing: #{missing_params.join(', ')}"
  end
end
