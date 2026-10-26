# Sends FCM data messages for a call's ring and its cancel to Android phones, a batch of
# devices at a time. Built from a client made before any delivery thread starts, so the
# deliveries make HTTP requests only and never touch the database.
class Voice::FcmVoipSender
  pattr_initialize [:client!, :call_id!, :expiry_seconds!]

  # Deliveries in flight at once
  BATCH_SIZE = 20

  # How long a batch may take; the FCM client sets no timeout of its own. A push still
  # waiting then is stopped, so it neither lingers nor lands after the cancel that follows
  # a ring, and counts as failed.
  PUSH_TIMEOUT_SECONDS = 10

  # Returns each token's outcome: :sent, :gone when Firebase reports it unregistered, or :failed.
  # `proceed` is asked on the calling thread before each batch after the first; once it returns
  # false the remaining tokens are not sent and have no outcome.
  def deliver(tokens, data, kind, proceed: -> { true })
    tokens.each_slice(BATCH_SIZE).with_index.each_with_object({}) do |(batch, index), results|
      break results if index.positive? && !proceed.call

      outcomes = within_timeout(batch.map { |token| Thread.new { deliver_one(token, data, kind) } })
      results.merge!(batch.zip(outcomes).to_h)
    end
  end

  private

  def within_timeout(threads)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + PUSH_TIMEOUT_SECONDS
    threads.map do |thread|
      next thread.value if thread.join([deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC), 0].max)

      thread.kill
      :failed
    end
  end

  def deliver_one(token, data, kind)
    # One collapse key per call, so a cancel queued for an offline phone replaces the ring
    # rather than arriving before it
    android = { priority: 'high', ttl: "#{expiry_seconds}s", collapse_key: "voice_call_#{call_id}" }
    response = client.send_v1(token: token, data: data, android: android)
    outcome = outcome(response)
    # A rejection such as bad credentials or a Firebase outage leaves the phone silent, so it
    # is logged as an error
    Rails.logger.public_send(outcome == :failed ? :error : :info,
                             "[VOIP PUSH] android #{kind} call #{call_id} to #{token[0, 8]}… status=#{response[:status_code]}")
    outcome
  rescue StandardError => e
    Rails.logger.error("[VOIP PUSH] android #{kind} call #{call_id} to #{token[0, 8]}… failed: #{e.class}: #{e.message}")
    :failed
  end

  def outcome(response)
    return :sent if response[:status_code].to_i.between?(200, 299)

    response[:status_code] == 404 && response[:body].to_s.include?('UNREGISTERED') ? :gone : :failed
  end
end
