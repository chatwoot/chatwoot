# The presence half of the facade: typing indicators, the agent's own availability, and
# subscribing to a contact's.
#
# Split out for the same reason the group and history halves are: the facade is at the
# length the project allows.
module Whatsapp::Session::Facade::Presence
  # Chatwoot's typing events, in the terms the contract uses.
  TYPING_STATES = {
    Events::Types::CONVERSATION_TYPING_ON => 'composing',
    Events::Types::CONVERSATION_RECORDING => 'recording',
    Events::Types::CONVERSATION_TYPING_OFF => 'paused'
  }.freeze

  # --- presence and contacts -----------------------------------------------------
  #
  # These four are background synchronization the dashboard triggers as a side effect of
  # something else: a listener firing on a typing event, a conversation being marked
  # unread. `Channel::Whatsapp` used to skip them by asking `respond_to?`, which was true
  # of the legacy service and false of anything it did not implement; a facade that
  # answers every message makes that test useless, so the capability is what decides now.
  # Nothing here is an action the agent waits on, so an unsupported one is skipped rather
  # than raised: a listener that raises takes the whole event down with it.

  def toggle_typing_status(typing_status, recipient_id:, **)
    state = TYPING_STATES[typing_status]
    return if state.blank? || !capability?('typing')

    backend.send_chat_presence(model::Commands::ChatPresence.new(chat: address(recipient_id), state: state))
  end

  # `online`, `offline` and `busy` are Chatwoot availability; the contract knows only
  # `available` and `unavailable`. The same mapping the Baileys service has.
  PRESENCE_STATES = { 'online' => 'available', 'offline' => 'unavailable', 'busy' => 'unavailable' }.freeze

  def update_presence(status)
    return unless capability?('presence')

    state = PRESENCE_STATES[status.to_s]
    return if state.blank?

    backend.update_presence(model::Commands::PresenceSet.new(state: state))
  end

  # The command's `party` field carries an Address, not a Party: `PresenceSubscribe`
  # coerces it as one, and `.new` does not run that coercion, so building a Party here
  # put `{phone, lid}` on the wire where the connector expects `{kind, id}`.
  def presence_subscribe(jids)
    return unless capability?('presence_subscribe')

    Array(jids).filter_map { |jid| model::Address.parse(jid) }.each do |address|
      backend.subscribe_presence(model::Commands::PresenceSubscribe.new(party: address))
    end
  end
end
