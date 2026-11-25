# One webhook body from this provider, turned into canonical events.
#
# The envelope has three shapes, keyed by `EventType`: a connection carries `instance`, a
# message carries `message` (plus a large CRM object this layer ignores), and everything
# else carries `event`. What they have in common is `token`, the instance credential,
# which is why nothing here copies the body into an event: `raw` stays empty rather than
# carrying a secret into a job argument, a log line and a database row.
#
# A body this build does not understand produces no events at all. That is what lets a
# provider add an event type, or an operator subscribe to more than Chatwoot asked for,
# without the inbox failing on every delivery.
class Whatsapp::Session::Backends::Uazapi::WebhookTranslator
  include Whatsapp::Session::Backends::Uazapi::WebhookTranslator::History
  # `state` at the top of the body, not `event.Type`: the casing of the latter is not
  # stable (a peer reading answers `Read`, our own `/message/markread` answers `read`),
  # while `state` was consistent across every capture.
  #
  # `FileDownloaded` is the provider's own bookkeeping and means nothing here.
  RECEIPTS = { 'Delivered' => 'delivered', 'Read' => 'read', 'Played' => 'played' }.freeze
  REVOKED = 'Deleted'.freeze

  # whatsmeow reports a recording as `composing` with an audio media hint.
  PRESENCE_STATES = %w[composing paused available unavailable].freeze

  attr_reader :channel, :body

  def initialize(channel, payload)
    @channel = channel
    @body = (payload || {}).to_h.with_indifferent_access
  end

  # Returns the canonical events this body carries, in order.
  #
  # More than one only for a bulk revoke, whose handler is a no-op on a message already
  # flagged: the job that dispatches these replays the whole body when a later event has
  # to wait for its message, so anything emitted alongside one has to survive being run
  # twice.
  def perform
    return [] unless this_instance?

    return message_update if body[:EventType] == 'messages_update'

    [single_event].compact
  end

  private

  # Every envelope but `messages_update`, which is the one that can carry several.
  def single_event
    case body[:EventType]
    when 'connection' then connection
    when 'messages' then message
    when 'presence' then chat_presence
    when 'groups' then group
    when 'history' then history
    end
  end

  # The instance the body says it came from, against the one the inbox is pointed at now.
  # A body is authenticated when it arrives and dispatched later, and an inbox re-pointed
  # in between would file the old instance's messages under the new one: the token that
  # authenticated them is gone by then, and the provider on its own says nothing about
  # which instance a queued job was meant for.
  #
  # Only when the body carries the field, which every captured one does. Missing, it is a
  # shape this build does not know, and a shape is not a reason to drop an event.
  def this_instance?
    sent_from = body[:BaseUrl].to_s.chomp('/').downcase
    configured = channel.provider_config['base_url'].to_s.chomp('/').downcase
    sent_from.blank? || configured.blank? || sent_from == configured
  end

  def model = Whatsapp::Session::Model
  def events = Whatsapp::Session::Model::Events
  def uazapi = Whatsapp::Session::Backends::Uazapi

  def event(payload, timestamp: nil)
    return if payload.nil?

    model::Event.build(payload, id: body[:event_id].presence, ts: timestamp)
  end

  # --- connection --------------------------------------------------------------------

  def connection
    instance = (body[:instance] || {}).to_h
    status = uazapi::Backend::CONNECTIONS.fetch(instance['status'].to_s, 'close')
    return event(events::PairingQr.new(png_data_url: instance['qrcode'])) if status == 'connecting' && instance['qrcode'].present?

    event(events::SessionState.new(state: status, phone: connected_phone(status)))
  end

  # `owner` keeps the last number the instance was paired with for as long as it sits
  # disconnected, so it is only read when the session is actually up. Reporting a stale
  # one would tell the writer this inbox is paired with a number that is not there, and
  # the ownership check would quarantine it over that.
  def connected_phone(status)
    body[:owner].presence if status == 'open'
  end

  # --- messages ----------------------------------------------------------------------

  def message
    payload = (body[:message] || {}).to_h.with_indifferent_access
    return if payload[:messageid].blank?

    timestamp = timestamp_ms(payload[:messageTimestamp])
    return event(reaction(payload, timestamp), timestamp: timestamp) if payload[:type] == 'reaction'
    return event(edited(payload, timestamp), timestamp: timestamp) if payload[:edited].present?

    event(events::MessageReceived.new(message: inbound_message(payload, timestamp)), timestamp: timestamp)
  end

  def inbound_message(payload, timestamp)
    content = uazapi::ContentMapper.new(payload)
    model::InboundMessage.new(
      id: payload[:messageid], chat: chat_of(payload), sender: sender_of(payload), from_me: payload[:fromMe].present?,
      timestamp: timestamp, content: content.perform, quoted_id: quoted_id(payload), mentions: mentions(content),
      client_ref: payload[:track_id].presence
    )
  end

  # An edit arrives as an ordinary message with an id of its own and `edited` naming the
  # message it replaces, so the event is addressed to the original.
  def edited(payload, timestamp)
    events::MessageEdited.new(
      chat: chat_of(payload), sender: sender_of(payload), message_id: payload[:edited],
      from_me: payload[:fromMe].present?, timestamp: timestamp, content: uazapi::ContentMapper.new(payload).perform
    )
  end

  def reaction(payload, timestamp)
    events::MessageReaction.new(
      id: payload[:messageid], chat: chat_of(payload), sender: sender_of(payload), from_me: payload[:fromMe].present?,
      target_id: payload[:reaction], emoji: payload[:text].to_s, timestamp: timestamp
    )
  end

  # `chatid` rather than `chatlid`: the LID form is only sent for incoming messages, so
  # using it would give the same 1:1 chat two different addresses depending on who spoke.
  # Nothing is lost by that, because the LID travels on the sender of every incoming
  # message, which is what the contact is filed under.
  def chat_of(payload)
    model::Address.parse(payload[:chatid])
  end

  # Both identities always travel, and `sender` alone alternates between them for no
  # visible reason, so the pair is what is read. On a message the connected phone sent
  # this describes us, not the peer, which is what the handler expects.
  def sender_of(payload)
    model::Party.new(
      lid: address_id(payload[:sender_lid]), phone: address_id(payload[:sender_pn]), push_name: payload[:senderName].presence
    )
  end

  def address_id(jid)
    model::Address.parse(jid)&.id
  end

  # The quoted message, which the provider reports either as a bare id or as the message
  # it points at.
  def quoted_id(payload)
    quoted = payload[:quoted]
    quoted.is_a?(Hash) ? quoted['messageid'].presence : quoted.presence
  end

  def mentions(content)
    Array(content.body.dig(:contextInfo, :mentionedJid)).filter_map { |jid| model::Address.parse(jid) }
  end

  # --- receipts and revokes ------------------------------------------------------------

  def message_update
    payload = (body[:event] || {}).to_h.with_indifferent_access
    ids = Array(payload[:MessageIDs]).compact_blank
    return [] if ids.empty?

    timestamp = timestamp_ms(payload[:Timestamp])
    return revokes(payload, ids, timestamp) if body[:state] == REVOKED

    type = RECEIPTS[body[:state].to_s]
    return [] if type.nil?

    [event(receipt(payload, ids, type, timestamp), timestamp: timestamp)].compact
  end

  def receipt(payload, ids, type, timestamp)
    events::MessageReceipt.new(
      chat: chat_of_event(payload), message_ids: ids, type: type,
      participant: participant_of(payload), timestamp: timestamp
    )
  end

  # A revoke names one message, and the provider batches ids like any other update, so a
  # bulk deletion becomes one event per message.
  def revokes(payload, ids, timestamp)
    ids.filter_map do |id|
      event(
        events::MessageRevoked.new(
          chat: chat_of_event(payload), sender: sender_of_event(payload), message_id: id,
          by: payload[:IsFromMe].present? ? 'self' : 'contact', timestamp: timestamp
        ),
        timestamp: timestamp
      )
    end
  end

  # --- presence ------------------------------------------------------------------------

  # Our own typing comes back on this webhook, and it names the peer's chat: dispatched as
  # it is, the dashboard would show the contact typing every time an agent does.
  def chat_presence
    payload = (body[:event] || {}).to_h.with_indifferent_access
    return if payload[:IsFromMe].present?

    state = payload[:State].to_s.downcase
    return unless PRESENCE_STATES.include?(state)

    state = 'recording' if state == 'composing' && payload[:Media].to_s == 'audio'
    event(events::ChatPresence.new(chat: chat_of_event(payload), sender: sender_of_event(payload), state: state))
  end

  # --- groups ---------------------------------------------------------------------------

  def group
    payload = (body[:event] || {}).to_h.with_indifferent_access
    return if payload[:JID].blank?

    payload[:Type] == 'new' ? joined(payload) : updated(payload)
  end

  def joined(payload)
    info = uazapi::GroupMapper.new(payload).perform
    event(events::GroupJoined.new(info: info)) if info.present?
  end

  # A membership change carries no `Type` at all: which of the arrays is populated is what
  # says what happened.
  def updated(payload)
    mapper = uazapi::GroupChangeMapper.new(payload)
    changes = mapper.perform
    # Something changed and the contract has no truthful field for it, so the group is
    # pinged instead of described: this side reads it back from a snapshot, which is the
    # only source that knows which way an approval setting was moved.
    #
    # Only when nothing else came with it, because one webhook produces one event here. A
    # notification carrying both a carriable change and this one describes what it can, and
    # the setting waits for the next scheduled sync. WhatsApp was measured sending one
    # change per notification, so that is a residue rather than the common case.
    return event(events::GroupActivity.new(groups: [model::Address.parse(payload[:JID])])) if changes.nil? && mapper.uncarried?
    return if changes.nil?

    timestamp = timestamp_ms(payload[:Timestamp])
    event(
      events::GroupUpdated.new(
        group: model::Address.parse(payload[:JID]), actor: sender_of_event(payload), timestamp: timestamp, changes: changes
      ),
      timestamp: timestamp
    )
  end

  # --- shared ----------------------------------------------------------------------------

  def chat_of_event(payload)
    model::Address.parse(payload[:chatid].presence || payload[:Chat])
  end

  def sender_of_event(payload)
    lid = address_id(payload[:sender_lid])
    phone = address_id(payload[:sender_pn].presence || payload[:SenderPN])
    return if lid.blank? && phone.blank?

    model::Party.new(lid: lid, phone: phone, push_name: payload[:Notify].presence)
  end

  # In a group a receipt belongs to the participant that sent it; in a 1:1 chat the peer
  # is the chat itself and the field stays empty.
  def participant_of(payload)
    return if payload[:IsGroup].blank?

    sender_of_event(payload)&.address
  end

  # The provider is not consistent about time: a message carries milliseconds, a receipt
  # carries whole seconds in one shape and an ISO string in another. Everything above this
  # layer reads milliseconds.
  def timestamp_ms(value)
    return (value.to_f * 1000).round if value.is_a?(Numeric) && value < 1e11
    return value.to_i if value.is_a?(Numeric)

    Time.zone.parse(value.to_s)&.to_i&.*(1000)
  rescue ArgumentError
    nil
  end
end
