# Creates a Vapi call whose audio comes from our own Twilio call (Vapi's "phone call provider bypass").
# Vapi answers with the TwiML that connects the Twilio call to it.
class Voice::Captain::VapiClient
  class Error < StandardError; end

  API_URL = 'https://api.vapi.ai/call'.freeze
  REQUEST_TIMEOUT_SECONDS = 5

  # Returns { id:, twiml: } for the new Vapi call
  def create_call(customer_number:, assistant:)
    response = HTTParty.post(API_URL, headers: headers, body: call_body(customer_number, assistant).to_json, timeout: REQUEST_TIMEOUT_SECONDS)
    raise Error, "Vapi call create failed: status=#{response.code} body=#{response.body}" unless response.success?

    twiml = response.parsed_response.dig('phoneCallProviderDetails', 'twiml')
    raise Error, 'Vapi call create returned no TwiML' if twiml.blank?

    { id: response.parsed_response.fetch('id'), twiml: twiml }
  end

  private

  def call_body(customer_number, assistant)
    {
      phoneNumberId: Voice::Captain::VapiConfig.phone_number_id,
      phoneCallProviderBypassEnabled: true,
      customer: { number: customer_number },
      assistant: assistant
    }
  end

  def headers
    {
      'Authorization' => "Bearer #{Voice::Captain::VapiConfig.api_key}",
      'Content-Type' => 'application/json'
    }
  end
end
