require 'uri'

class DataImports::Freshdesk::Client
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

  Page = Struct.new(:data, :next_page, keyword_init: true)

  DEFAULT_PER_PAGE = 100
  MAX_TICKET_PAGES = 300
  EARLIEST_TICKET_TIMESTAMP = '1970-01-01T00:00:00Z'.freeze
  FRESHDESK_DOMAIN_REGEX = /\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.freshdesk\.com\z/i

  attr_reader :domain

  def self.normalize_domain(value)
    candidate = value.to_s.strip.downcase
    candidate = "#{candidate}.freshdesk.com" unless candidate.include?('.')
    candidate = URI.parse(candidate).host if candidate.start_with?('http://', 'https://')
    raise ArgumentError, 'Enter a valid Freshdesk domain, such as acme.freshdesk.com.' unless candidate&.match?(FRESHDESK_DOMAIN_REGEX)

    candidate
  rescue URI::InvalidURIError
    raise ArgumentError, 'Enter a valid Freshdesk domain, such as acme.freshdesk.com.'
  end

  def initialize(domain:, api_key:)
    @domain = self.class.normalize_domain(domain)
    @api_key = api_key.to_s.strip
  end

  def list_contacts(page: 1, per_page: DEFAULT_PER_PAGE)
    get_page('/contacts', query: { page: page, per_page: per_page })
  end

  def retrieve_contact(id)
    get("/contacts/#{id}")
  end

  def list_tickets(page: 1, per_page: DEFAULT_PER_PAGE)
    get_page(
      '/tickets',
      query: {
        page: page,
        per_page: per_page,
        updated_since: EARLIEST_TICKET_TIMESTAMP
      }
    )
  end

  def retrieve_ticket(id)
    get("/tickets/#{id}", query: { include: 'requester' })
  end

  def list_conversations(ticket_id, page: 1, per_page: DEFAULT_PER_PAGE)
    get_page("/tickets/#{ticket_id}/conversations", query: { page: page, per_page: per_page })
  end

  private

  def get_page(path, query: {})
    response = request(path, query: query)
    Page.new(
      data: parsed_body(response),
      next_page: next_page(response.headers['link'], current_page: query[:page] || query['page'])
    )
  end

  def get(path, query: {})
    parsed_body(request(path, query: query))
  end

  def request(path, query: {})
    response =
      begin
        HTTParty.get(
          "https://#{@domain}/api/v2#{path}",
          query: query,
          basic_auth: { username: @api_key, password: 'X' },
          headers: { 'Accept' => 'application/json', 'Content-Type' => 'application/json' },
          timeout: 30
        )
      rescue StandardError => e
        raise Error.new(
          "Freshdesk API request failed before receiving a response: #{e.message}",
          body: { transport_error_class: e.class.name }
        )
      end

    parse_response(response)
    response
  end

  def parse_response(response)
    return if response.success?

    body = parsed_body(response)
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
    response.parsed_response.presence || (response.code == 204 ? {} : [])
  rescue JSON::ParserError
    {}
  end

  def error_message(body, response)
    description = body['description'] if body.is_a?(Hash)
    errors = body['errors'] if body.is_a?(Hash)
    first_error = errors.first if errors.is_a?(Array)
    first_error_message = first_error['message'] if first_error.is_a?(Hash)
    first_error_message.presence || description.presence || "Freshdesk API request failed with status #{response.code}"
  end

  def next_page(link_header, current_page:)
    next_link = link_header.to_s.split(',').find { |link| link.include?('rel="next"') }
    return if next_link.blank?

    url = next_link[/<([^>]+)>/, 1]
    return if url.blank?

    parse_next_page(url, current_page)
  rescue ArgumentError, URI::InvalidURIError
    nil
  end

  def parse_next_page(url, current_page)
    uri = URI.parse(url)
    page = URI.decode_www_form(uri.query.to_s).to_h['page']
    same_domain = uri.host.blank? || uri.host.casecmp?(@domain)
    positive_page = page&.match?(/\A[1-9]\d*\z/)
    page.to_i if same_domain && positive_page && page.to_i > current_page.to_i
  end
end
