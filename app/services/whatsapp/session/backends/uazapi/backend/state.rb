# How this provider's answers are read: the connection state behind a pairing screen, and
# the account limits behind the banner.
#
# Split out of the backend for the same reason its messaging and group halves are: the
# class was over the length the project allows, and reading a provider's state is its own
# subject.
module Whatsapp::Session::Backends::Uazapi::Backend::State
  # `instance.status` -> canonical connection. `hibernated` is a paused instance on the
  # provider's side, which for an inbox is the same as being closed.
  CONNECTIONS = {
    'disconnected' => 'close', 'disconnecting' => 'close', 'hibernated' => 'close',
    'connecting' => 'connecting', 'connected' => 'open'
  }.freeze

  # The disconnect reason that means the pairing itself is gone, not just the socket.
  # Anything else the provider reports is a connection that can come back.
  LOGGED_OUT = /401|logged out/i

  private

  def connection_state(response)
    instance = (response.to_h['instance'] || response.to_h).to_h
    connection = pairing_connection(instance)
    model::ConnectionState.new(
      connection: connection,
      qr_data_url: (instance['qrcode'].presence if connection == 'connecting'),
      pairing_code: (instance['paircode'].presence if connection == 'connecting'),
      phone_number: (instance['owner'].presence if connection == 'open'),
      error: connection_error(instance, connection)
    )
  end

  # The provider's own `status`, except that a state still handing out a QR or a pairing
  # code is not a closed one. Its `/instance/connect` answers `connecting`, and a second
  # later `/instance/status` can report `disconnected` while serving the very same QR,
  # unchanged, for as long as anyone keeps asking (measured 22/08/2026). Taken at face
  # value that empties the pairing screen one second after the operator asked for it,
  # while the code they were about to scan is still on offer.
  #
  # A pairing that has really ended stops carrying either artifact, and the poll's own
  # ceiling closes the screen with a timeout rather than leaving it up forever.
  def pairing_connection(instance)
    connection = CONNECTIONS.fetch(instance['status'].to_s, 'close')
    return connection unless connection == 'close'
    return connection if instance['qrcode'].blank? && instance['paircode'].blank?

    'connecting'
  end

  # `owner` keeps the previous number for as long as the instance sits disconnected, so a
  # closed state never reports one: taking it at face value would tell the inbox it is
  # paired with a number that is no longer there.
  def connection_error(instance, connection)
    return if connection != 'close'

    'logged_out' if instance['lastDisconnectReason'].to_s.match?(LOGGED_OUT)
  end

  # --- limits ------------------------------------------------------------------------

  # Answered in the shape the dashboard banner already reads, which the Baileys layer
  # established. A provider that reports nothing leaves the key out entirely, because the
  # check job treats a missing value as "unknown" and keeps the last one rather than
  # clearing a banner that is legitimately up.
  def reachout_time_lock(limits)
    lock = limits['reachout_timelock']
    return if lock.blank?

    { 'is_active' => lock['active'].present?, 'time_enforcement_ends' => lock['until'].presence }.compact
  end

  def new_chat_cap(limits)
    cap = limits['new_chat_message_capping']
    return if cap.blank?

    {
      'capping_status' => cap['status'].presence, 'total_quota' => cap['total_quota'],
      'used_quota' => cap['used_quota'], 'cycle_end_timestamp' => cap['cycle_end'].presence
    }.compact
  end
end
