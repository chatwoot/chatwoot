class SurveyCallService
  include HTTParty

  def initialize(contact:, survey:)
    @contact = contact
    @survey = survey
    @webhook_url = ENV.fetch('SURVEY_CALL_WEBHOOK_URL', nil)
  end

  def perform
    raise ConfigurationError, 'Survey call webhook URL not configured' if @webhook_url.blank?
    raise ValidationError, 'Contact must have a valid phone number' unless valid_phone_number?

    make_request
  end

  private

  def valid_phone_number?
    return false if @contact.phone_number.blank?

    # Validate E.164 format: +[1-9]\d{1,14}
    @contact.phone_number.match?(/\A\+[1-9]\d{1,14}\z/)
  end

  def make_request
    response = HTTParty.post(
      @webhook_url,
      body: payload.to_json,
      headers: {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      },
      timeout: 30
    )

    handle_response(response)
  rescue HTTParty::Error, Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.error("Survey call request failed: #{e.message}")
    raise RequestError, "Failed to initiate survey call: #{e.message}"
  end

  def payload
    {
      customer_phone: @contact.phone_number,
      surveyId: @survey.id,
      accountId: @contact.account_id,
      contactId: @contact.id
    }
  end

  def handle_response(response)
    case response.code
    when 200..299
      { success: true, message: 'Survey call initiated successfully' }
    when 400..499
      Rails.logger.error("Survey call client error: #{response.code} - #{response.body}")
      raise RequestError, "Survey call request failed: #{response.body}"
    when 500..599
      Rails.logger.error("Survey call server error: #{response.code} - #{response.body}")
      raise RequestError, 'Survey call service temporarily unavailable'
    else
      Rails.logger.error("Survey call unexpected response: #{response.code}")
      raise RequestError, 'Unexpected response from survey call service'
    end
  end

  # Custom exceptions
  class ConfigurationError < StandardError; end
  class ValidationError < StandardError; end
  class RequestError < StandardError; end
end
