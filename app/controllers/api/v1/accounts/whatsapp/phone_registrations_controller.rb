class Api::V1::Accounts::Whatsapp::PhoneRegistrationsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :fetch_and_validate_inbox

  def create
    register_phone_and_setup_webhook
    render_success_response
  rescue StandardError => e
    render_error_response(e)
  end

  private

  def fetch_and_validate_inbox
    @inbox = Current.account.inboxes.find(permitted_params[:inbox_id])
    validate_whatsapp_channel
  end

  def validate_whatsapp_channel
    return if @inbox.channel_type == 'Channel::Whatsapp'

    render json: {
      success: false,
      message: 'Inbox must be a WhatsApp channel'
    }, status: :unprocessable_entity
  end

  def register_phone_and_setup_webhook
    channel = @inbox.channel
    service = Whatsapp::WebhookSetupService.new(
      channel,
      permitted_params[:waba_id],
      permitted_params[:access_token]
    )
    service.perform
  end

  def render_success_response
    render json: {
      success: true,
      message: 'Phone number registered and webhook setup completed successfully',
      inbox_id: @inbox.id,
      inbox_name: @inbox.name
    }
  end

  def render_error_response(error)
    Rails.logger.error "[WHATSAPP PHONE REGISTRATION] Error: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    render json: {
      success: false,
      error: error.message
    }, status: :unprocessable_entity
  end

  def permitted_params
    params.permit(:inbox_id, :waba_id, :access_token)
  end
end
