class Voice::FcmVoipSender
  pattr_initialize [:client!, :call_id!, :expiry_seconds!]

  BATCH_SIZE = 20

  # FCM's v1 sender sets no request timeout; each batch shares this deadline.
  PUSH_TIMEOUT_SECONDS = 10

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
    # A shared collapse key lets a queued cancel replace the ring for an offline device.
    android = { priority: 'high', ttl: "#{expiry_seconds}s", collapse_key: "voice_call_#{call_id}" }
    response = client.send_v1(token: token, data: data, android: android)
    outcome = outcome(response)
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
