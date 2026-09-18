class DataImports::Intercom::Client
  class Error < StandardError
    attr_reader :status, :body

    def initialize(message, status: nil, body: nil)
      super(message)
      @status = status
      @body = body
    end
  end

  class AuthenticationError < Error; end

  class RateLimitError < Error
    attr_reader :retry_after

    def initialize(message, retry_after: nil, **)
      super(message, **)
      @retry_after = retry_after
    end
  end

  BASE_URL = 'https://api.intercom.io'.freeze
  API_VERSION = '2.15'.freeze
  DEFAULT_PER_PAGE = 50

  def initialize(access_token:)
    @access_token = access_token
  end

  def list_contacts(starting_after: nil, per_page: DEFAULT_PER_PAGE)
    get('/contacts', query: pagination_query(starting_after, per_page))
  end

  def list_conversations(starting_after: nil, per_page: DEFAULT_PER_PAGE)
    get('/conversations', query: pagination_query(starting_after, per_page))
  end

  def retrieve_conversation(id)
    get("/conversations/#{id}")
  end

  def retrieve_contact(id)
    get("/contacts/#{id}")
  end

  private

  def pagination_query(starting_after, per_page)
    { per_page: per_page, starting_after: starting_after }.compact
  end

  def get(path, query: {})
    response =
      begin
        HTTParty.get(
          "#{BASE_URL}#{path}",
          query: query,
          headers: headers,
          timeout: 30
        )
      rescue StandardError => e
        raise Error.new(
          "Intercom API request failed before receiving a response: #{e.message}",
          body: { transport_error_class: e.class.name }
        )
      end

    parse_response(response)
  end

  def headers
    {
      'Authorization' => "Bearer #{@access_token}",
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
      'Intercom-Version' => API_VERSION
    }
  end

  def parse_response(response)
    body = parsed_body(response)
    return body if response.success?

    message = error_message(body, response)
    case response.code
    when 401, 403
      raise AuthenticationError.new(message, status: response.code, body: body)
    when 429
      raise RateLimitError.new(message, status: response.code, body: body, retry_after: response.headers['retry-after'])
    else
      raise Error.new(message, status: response.code, body: body)
    end
  end

  def parsed_body(response)
    response.parsed_response.presence || {}
  rescue JSON::ParserError
    {}
  end

  def error_message(body, response)
    errors = body.is_a?(Hash) ? body['errors'] : nil
    first_error = errors.is_a?(Array) ? errors.first : nil
    first_error&.dig('message').presence || "Intercom API request failed with status #{response.code}"
  end
end
