# Everything that changes what the inbox reports about its WhatsApp connection: the
# state itself, the pairing steps, and the ways a session dies.
#
# One handler for all of them because they write the same record, through the only
# writer allowed to touch it. The i18n key in `error` is what the dashboard renders;
# a provider message never reaches the UI.
class Whatsapp::Session::Inbound::Handlers::ConnectionState < Whatsapp::Session::Inbound::Handlers::Base
  def perform
    state = build_state
    return :ignored if state.nil?

    # Fenced to the instance the event arrived from, and the writer compares it inside the
    # row lock: an inbox re-pointed after the dispatcher looked would otherwise take the
    # previous instance's state, down to the number it was paired with, which reads as the
    # wrong one and ends the session that just replaced it.
    result = Whatsapp::Session::ConnectionStateWriter.new(channel).apply(state, instance: instance)
    return :ignored if result == :stale

    :handled
  end

  private

  # Every event that only means "the session closed, and here is why" maps straight to
  # its i18n key; the rest need a little more than that.
  #
  # Keyed by wire type rather than by event class. A class in a constant is captured when
  # this file loads, and after a reload the incoming payload is an instance of the new
  # generation: the lookup misses, the case below misses too, and the session state is
  # dropped without an error anywhere.
  CLOSING_ERRORS = {
    'session.logged_out' => 'logged_out',
    'session.stream_replaced' => 'stream_replaced',
    'session.temporary_ban' => 'temporary_ban',
    'session.client_outdated' => 'client_outdated',
    'session.connect_failure' => 'connect_failure'
  }.freeze

  # A pairing nobody completed in time. It is the way most pairings that go nowhere end,
  # and there is nothing to report: the code ran out because nobody scanned it, which the
  # person looking at the screen is the one who knows. Reported, it reads as a failure of
  # the connection, and the operator goes looking for one.
  PAIRING_EXPIRED = %w[timeout pairing_timeout].freeze

  # The connector took the socket down to dial again through the proxy the operator just
  # saved, and it comes back within the same connect. A reconnect, not a failure: written
  # with a sentence, the modal shows it in red next to the button to pair the phone again.
  # Written as `rerouting` instead, which the agent's view also receives: the error string
  # is admin-only, so its absence cannot be what tells a deliberate reconnect apart.
  PROXY_CHANGED = 'proxy_changed'.freeze

  # A logout this installation asked for, told apart from an unlink done on the phone.
  # The connector already separates them and says which, and both arrive as
  # `session.logged_out`: collapsing the two sends an agent who just clicked disconnect
  # to go look at a phone that did nothing.
  LOGOUT_REQUESTED = 'logout_requested'.freeze

  # The events that carry a pairing along, keyed by wire type for the same reason
  # CLOSING_ERRORS is: a constant holding a class is the generation this file was loaded
  # in, and after a reload the lookup misses without saying so.
  PAIRING_STEPS = {
    'pairing.error' => :pairing_failure,
    'pairing.qr' => :pairing_qr,
    'pairing.code' => :pairing_code,
    'pairing.success' => :pairing_success
  }.freeze

  def build_state
    type = payload&.wire_type
    error = closing_error(type)
    return closed(error, ban: payload.try(:ban)) if error
    return session_state if type == 'session.state'

    step = PAIRING_STEPS[type]
    send(step) if step
  end

  def pairing_qr = connecting(qr_data_url: payload.png_data_url)
  def pairing_code = connecting(pairing_code: payload.code)

  # Which sentence the dashboard ends up rendering, for the events that end a connection.
  def closing_error(type)
    error = CLOSING_ERRORS[type]
    return error unless error == 'logged_out' && payload.try(:reason) == LOGOUT_REQUESTED

    'logged_out_by_request'
  end

  # A pairing that ended without one. Named after what went wrong rather than reported as
  # a refused connection, because they are different things and only one of them is worth
  # an operator's attention: WhatsApp would not send a code to that number, or the account
  # has not turned multi-device on, are both things they can act on.
  def pairing_failure
    return closed(nil) if payload.reason.to_s.in?(PAIRING_EXPIRED)

    closed("pairing_#{payload.reason}")
  end

  # Whose account this is, is not decided here: the writer refuses any state that names
  # the wrong number, or that names none while the inbox is quarantined, because the poll
  # and the connect answer write states without ever passing through a handler.
  def session_state
    rerouting = payload.reason.to_s == PROXY_CHANGED
    reason = payload.reason.to_s.in?(PAIRING_EXPIRED) || rerouting ? nil : payload.reason
    state(payload.state, error: reason, rerouting: rerouting || nil, phone_number: payload.phone, lid: payload.lid,
                         quarantine: payload.quarantine, ban: payload.ban)
  end

  def pairing_success = connecting(phone_number: payload.phone, lid: payload.lid)

  def closed(error, **attributes) = state('close', error: error, **attributes)
  def connecting(**attributes) = state('connecting', **attributes)

  def state(connection, **attributes)
    model::ConnectionState.new(connection: connection, epoch: epoch, **attributes)
  end

  # Uazapi has no ownership model and sends no epoch; only the connector's epoch is a
  # real fencing token, and it starts at 1.
  def epoch
    event.epoch.to_i.positive? ? event.epoch.to_i : nil
  end
end
