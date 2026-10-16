# Sends call pushes through the Chatwoot Hub voice relay, for installations the hub approved
# that have no push credentials of their own. The hub reaches only phones this installation
# registered with it (Voice::RelayDeviceSync) and builds the APNs or FCM message from the
# call's fields. Answers as Voice::ApnsVoipSender does for iPhones and Voice::FcmVoipSender
# for Android, with HTTP requests only, so it runs on a delivery thread.
class Voice::HubRelaySender
  OUTCOMES = { 'sent' => :sent, 'gone' => :gone }.freeze

  # Phones per request. The call is checked before each request, so a ring answered elsewhere
  # stops within one request.
  BATCH_SIZE = 5

  # The hub stops sending 15 seconds into a request
  READ_TIMEOUT_SECONDS = 20

  def initialize(platform:, call_id:, expiry_seconds:)
    @platform = platform
    @call_id = call_id
    @expires_at = Time.now.to_i + expiry_seconds
  end

  def ring(tokens, payload, proceed: -> { true }) = deliver(tokens, payload, 'ring', proceed: proceed)

  # Returns each token's outcome: :sent, :gone when the platform no longer knows it, or :failed,
  # which includes a phone the hub has not registered to this installation. `proceed` is asked on
  # the calling thread before each request; once it returns false the remaining tokens are not
  # sent and have no outcome.
  def deliver(tokens, payload, kind, proceed: -> { true })
    tokens.each_slice(BATCH_SIZE).with_object({}) do |batch, outcomes|
      break outcomes unless proceed.call

      outcomes.merge!(deliver_batch(batch, payload, kind))
    end
  end

  private

  def deliver_batch(tokens, payload, kind)
    body = { platform: @platform, event: kind, tokens: tokens, call: payload, expires_at: @expires_at }
    response = ChatwootHub.voice_relay_request(:post, 'pushes', body, read_timeout: READ_TIMEOUT_SECONDS)
    results = JSON.parse(response.body).fetch('results')
    tokens.index_with { |token| outcome(token, kind, results[token] || {}) }
  rescue StandardError => e
    status = e.respond_to?(:http_code) ? " status=#{e.http_code}" : ''
    Rails.logger.error("[VOIP PUSH] #{@platform} #{kind} call #{@call_id} via hub relay failed: #{e.class}#{status}")
    tokens.index_with(:failed)
  end

  def outcome(token, kind, result)
    outcome = OUTCOMES.fetch(result['status'], :failed)
    Rails.logger.public_send(outcome == :failed ? :error : :info,
                             "[VOIP PUSH] #{@platform} #{kind} call #{@call_id} to #{token[0, 8]}… via hub relay " \
                             "status=#{result['status']} #{result['reason']}")
    outcome
  end
end
