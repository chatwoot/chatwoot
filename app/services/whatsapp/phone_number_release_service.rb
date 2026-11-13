# Releases an embedded signup number from the WhatsApp Cloud API when an admin deletes its inbox and asks for it,
# usually to move the number back to the WhatsApp Business app. It is opt-in because deregistration is number-wide:
# it also stops any other partner or the customer's own integration from using the number.
class Whatsapp::PhoneNumberReleaseService
  def initialize(channel)
    @channel = channel
  end

  def perform
    raise CustomExceptions::WhatsappNumberReleaseError, { reason: 'unsupported' } unless embedded_signup_cloud_channel?

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
end
