class Webhooks::XController < ActionController::API
  before_action :verify_signature!, only: [:events]

  def verify
    crc_token = params[:crc_token]
    return head :bad_request if crc_token.blank?

    api_secret = GlobalConfigService.load('X_API_SECRET', '')
    return head :unauthorized if api_secret.blank?

    response_token = OpenSSL::HMAC.digest('SHA256', api_secret, crc_token)
    encoded_response = Base64.strict_encode64(response_token)

    render json: { response_token: "sha256=#{encoded_response}" }
  end

  def events
    event = JSON.parse(request_payload)
    ::Webhooks::XEventsJob.perform_later(event)

    head :ok
  end

  private

  def request_payload
    @request_payload ||= request.body.read
  end

  def verify_signature!
    signature_header = request.headers['X-Twitter-Webhooks-Signature']
    api_secret = GlobalConfigService.load('X_API_SECRET', nil)

    return head :unauthorized unless api_secret && signature_header

    received_signature = signature_header.sub('sha256=', '')
    computed_signature = OpenSSL::HMAC.digest('SHA256', api_secret, request_payload)
    encoded_computed = Base64.strict_encode64(computed_signature)

    return head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(encoded_computed, received_signature)
  end
end
