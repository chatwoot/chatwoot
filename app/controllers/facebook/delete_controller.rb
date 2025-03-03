class Facebook::DeleteController < ApplicationController
  class InvalidDigestError < StandardError; end

  def create
    signed_request = params['signed_request']
    payload = parse_fb_signed_request(signed_request)
    id_to_process = payload['user_id']

    mark_processing(id_to_process)
    Webhooks::FacebookDeleteJob.perform_later(id_to_process)
    status_url = "#{app_url_base}/facebook/confirm/#{id_to_process}"

    render json: { status_url: status_url, code: id_to_process }, status: :ok
  rescue InvalidDigestError
    render json: { error: 'Invalid signature' }, status: :unprocessable_entity
  end

  private

  def mark_processing(id_to_process)
    # we use this key to check if the deletion is completed or not
    # Once the key is gone, we know the deletion is completed
    # And we can show as such
    key = format(::Redis::Alfred::META_DELETE_PROCESSING, id: id_to_process)
    ::Redis::Alfred.set(key, true)
  end

  def app_url_base
    ENV.fetch('FRONTEND_URL', nil)
  end

  def parse_fb_signed_request(signed_request)
    encoded_signature, payload = signed_request.split('.', 2)

    decoded_signature = Base64.urlsafe_decode64(encoded_signature)
    decoded_payload = JSON.parse(Base64.urlsafe_decode64(payload))

    expected_signature = OpenSSL::HMAC.digest('sha256', app_secret, payload)

    raise InvalidDigestError if decoded_signature != expected_signature

    decoded_payload
  end

  def app_secret
    GlobalConfigService.load('FB_APP_SECRET', '')
  end
end
