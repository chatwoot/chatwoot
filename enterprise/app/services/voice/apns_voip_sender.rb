# Sends APNs VoIP pushes over one connection. Built from settings read before any delivery
# thread starts, so the deliveries make HTTP requests only and never touch the database.
class Voice::ApnsVoipSender
  pattr_initialize [:settings!, :call_id!]

  # Pushes in flight at once over the connection, so one slow response does not hold up
  # the iPhones after it
  BATCH_SIZE = 20

  # How long one push may wait to connect and for Apple's answer, well inside the ring, so a
  # stalled first push does not hold up the iPhones after it
  PUSH_TIMEOUT_SECONDS = 10

  # How long the first push, which also sets up TLS, may take in all. The connection's own
  # timeouts do not cover the TLS handshake, so a connection that stalls there is given up.
  FIRST_PUSH_DEADLINE_SECONDS = 15

  # Returns each token's outcome: :sent, :gone when Apple no longer knows it, or :failed.
  # The first push goes alone: APNs allows more requests at once on a connection only
  # after its first. `proceed` is asked on the calling thread before each batch after the
  # first push; once it returns false the remaining tokens are not sent and have no outcome.
  def ring(tokens, payload, proceed: -> { true })
    return {} if tokens.empty?

    connection = new_connection
    first, *rest = tokens
    outcomes = { first => deliver_first(connection, first, payload) }
    # A connection given up reached nobody
    return tokens.index_with(:failed) if (abandoned = outcomes[first].nil?)

    outcomes.merge!(deliver_rest(connection, rest, payload, proceed))
    outcomes
  ensure
    connection&.close unless abandoned
  end

  private

  # nil when the push did not finish in time. That push is then stopped, which releases the
  # connection's lock held through a TLS setup still under way, and the connection is closed
  # on a thread of its own, so nothing here waits on it.
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
    # A rejection such as a wrong key or topic leaves the iPhone silent, so it is logged as an error
    Rails.logger.public_send(outcome == :failed ? :error : :info,
                             "[VOIP PUSH] apple ring call #{call_id} to #{token[0, 8]}… status=#{status} #{response&.body}")
    outcome
  rescue StandardError => e
    Rails.logger.error("[VOIP PUSH] apple ring call #{call_id} to #{token[0, 8]}… failed: #{e.class}: #{e.message}")
    :failed
  end
end
