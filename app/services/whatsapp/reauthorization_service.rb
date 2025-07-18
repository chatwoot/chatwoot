class Whatsapp::ReauthorizationService
  include Whatsapp::Concerns::ReauthorizationWorkflow
  include Whatsapp::Concerns::ChannelConfigUpdater
  include Whatsapp::Concerns::ServiceResponseHandler

  attr_reader :inbox, :code, :business_id, :waba_id, :phone_number_id

  def initialize(inbox:, code:, business_id:, waba_id:, phone_number_id:)
    @inbox = inbox
    @code = code
    @business_id = business_id
    @waba_id = waba_id
    @phone_number_id = phone_number_id
  end

  def perform
    return execute_reauthorization_workflow if whatsapp_cloud_channel?

    error_response(I18n.t('errors.whatsapp.reauthorization.not_supported'))
  end

  private

  def whatsapp_cloud_channel?
    channel.provider == 'whatsapp_cloud'
  end

  def embedded_signup_channel?
    channel.provider == 'whatsapp_cloud' && channel.provider_config['source'] == 'embedded_signup'
  end

  def exchange_code_for_token
    service = Whatsapp::TokenExchangeService.new(code: code)
    response = service.perform

    handle_service_response(
      response,
      success_key: :access_token,
      error_message: I18n.t('errors.whatsapp.token_exchange_failed')
    )
  end

  def validate_token_access(access_token)
    service = Whatsapp::TokenValidationService.new(
      access_token: access_token,
      waba_id: waba_id
    )
    response = service.perform

    handle_service_response(
      response,
      success_key: :valid,
      error_message: I18n.t('errors.whatsapp.invalid_token_permissions')
    )
  end

  def fetch_phone_info(access_token)
    service = Whatsapp::PhoneInfoService.new(
      access_token: access_token,
      phone_number_id: phone_number_id
    )
    response = service.perform

    handle_service_response(
      response,
      success_key: :phone_number,
      success_data: { phone_info: response },
      error_message: I18n.t('errors.whatsapp.phone_info_fetch_failed')
    )
  end

  def setup_webhooks(access_token)
    return unless channel.provider == 'whatsapp_cloud'

    Whatsapp::WebhookSetupService.new(channel, business_id, access_token).perform
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_REAUTH] Webhook setup failed: #{e.message}"
    # Don't fail the reauthorization if webhook setup fails
  end

  def channel
    @channel ||= inbox.channel
  end
end
