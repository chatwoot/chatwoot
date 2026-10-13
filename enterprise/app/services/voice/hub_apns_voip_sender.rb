# Sends APNs VoIP pushes through the Chatwoot Hub, which holds the app's Apple key, for
# installations without one of their own. The installation details and relay token sent with
# the request are read when the sender is made, so its delivery makes HTTP requests only.
class Voice::HubApnsVoipSender
  OUTCOMES = { 200 => :sent, 410 => :gone }.freeze

  def initialize(call_id:, relay_token:)
    @call_id = call_id
    @relay_token = relay_token
    @instance_info = ChatwootHub.instance_config
  end

  # Returns each token's outcome from the status APNs gave the hub: :sent, :gone when Apple
  # no longer knows the token, or :failed. A request the hub refuses fails every token.
  def ring(tokens, payload)
    return {} if tokens.empty?

    response = ChatwootHub.send_voip_push(tokens, payload, relay_token: @relay_token, instance_info: @instance_info)
    results = JSON.parse(response.body).fetch('results', {})
    tokens.index_with { |token| outcome(token, results[token] || {}) }
  rescue StandardError => e
    Rails.logger.error("[VOIP PUSH] apple ring call #{@call_id} via hub failed: #{e.class}: #{e.message}")
    tokens.index_with(:failed)
  end

  private

  def outcome(token, result)
    Rails.logger.info("[VOIP PUSH] apple ring call #{@call_id} to #{token[0, 8]}… via hub status=#{result['status']} #{result['reason']}")
    OUTCOMES.fetch(result['status'], :failed)
  end
end
