# Sends APNs VoIP pushes over one connection. Built from settings read before any delivery
# thread starts, so the deliveries make HTTP requests only and never touch the database.
class Voice::ApnsVoipSender
  pattr_initialize [:settings!, :call_id!]

  # Returns each token's outcome: :sent, :gone when Apple no longer knows it, or :failed
  def ring(tokens, payload)
    return {} if tokens.empty?

    connection = new_connection
    tokens.index_with { |token| deliver(connection, token, payload) }
  ensure
    connection&.close
  end

  private

  def new_connection
    Apnotic::Connection.new(
      url: settings[:production] ? Apnotic::APPLE_PRODUCTION_SERVER_URL : Apnotic::APPLE_DEVELOPMENT_SERVER_URL,
      auth_method: :token,
      cert_path: StringIO.new(settings[:key]),
      key_id: settings[:key_id],
      team_id: settings[:team_id]
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
    response = connection.push(notification(token, payload))
    status = response ? response.status.to_s : 'no response'
    Rails.logger.info("[VOIP PUSH] apple ring call #{call_id} to #{token[0, 8]}… status=#{status} #{response&.body}")
    status == '410' ? :gone : :sent
  rescue StandardError => e
    Rails.logger.error("[VOIP PUSH] apple ring call #{call_id} to #{token[0, 8]}… failed: #{e.class}: #{e.message}")
    :failed
  end
end
