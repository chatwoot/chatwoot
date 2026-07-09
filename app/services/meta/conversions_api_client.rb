# Thin HTTP client for Meta's Conversions API for Business Messaging (CAPI-BM).
#
# POST /{API_VERSION}/{DATASET_ID}/events — action_source "business_messaging".
# This is NOT the classic Pixel /{pixel_id}/events endpoint; the attribution key is
# the ctwa_clid carried inside each event's user_data (see PayloadBuilder), not an
# event_id (Meta does not dedup CAPI-BM events server-side).
#
# The access token is a Meta secret: it travels only in the Authorization header (never
# the query string, which leaks through access logs/proxies/referrers) and is NEVER
# returned or logged. Every string that leaves this client (body/error) is scrubbed of
# token-shaped substrings before it can reach a log or exception.
class Meta::ConversionsApiClient
  BASE_URI = 'https://graph.facebook.com'.freeze
  # Pin the current stable Graph version (never v16.0). Reuses the same knob the
  # WhatsApp Cloud client reads, so the whole Meta surface moves versions together.
  DEFAULT_API_VERSION = 'v22.0'.freeze
  DEFAULT_TIMEOUT_SECONDS = 8
  # Any run of 20+ non-space chars is treated as a possible secret and redacted. Broad
  # on purpose: Meta tokens can carry -, _, |, +, /, = so a [A-Za-z0-9] class misses them.
  SENSITIVE_PATTERN = %r{[A-Za-z0-9_\-|+/=.]{20,}}

  Result = Struct.new(:ok, :http_code, :body, :error, keyword_init: true)

  def initialize(access_token:, dataset_id:, api_version: nil)
    @access_token = access_token
    @dataset_id = dataset_id
    @api_version = api_version.presence || GlobalConfigService.load('WHATSAPP_API_VERSION', DEFAULT_API_VERSION)
  end

  # events: an array of CAPI-BM event hashes (see Crm::MetaCapi::PayloadBuilder#build).
  def post_events(events)
    response = HTTParty.post(
      "#{BASE_URI}/#{@api_version}/#{@dataset_id}/events",
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{@access_token}"
      },
      body: { data: Array(events) }.to_json,
      timeout: DEFAULT_TIMEOUT_SECONDS
    )

    body = sanitize(response.body)
    Result.new(ok: response.success?, http_code: response.code, body: body, error: response.success? ? nil : body)
  rescue StandardError => e
    Result.new(ok: false, http_code: nil, body: nil, error: sanitize(e.message))
  end

  private

  def sanitize(text)
    return if text.nil?

    text.to_s.gsub(SENSITIVE_PATTERN, '<REDACTED>')
  end
end
