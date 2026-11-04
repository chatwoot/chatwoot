class Api::V1::Accounts::Whatsapp::ManualSetupController < Api::V1::Accounts::BaseController
  before_action :authorize_create, only: [:preview, :connect]
  before_action :fetch_inbox, only: [:webhook_status, :setup_webhook]

  def preview
    render json: validation_service.perform
  rescue StandardError => e
    render_setup_error(e)
  end

  def connect
    setup = Whatsapp::ManualSetupService.new(account: Current.account, **connect_params.to_h.symbolize_keys).perform
    render json: connection_response(setup), status: :created
  rescue CustomExceptions::Inbox::LimitExceeded => e
    render_error_response(e)
  rescue StandardError => e
    render_setup_error(e)
  end

  def webhook_status
    render json: Whatsapp::ManualWebhookStatusService.new(@inbox.channel).perform
  rescue StandardError => e
    render_setup_error(e)
  end

  def setup_webhook
    channel = @inbox.channel
    webhook_setup = Whatsapp::WebhookSetupService.new(channel)
    webhook_setup.perform
    raise webhook_setup.registration_error if webhook_setup.registration_error

    render json: Whatsapp::ManualWebhookStatusService.new(channel.reload).perform
  rescue StandardError => e
    render_setup_error(e)
  end

  private

  def authorize_create
    authorize ::Inbox, :create?
  end

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :update?
    channel = @inbox.channel
    return if channel.is_a?(Channel::Whatsapp) && channel.provider_config['source'] == 'manual_setup_v2'

    raise ActiveRecord::RecordNotFound
  end

  def validation_service
    Whatsapp::ManualSetupValidationService.new(**connection_params.to_h.symbolize_keys)
  end

  def connection_params
    params.permit(:waba_id, :phone_number_id, :access_token)
  end

  def connect_params
    params.permit(:waba_id, :phone_number_id, :access_token, :inbox_name)
  end

  def connection_response(setup)
    channel = setup.channel.reload
    {
      id: channel.inbox.id,
      name: channel.inbox.name,
      number_access: true,
      template_access: true,
      webhook_setup: setup.webhook_setup?,
      webhook_error: setup.webhook_error
    }
  end

  def render_setup_error(error)
    Rails.logger.error "[WHATSAPP MANUAL SETUP] account_id=#{Current.account.id} error=#{error.class}: #{error.message}"
    render json: { message: error.message }, status: :unprocessable_entity
  end
end
