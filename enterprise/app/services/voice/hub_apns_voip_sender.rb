# Sends APNs VoIP pushes through the Chatwoot Hub, which holds the app's Apple key, for
# installations without one of their own. The installation details and relay token sent with
# the request are read when the sender is made, so its delivery makes HTTP requests only.
class Voice::HubApnsVoipSender
  OUTCOMES = { 200 => :sent, 410 => :gone }.freeze

  # Tokens sent to the hub in one request
  BATCH_SIZE = 20

  def initialize(call_id:, relay_token:)
    @call_id = call_id
    @relay_token = relay_token
    @instance_info = ChatwootHub.instance_config
  end

  # Returns each token's outcome from the status APNs gave the hub: :sent, :gone when Apple
  # no longer knows the token, or :failed. A request the hub refuses fails its tokens.
  # `proceed` is asked on the calling thread before each batch after the first; once it
  # returns false the remaining tokens are not sent and have no outcome.
  def ring(tokens, payload, proceed: -> { true })
    tokens.each_slice(BATCH_SIZE).with_index.each_with_object({}) do |(batch, index), outcomes|
      break outcomes if index.positive? && !proceed.call

      outcomes.merge!(deliver_batch(batch, payload))
    end
  end

  private

  def deliver_batch(tokens, payload)
    response = ChatwootHub.send_voip_push(tokens, payload, relay_token: @relay_token, instance_info: @instance_info)
    results = JSON.parse(response.body).fetch('results', {})
    tokens.index_with { |token| outcome(token, results[token] || {}) }
  rescue StandardError => e
    Rails.logger.error("[VOIP PUSH] apple ring call #{@call_id} via hub failed: #{e.class}: #{e.message}")
    tokens.index_with(:failed)
  end

  def outcome(token, result)
    Rails.logger.info("[VOIP PUSH] apple ring call #{@call_id} to #{token[0, 8]}… via hub status=#{result['status']} #{result['reason']}")
    OUTCOMES.fetch(result['status'], :failed)
  end
end
