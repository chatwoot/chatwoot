class Whatsapp::EmbeddedController < ApplicationController
  include EnsureCurrentAccountHelper

  before_action :authenticate_user!
  before_action :current_account
  before_action :check_authorization

  def new
    # Configuration endpoint for embedded signup initialization
    render json: {
      status: 'ready',
      app_id: GlobalConfigService.load('WHATSAPP_APP_ID', ''),
      config_id: GlobalConfigService.load('WHATSAPP_CONFIGURATION_ID', ''),
      app_secret: GlobalConfigService.load('WHATSAPP_APP_SECRET', '')
    }
  end

  def embedded_signup
    # Complete embedded signup using auth code + business info from frontend
    validate_authorization_code!
    return if performed?

    validate_required_parameters!
    return if performed?

    channel = process_signup
    @inbox = channel.inbox

    # Return the inbox object using the standard jbuilder template
    render 'embedded_signup', formats: [:json]
  rescue StandardError => e
    handle_signup_error(e)
  end

  def reauthorize
    # Reauthorize existing WhatsApp inbox using embedded signup flow
    validate_authorization_code!
    return if performed?

    validate_required_parameters!
    return if performed?

    validate_inbox_id!
    return if performed?

    channel = process_reauthorization
    @inbox = channel.inbox

    # Clear reauthorization required flag
    channel.reauthorized!

    render json: { message: 'WhatsApp channel reauthorized successfully' }, status: :ok
  rescue StandardError => e
    handle_signup_error(e)
  end

  private

  def validate_authorization_code!
    return if params[:code].present?

    render json: {
      error: 'Missing authorization code',
      message: 'Authorization code is required for embedded signup'
    }, status: :bad_request
  end

  def validate_required_parameters!
    return if params[:business_id].present? && params[:waba_id].present?

    render json: {
      error: 'Missing required parameters: business_id and waba_id are required'
    }, status: :bad_request
  end

  def validate_inbox_id!
    return if params[:inbox_id].present?

    render json: {
      error: 'Missing inbox_id parameter'
    }, status: :bad_request
  end

  def process_signup
    service = Whatsapp::EmbeddedSignupService.new(
      {
        account: Current.account,
        code: params[:code],
        business_id: params[:business_id],
        waba_id: params[:waba_id],
        phone_number_id: params[:phone_number_id]
      }
    )

    service.perform
  end

  def process_reauthorization
    service = Whatsapp::EmbeddedSignupService.new(
      {
        account: Current.account,
        code: params[:code],
        business_id: params[:business_id],
        waba_id: params[:waba_id],
        phone_number_id: params[:phone_number_id],
        inbox_id: params[:inbox_id]
      }
    )

    service.perform_reauthorization
  end

  def handle_signup_error(error)
    Rails.logger.error("WhatsApp embedded signup processing error: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))
    render json: {
      error: 'Internal server error',
      message: error.message
    }, status: :internal_server_error
  end

  def check_authorization
    authorize(Current.account, :update?)
  end
end
