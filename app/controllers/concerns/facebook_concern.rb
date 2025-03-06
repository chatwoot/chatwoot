module FacebookConcern
  extend ActiveSupport::Concern

  class InvalidDigestError < StandardError; end

  private

  def deletion_processed?(code)
    request = DeleteRequest.find_by!(confirmation_code: code)
    request.complete?
  rescue ActiveRecord::RecordNotFound
    false
  end

  def parse_fb_signed_request(signed_request)
    encoded_signature, payload = signed_request.split('.', 2)

    decoded_signature = Base64.urlsafe_decode64(encoded_signature)
    decoded_payload = JSON.parse(Base64.urlsafe_decode64(payload))

    expected_signature = OpenSSL::HMAC.digest('sha256', app_secret, payload)

    raise InvalidDigestError if decoded_signature != expected_signature

    decoded_payload
  end

  def app_url_base
    ENV.fetch('FRONTEND_URL', nil)
  end

  def app_secret
    GlobalConfigService.load('FB_APP_SECRET', '')
  end
end
