# Releases an embedded signup number from the WhatsApp Cloud API when an admin deletes its inbox and asks for it.
# It is opt-in because deregistration is number-wide: it also stops any other partner or the customer's own integration
# from using the number.
class Whatsapp::PhoneNumberReleaseService
  def initialize(channel)
    @channel = channel
  end

  def perform
    raise CustomExceptions::WhatsappNumberReleaseError, { reason: 'unsupported' } unless embedded_signup_cloud_channel?
    # Meta does not allow deregistering a number that also uses the WhatsApp Business app.
    raise CustomExceptions::WhatsappNumberReleaseError, { reason: 'business_app' } unless confirmed_not_on_business_app?

    deregister
  end

  private

  def embedded_signup_cloud_channel?
    @channel.is_a?(Channel::Whatsapp) &&
      @channel.provider == 'whatsapp_cloud' &&
      @channel.provider_config['source'] == 'embedded_signup'
  end

  def confirmed_not_on_business_app?
    Whatsapp::HealthService.new(@channel).fetch_health_status[:is_on_biz_app] == false
  rescue StandardError
    false
  end

  def deregister
    Whatsapp::FacebookApiClient.new(@channel.provider_config['api_key']).deregister_phone_number(@channel.provider_config['phone_number_id'])
    Rails.logger.info "[WHATSAPP] Phone number released from Cloud API for channel #{@channel.id}"
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Phone number release failed for channel #{@channel.id}: #{e.message}"
    raise CustomExceptions::WhatsappNumberReleaseError, { reason: 'failed' }
  end
end
