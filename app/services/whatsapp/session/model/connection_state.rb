# The provider connection as the UI sees it. Persisted as-is in
# channel_whatsapp.provider_connection by ConnectionStateWriter, keeping the shape the
# Baileys layer already writes so the dashboard needs no migration.
#
# `error` carries an i18n key suffix on the wire, never a provider message.
# ConnectionStateWriter resolves it under `errors.inboxes.channel.provider_connection`
# before persisting, so what the dashboard reads is already a sentence.
#
# `rerouting` marks a reconnect the connector is making on purpose (a proxy change). It
# is agent-visible, unlike `error`, because it is the only thing that tells an agent's
# view a deliberate reconnect apart from an outage.
class Whatsapp::Session::Model::ConnectionState < Data.define(
  :connection, :qr_data_url, :pairing_code, :error, :epoch, :phone_number, :lid,
  :quarantine, :ban, :reachout_time_lock, :new_chat_cap, :pairing_attempt, :rerouting
)
  include Whatsapp::Session::Model::Serializable

  CONNECTIONS = %w[close connecting reconnecting open].freeze

  # Written by polls and by the provider outside the connection lifecycle, so a state
  # update must never drop them.
  STICKY_KEYS = %w[reachout_time_lock new_chat_cap].freeze

  def initialize(**attributes)
    connection = attributes[:connection].to_s
    raise Whatsapp::Session::Errors::InvalidPayload, "unknown connection: #{connection}" unless CONNECTIONS.include?(connection)

    # Normalized, not just validated: a bare `super` would forward the caller's own
    # value, so a symbol would pass validation and then be stored as a symbol, making
    # `open?` false and putting a non-canonical value on the wire.
    super(**attributes, connection: connection)
  end

  def open?
    connection == 'open'
  end

  def close?
    connection == 'close'
  end

  def connecting?
    connection.in?(%w[connecting reconnecting])
  end

  # The pairing attempt token rides along only while the attempt is still running. Stamped
  # onto a state that ended it, the token stays on the record and the polling chain looks
  # current forever: it would poll a session that has already opened and, if that request
  # failed, write `connect_failure` over a healthy connection.
  def with_attempt(attempt)
    return self if attempt.blank? || !connecting?

    with(pairing_attempt: attempt)
  end
end
