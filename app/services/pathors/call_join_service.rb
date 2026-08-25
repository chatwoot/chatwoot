# Relays a dashboard agent's "join call" click to the Pathors backend, which
# owns the LiveKit room the voice agent is already speaking in and hands back a
# participant token so the human can drop into the same room.
#
# Everything about the destination is derived from the Pathors agent bot behind
# the call's inbox: its `outgoing_url` carries both the backend origin and the
# project id, and its webhook secret keys the request signature. There is no
# extra config surface to keep in sync.
class Pathors::CallJoinService
  REQUEST_TIMEOUT = 10
  # Statuses the Pathors contract defines as meaningful to the browser; anything
  # else is an upstream malfunction and is collapsed into a 502.
  RELAYED_STATUSES = [200, 404, 409].freeze
  NETWORK_ERRORS = [
    HTTParty::Error, Net::OpenTimeout, Net::ReadTimeout, Timeout::Error,
    SocketError, OpenSSL::SSL::SSLError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, EOFError
  ].freeze

  Result = Struct.new(:status, :body, keyword_init: true) do
    def ok?
      status == 200
    end
  end

  def initialize(call:, user:)
    @call = call
    @user = user
  end

  def perform
    return misconfigured if endpoint.blank?

    relay(post_join)
  rescue *NETWORK_ERRORS => e
    Rails.logger.warn "[Pathors] join relay failed for call #{@call.id}: #{e.class} #{e.message}"
    Result.new(status: 502, body: { error: 'pathors_unreachable' })
  end

  private

  def post_join
    body = request_body
    HTTParty.post(
      endpoint,
      body: body,
      headers: {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'X-Pathors-Signature' => signature(body)
      },
      timeout: REQUEST_TIMEOUT
    )
  end

  # The signed payload is this exact string — sign the serialized body so the
  # bytes we hash are the bytes that go on the wire.
  def request_body
    {
      sessionId: @call.provider_call_id,
      conversationId: @call.conversation.display_id,
      agent: { id: @user.id, name: @user.available_name }
    }.to_json
  end

  def signature(body)
    "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', webhook_secret.to_s, body)}"
  end

  # AgentBot#secret is the webhook signing secret; a bot whose secret is blank
  # falls back to its access token — the same pair the Pathors side stores.
  def webhook_secret
    agent_bot&.secret.presence || agent_bot&.access_token&.token
  end

  def relay(response)
    code = response.code.to_i
    return Result.new(status: code, body: parsed(response)) if RELAYED_STATUSES.include?(code)
    # 401 means our signature was rejected — a server-side misconfiguration, not
    # something the agent clicking "join" can act on.
    return Result.new(status: 502, body: { error: 'pathors_auth_failed' }) if code == 401

    Rails.logger.warn "[Pathors] join relay got unexpected status #{code} for call #{@call.id}"
    Result.new(status: 502, body: { error: 'pathors_error' })
  end

  def parsed(response)
    body = response.parsed_response
    body.is_a?(Hash) ? body : {}
  rescue StandardError
    {}
  end

  def misconfigured
    Result.new(status: 422, body: { error: 'pathors_not_configured' })
  end

  # "https://api.pathors.com/project/42/integration/chatwoot/callback"
  #   -> "https://api.pathors.com/project/42/integration/chatwoot/voice/join"
  def endpoint
    return @endpoint if defined?(@endpoint)

    @endpoint = build_endpoint
  end

  def build_endpoint
    project_id = agent_bot&.pathors_project_id
    return nil if project_id.blank?

    "#{agent_bot.pathors_origin}/project/#{project_id}/integration/chatwoot/voice/join"
  end

  # An account can hold more than one Pathors bot — one per project — so the
  # account is too coarse a key to pick by: the wrong bot means the wrong
  # project id in the URL and the wrong secret on the signature, which the
  # backend answers with a 401. The inbox the call arrived on is bound to
  # exactly one bot, so that binding is the authoritative answer whenever it
  # points at Pathors. The account-wide scan stays as the fallback for inboxes
  # that were never bound (single-project installs, bots attached elsewhere).
  def agent_bot
    return @agent_bot if defined?(@agent_bot)

    fragment = Integrations::App::PATHORS_CALLBACK_URL_FRAGMENT
    inbox_bot = @call.inbox.agent_bot
    @agent_bot = if inbox_bot&.outgoing_url&.include?(fragment)
                   inbox_bot
                 else
                   @call.account.agent_bots.where('outgoing_url LIKE ?', "%#{fragment}%").order(:id).first
                 end
  end
end
