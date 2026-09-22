class Crm::Cpfcnpj::Api::BaseClient
  include HTTParty

  base_uri 'https://api.cpfcnpj.com.br'

  # The public documentation recommends waiting up to 60 seconds for a lookup.
  TIMEOUT_SECONDS = 60
  default_timeout TIMEOUT_SECONDS

  class ApiError < StandardError
    attr_reader :code, :response

    def initialize(message = nil, code: nil, response: nil)
      @code = code
      @response = response
      super(message)
    end
  end

  def initialize(token:)
    @token = token
  end

  # Builds the public path /{token}/{package}/{document} and returns the parsed
  # body on success. See https://www.cpfcnpj.com.br/dev/ for the contract.
  def lookup(document, package)
    response = self.class.get("/#{@token}/#{package}/#{document}")
    handle_response(response, document)
  end

  private

  def handle_response(response, document)
    body = parsed_body(response)
    return body if success?(response, body)

    raise ApiError.new(
      error_message(body, response, document),
      code: error_code(body, response),
      response: response
    )
  end

  def success?(response, body)
    response.code.between?(200, 299) && body.is_a?(Hash) && body['status'] == 1
  end

  def parsed_body(response)
    response.parsed_response
  rescue StandardError
    nil
  end

  # Never interpolates the token or the full document. The document is masked to
  # its last four characters so logs and error trackers stay free of PII.
  def error_message(body, response, document)
    reason = error_reason(body) || "HTTP #{response.code}"
    code = body.is_a?(Hash) ? body['erroCodigo'] : nil
    suffix = code ? " (erroCodigo #{code})" : ''
    "CPF.CNPJ API error for document #{masked(document)}: #{reason}#{suffix}"
  end

  def error_reason(body)
    return nil unless body.is_a?(Hash)

    body['erro'].presence || body['message'].presence
  end

  def error_code(body, response)
    return response.code unless body.is_a?(Hash)

    body['erroCodigo'] || body['code'] || response.code
  end

  def masked(document)
    value = document.to_s
    return '****' if value.length <= 4

    "****#{value[-4..]}"
  end
end
