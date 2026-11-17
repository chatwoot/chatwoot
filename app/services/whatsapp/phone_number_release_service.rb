# Releases an embedded signup number from the WhatsApp Cloud API when an admin deletes its inbox and asks for it.
# It is opt-in because deregistration is number-wide: it also stops any other partner or the customer's own integration
# from using the number.
class Whatsapp::PhoneNumberReleaseService
  def initialize(channel)
    @channel = channel
  end

  def perform
    raise CustomExceptions::WhatsappNumberReleaseError, { reason: 'unsupported' } unless embedded_signup_cloud_channel?

    ensure_not_on_business_app!
    Whatsapp::FacebookApiClient.new(@channel.provider_config['api_key']).deregister_phone_number(@channel.provider_config['phone_number_id'])
    Rails.logger.info "[WHATSAPP] Phone number released from Cloud API for channel #{@channel.id}"
  rescue Whatsapp::FacebookApiClient::ApiError => e
    raise CustomExceptions::WhatsappNumberReleaseError, { reason: 'failed', meta_message: e.meta_message }
  end

  private

  def embedded_signup_cloud_channel?
    @channel.is_a?(Channel::Whatsapp) &&
      @channel.provider == 'whatsapp_cloud' &&
      @channel.provider_config['source'] == 'embedded_signup'
  end

  # Meta does not allow deregistering a number that also uses the WhatsApp Business app; the business disconnects it
  # in the app instead. So the number is released only when Meta confirms it is not on the app.
  def ensure_not_on_business_app!
    case business_app_status
    when false then nil
    when true then raise CustomExceptions::WhatsappNumberReleaseError, { reason: 'business_app' }
    else raise CustomExceptions::WhatsappNumberReleaseError, { reason: 'business_app_unknown' }
    end
  end

  def business_app_status
    Whatsapp::HealthService.new(@channel).fetch_health_status&.dig(:is_on_biz_app)
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Could not check the Business app status for channel #{@channel.id}: #{e.message}"
    nil
  end
end
