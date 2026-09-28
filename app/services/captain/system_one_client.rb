class Captain::SystemOneClient
  MODEL = 'jev-latest'.freeze
  SYSTEM_ONE_PATH = '/v1/systemone'.freeze
  REQUEST_TIMEOUT = 15

  class Error < StandardError; end

  def ask(state:, questions:)
    response = HTTParty.post(
      "#{GlobalConfigService.load('CAPTAIN_OPENROUTER_DECISION_MODEL_ENDPOINT', nil)}#{SYSTEM_ONE_PATH}",
      headers: {
        'Authorization' => "Bearer #{GlobalConfigService.load('CAPTAIN_OPENROUTER_API_KEY', nil)}",
        'Content-Type' => 'application/json'
      },
      body: { model: MODEL, state: state, questions: questions }.to_json,
      timeout: REQUEST_TIMEOUT
    )
    raise Error, "Jev request failed with status #{response.code}: #{response.body}" unless response.success?

    answers_from(response)
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError => e
    raise Error, "Jev request failed (#{e.class.name})"
  end

  private

  def answers_from(response)
    body = response.parsed_response
    answers = body['answers'] if body.is_a?(Hash)
    raise Error, 'Jev returned an invalid response' unless answers.is_a?(Hash)

    answers
  rescue JSON::ParserError
    raise Error, 'Jev returned an invalid response'
  end
end
