# The HTTP side of the `uazapi` provider: one hosted instance, reached with the base URL
# and the instance token the operator pasted into the inbox form.
#
# Everything this class knows about the provider is transport: how to authenticate, what
# a failure means in canonical terms, and how long to wait. Which endpoints exist and
# what their answers mean belongs to the backend.
class Whatsapp::Session::Backends::Uazapi::Client
  # The instance token travels in a header of this name, which is also what the webhook
  # envelope echoes back. It is a credential: it must never reach a log line.
  TOKEN_HEADER = 'token'.freeze

  # Long enough for the provider to reach WhatsApp and come back, short enough that a
  # provider that is simply gone does not hold a Sidekiq thread. Uploads get their own
  # ceiling: `/send/media` fetches the file from us before it answers.
  TIMEOUT = 20
  UPLOAD_TIMEOUT = 60
  OPEN_TIMEOUT = 5

  # `Net::HTTP` retries an idempotent request once by default, so every ceiling above
  # buys half of what it reads as: measured here, a GET at `read_timeout: 3` against a
  # socket that accepts and never answers took 6.0s, and 3.0s with this. The `get`s are
  # the status reads, one of which runs inside the pairing poll, so the doubling landed
  # on the loop that is already waiting.
  MAX_RETRIES = 0

  # HTTP status -> contract error code, resolved to a class at raise time by
  # `Errors.build`. Codes rather than classes on purpose: a frozen hash of class objects
  # keeps the ones from before the last reload, and a `rescue` in a caller that did
  # reload then fails to match its own error.
  STATUS_CODES = {
    400 => 'invalid_payload',
    401 => 'unauthorized',
    403 => 'unauthorized',
    404 => 'session_not_found',
    # The build we captured answers 405 on endpoints its own docs describe
    # (`/instance/logout`, `/group/invitelink`). That is a capability this instance does
    # not have rather than a bad request, and the difference decides whether the caller
    # gives up or keeps retrying.
    405 => 'unsupported',
    413 => 'media_too_large',
    415 => 'media_too_large',
    429 => 'rate_limited'
  }.freeze

  # Connection-level failures. All of them mean the same thing to a caller: nobody
  # answered, so ask again later.
  #
  # The list is long on purpose. Anything left out escapes as itself, and a caller that
  # rescues this layer's own errors (the pairing poll, the outbound sender) would let it
  # through and leave an inbox showing state that stopped being true. A peer that closes
  # before answering raises EOFError, a route that is gone raises ENETUNREACH, and neither
  # is an HTTParty::Error.
  TRANSPORT_ERRORS = [
    Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout, Net::HTTPBadResponse, Net::ProtocolError,
    Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ECONNABORTED, Errno::EHOSTUNREACH, Errno::ENETUNREACH,
    Errno::ETIMEDOUT, Errno::EPIPE, EOFError, IOError, SocketError, OpenSSL::SSL::SSLError,
    HTTParty::Error, SsrfFilter::UnresolvedHostname, SsrfFilter::TooManyRedirects
  ].freeze

  attr_reader :base_url, :token

  def initialize(base_url:, token:)
    @base_url = base_url.to_s.chomp('/')
    @token = token.to_s
    raise Whatsapp::Session::Errors::InvalidConfig, 'uazapi inbox has no base url or token' if @base_url.blank? || @token.blank?
  end

  def get(path, query = {})
    request(:get, path, query: query.compact)
  end

  def post(path, body = {}, timeout: TIMEOUT)
    request(:post, path, body: body.compact, timeout: timeout)
  end

  private

  def request(method, path, query: nil, body: nil, timeout: TIMEOUT)
    payload = body.to_json if body.present?
    status, answer = if SafeFetch.allow_private_network?
                       direct(method, path, query, payload, timeout)
                     else
                       filtered(method, path, query, payload, timeout)
                     end
    parse(status, answer, path)
  rescue *TRANSPORT_ERRORS => e
    # The class name, never the message: an error raised over a URL is free to quote it,
    # and a quoted URL is one query string away from carrying the token.
    raise Whatsapp::Session::Errors::ProviderUnavailable, "uazapi #{path} did not answer (#{e.class})"
  rescue SsrfFilter::Error => e
    # The address this inbox is pointed at is inside the deployment, or is not an address
    # at all. Not retryable and not the provider's fault: somebody has to change the
    # inbox, so it is reported as the configuration error it is.
    raise Whatsapp::Session::Errors::InvalidConfig, "uazapi #{path} is not an address this deployment will call (#{e.class})"
  end

  # The ordinary path. Every address is resolved here and refused unless it is public: the
  # base URL is typed by whoever administers the account, and this method sends that
  # account's credentials to it and hands the answer back to the dashboard. A validation
  # on the literal address cannot cover a name that resolves inward, and it cannot cover a
  # redirect at all, so the filtering belongs at the moment of the call.
  #
  # The token is named as sensitive, which is what keeps a redirect to another origin from
  # carrying it there.
  #
  # All three timeouts: an endpoint that accepts the connection and then stops reading a
  # large body (a group photo travels as base64) would otherwise hold a worker for
  # Net::HTTP's own write default, well past the ceiling this class advertises.
  def filtered(method, path, query, payload, timeout)
    options = { open_timeout: OPEN_TIMEOUT, read_timeout: timeout, write_timeout: timeout, max_retries: MAX_RETRIES }
    response = SsrfFilter.public_send(method, url(path), headers: headers, body: payload, params: query.presence,
                                                         sensitive_headers: [TOKEN_HEADER], http_options: options)
    [response.code.to_i, response.body]
  end

  # An operator who has opened the private network is running the instance next to
  # Chatwoot, which is the one case the filter above cannot be asked about: it has no way
  # to be told that this particular private address is the intended one.
  #
  # `open_timeout` on its own key because HTTParty's `timeout` sets all three, and a
  # blackholed instance would otherwise hold a worker for the whole read budget, which on
  # a media send is a minute, before the connection even failed.
  #
  # `no_follow` because this library carries every header it was given across a redirect,
  # the instance token among them, so a 3xx to another host would hand that credential to
  # whoever answers there. There is no redirect on this API worth following: one is either
  # a misconfiguration or somebody standing in front of it, and both read better as the
  # provider being unreachable.
  def direct(method, path, query, payload, timeout)
    options = { headers: headers, timeout: timeout, open_timeout: OPEN_TIMEOUT, no_follow: true, max_retries: MAX_RETRIES }
    options[:query] = query if query.present?
    options[:body] = payload if payload.present?
    response = HTTParty.public_send(method, url(path), **options)
    [response.code, response.body]
  end

  def url(path)
    "#{base_url}#{path}"
  end

  def headers
    { TOKEN_HEADER => token, 'Content-Type' => 'application/json' }
  end

  # Parsed here rather than left to the client library: the answer is always JSON, and a
  # gateway that drops the content type would otherwise hand a caller a String where the
  # shape it was written against is a Hash. nil for an empty 200, an Array for the
  # endpoints that answer a list; handed back as it came, since the backend is what knows
  # the shape of each answer.
  def parse(status, answer, path)
    body = answer.presence && JSON.parse(answer)
    return body if status.between?(200, 299)

    raise Whatsapp::Session::Errors.build(code_for(status), "uazapi #{path} answered #{status}#{detail(body)}")
  rescue JSON::ParserError
    # A gateway in front of the provider answering with an HTML page, which is what a
    # 502 looks like from most hosts. It is the provider being unreachable, and it must
    # leave this class as one of ours like every other failure does.
    raise Whatsapp::Session::Errors::ProviderUnavailable, "uazapi #{path} answered #{status} with a body that is not json"
  end

  # 5xx is the provider being unwell, which is worth another attempt; an unmapped 4xx is
  # this request being wrong, which is not, and the difference is what decides whether an
  # outbound message is retried or marked failed in front of the agent.
  def code_for(status)
    STATUS_CODES[status] || (status >= 500 ? 'wa_error' : 'invalid_payload')
  end

  # The provider's own words, when it sends any, and only that field. The rest of an error
  # body is echoed request data, and on `/send/*` that includes the file we just uploaded.
  #
  # Two keys, because this provider uses two and the one it uses for failures was the one
  # not being read: `error` carries the refusal ("the number ... is not on WhatsApp",
  # "Description cannot be empty"), and `message` carries prose that is usually a report
  # rather than a complaint. Reading only `message` left the operator with the bare status
  # and no reason, on exactly the answers that had one.
  ERROR_KEYS = %w[error message].freeze

  def detail(body)
    return unless body.is_a?(Hash)

    said = ERROR_KEYS.filter_map { |key| body[key] }.find { |value| value.is_a?(String) && value.present? }
    ": #{said}" if said
  end
end
