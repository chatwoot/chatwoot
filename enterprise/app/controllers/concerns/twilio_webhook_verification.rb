module Concerns::TwilioWebhookVerification
  private

  def verify_twilio_signature!(auth_token)
    validator = Twilio::Security::RequestValidator.new(auth_token)
    signature = request.headers['X-Twilio-Signature'].to_s
    return if validator.validate(request.original_url, request.request_parameters, signature)

    head :forbidden
  end
end
