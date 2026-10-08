# Sends FCM data messages for a call's ring and its cancel to Android phones, a batch of
# devices at a time. Built from a client made before any delivery thread starts, so the
# deliveries make HTTP requests only and never touch the database.
class Voice::FcmVoipSender
  pattr_initialize [:client!, :call_id!, :expiry_seconds!]

  # Deliveries in flight at once
  BATCH_SIZE = 20

  # Returns each token's outcome: :sent, :gone when Firebase reports it unregistered, or :failed
  def deliver(tokens, data, kind)
    tokens.each_slice(BATCH_SIZE).with_object({}) do |batch, results|
      outcomes = batch.map { |token| Thread.new { deliver_one(token, data, kind) } }.map(&:value)
      results.merge!(batch.zip(outcomes).to_h)
    end
  end

  private

  def deliver_one(token, data, kind)
    response = client.send_v1(token: token, data: data, android: { priority: 'high', ttl: "#{expiry_seconds}s" })
    Rails.logger.info("[VOIP PUSH] android #{kind} call #{call_id} to #{token[0, 8]}… status=#{response[:status_code]}")
    return :sent if response[:status_code] == 200

    response[:status_code] == 404 && response[:body].to_s.include?('UNREGISTERED') ? :gone : :failed
  rescue StandardError => e
    Rails.logger.error("[VOIP PUSH] android #{kind} call #{call_id} to #{token[0, 8]}… failed: #{e.class}: #{e.message}")
    :failed
  end
end
