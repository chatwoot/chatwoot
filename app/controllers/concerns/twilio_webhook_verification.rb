module TwilioWebhookVerification
  private

  def verify_twilio_signature!(auth_token)
    head :forbidden unless valid_twilio_signature?(auth_token)
  end

  def valid_twilio_signature?(auth_token, url = request.original_url)
    validator = Twilio::Security::RequestValidator.new(auth_token)
    signature = request.headers['X-Twilio-Signature'].to_s
    validator.validate(url, request.request_parameters, signature)
  end
end
