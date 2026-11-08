class Voice::ApnsVoipSender
  pattr_initialize [:settings!, :call_id!]

  BATCH_SIZE = 20

  PUSH_TIMEOUT_SECONDS = 10

  # The connection timeout does not cover the TLS handshake.
  FIRST_PUSH_DEADLINE_SECONDS = 15

  # APNs allows concurrent requests only after the first push.
  def ring(tokens, payload, proceed: -> { true })
    return {} if tokens.empty?

    connection = new_connection
    first, *rest = tokens
    outcomes = { first => deliver_first(connection, first, payload) }
    return tokens.index_with(:failed) if (abandoned = outcomes[first].nil?)

    outcomes.merge!(deliver_rest(connection, rest, payload, proceed))
    outcomes
  ensure
    connection&.close unless abandoned
  end

  private

  # Stopping the first push releases the TLS lock so the abandoned connection can close.
  def deliver_first(connection, token, payload)
    attempt = Thread.new { deliver(connection, token, payload) }
    return attempt.value if attempt.join(FIRST_PUSH_DEADLINE_SECONDS)

    Rails.logger.error("[VOIP PUSH] apple ring call #{call_id}: connection did not finish its first push in time")
    attempt.kill
    Thread.new { attempt.join && connection.close }
    nil
  end

  def deliver_rest(connection, tokens, payload, proceed)
    tokens.each_slice(BATCH_SIZE).with_object({}) do |batch, outcomes|
      break outcomes unless proceed.call

      outcomes.merge!(deliver_batch(connection, batch, payload))
    end
  end

  def deliver_batch(connection, tokens, payload)
    tokens.zip(tokens.map { |token| Thread.new { deliver(connection, token, payload) } }.map(&:value)).to_h
  end

  def new_connection
    Apnotic::Connection.new(
      url: settings[:production] ? Apnotic::APPLE_PRODUCTION_SERVER_URL : Apnotic::APPLE_DEVELOPMENT_SERVER_URL,
      auth_method: :token,
      cert_path: StringIO.new(settings[:key]),
      key_id: settings[:key_id],
      team_id: settings[:team_id],
      connect_timeout: PUSH_TIMEOUT_SECONDS
    )
  end

  def notification(token, payload)
    Apnotic::Notification.new(token).tap do |notification|
      notification.topic = settings[:topic]
      notification.push_type = 'voip'
      notification.priority = 10
      notification.expiration = Time.now.to_i + settings[:expiry_seconds]
      notification.custom_payload = payload
    end
  end

  def deliver(connection, token, payload)
    response = connection.push(notification(token, payload), timeout: PUSH_TIMEOUT_SECONDS)
    status = response ? response.status.to_s : 'no response'
    outcome = { '200' => :sent, '410' => :gone }.fetch(status, :failed)
    Rails.logger.public_send(outcome == :failed ? :error : :info,
                             "[VOIP PUSH] apple ring call #{call_id} to #{token[0, 8]}… status=#{status} #{response&.body}")
    outcome
  rescue StandardError => e
    Rails.logger.error("[VOIP PUSH] apple ring call #{call_id} to #{token[0, 8]}… failed: #{e.class}: #{e.message}")
    :failed
  end
end
