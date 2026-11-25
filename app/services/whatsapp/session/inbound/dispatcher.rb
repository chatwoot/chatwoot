# The single entry point for everything that arrives from a session provider.
#
# The table is explicit on purpose: a type absent from it is ignored, never guessed at
# by name. That is what lets an older Chatwoot keep running against a newer connector,
# and what keeps the Uazapi translator honest about what it can actually produce.
class Whatsapp::Session::Inbound::Dispatcher
  # Handler names, not handler classes. A class object stored here is captured from
  # another file, and a reload leaves this table pointing at the previous generation,
  # whose own namespace aliases are stale in turn. Resolving the name when the event
  # arrives costs nothing and cannot go out of date.
  HANDLERS = {
    'session.state' => 'ConnectionState',
    'session.logged_out' => 'ConnectionState',
    'session.stream_replaced' => 'ConnectionState',
    'session.temporary_ban' => 'ConnectionState',
    'session.client_outdated' => 'ConnectionState',
    'session.connect_failure' => 'ConnectionState',
    'pairing.qr' => 'ConnectionState',
    'pairing.code' => 'ConnectionState',
    'pairing.success' => 'ConnectionState',
    'pairing.error' => 'ConnectionState',
    'message.received' => 'MessageReceived',
    'message.receipt' => 'MessageReceipt',
    'message.edited' => 'MessageEdited',
    'message.revoked' => 'MessageRevoked',
    'message.reaction' => 'MessageReaction',
    'media.download_failed' => 'MediaDownloadFailed',
    'command.failed' => 'CommandFailed',
    'chat.presence' => 'Presence',
    'presence.update' => 'Presence',
    'contact.picture_changed' => 'ContactPictureChanged',
    'group.joined' => 'GroupJoined',
    'group.updated' => 'GroupUpdated',
    'group.picture_changed' => 'GroupPictureChanged',
    'group.activity' => 'GroupActivity',
    'history.sync' => 'HistorySync',
    'call.offer' => 'CallOffer',
    'raw' => 'Raw'
  }.freeze

  # Types the catalog defines and this layer deliberately drops. Listed so that a type
  # missing from both tables shows up as a gap instead of as silence.
  # The offline-sync pair is counts, not content: what the server is about to replay and
  # that it finished. The messages themselves arrive as ordinary `message.received` and
  # are stored by the handler that stores every message, so nothing is lost by not
  # reading these. What they would buy is telling an agent that a backlog is on its way
  # instead of watching the thread fill on its own, which is #407's to spend.
  IGNORED = %w[
    pairing.passkey_request pairing.passkey_confirmation contact.identity_changed
    session.offline_sync_preview session.offline_sync_completed
    call.answered call.terminate
  ].freeze

  attr_reader :channel, :event, :instance

  # Returns :handled, :ignored or :duplicate. Raises Locks::Busy when another worker
  # holds the chat, which the caller answers by retrying the job.
  #
  # `instance` names the provider instance the event was authenticated against, for the
  # transports that can tell (a webhook body carries the token it arrived with; the
  # connector publishes for whichever instance holds the session and has none to name).
  def self.dispatch(channel, event, instance: nil)
    new(channel, event, instance: instance).perform
  end

  def initialize(channel, event, instance: nil)
    @channel = channel
    @event = event
    @instance = instance
  end

  def perform
    return skip('unknown payload') unless event.known?

    handler = HANDLERS[event.type]
    return skip('no handler') if handler.nil?
    return skip('inbox changed provider') if converted?
    return skip('inbox points at another instance') if repointed?
    return skip('inbox disowned its session') unless allowed_while_disowned?(handler)

    klass = "Whatsapp::Session::Inbound::Handlers::#{handler}".constantize
    klass.new(channel: channel, event: event, instance: instance).perform
  end

  private

  # A session paired with a number this inbox is not configured for is somebody else's
  # WhatsApp account, and its chats must not be filed here. The logout that removes it is
  # asynchronous and can be retried for a while, so this is what keeps the wrong account's
  # messages out in the meantime. Connection events still run, because they are how the
  # inbox reports the problem and how a correct pairing clears it.
  def allowed_while_disowned?(handler)
    return true if handler == 'ConnectionState'

    !Whatsapp::Session::ConnectionStateWriter.disowned?(channel)
  end

  # The inbox as it is now, not as the caller's copy remembers it. Read once and used by
  # both checks below: a job that waited in a queue, a retry that waited out a lock or a
  # stream replay can all be holding a channel from minutes ago.
  def current
    return @current if defined?(@current)

    @current = Channel::Whatsapp.find_by(id: channel.id)
  end

  # A check, not a fence: a conversion can land the moment after this reads, and closing
  # that window properly would mean every handler writing under the channel lock and
  # re-reading the provider there. What it does buy is that a backlog delivered after the
  # conversion, which is where the window is wide (a stream replay, a job that waited in
  # a queue, a retry that waited out a lock), stops filing the old provider's chats into
  # an inbox that has moved on.
  def converted?
    return false if current&.provider == channel.provider

    Rails.logger.warn("[WHATSAPP SESSION] #{channel.provider} event dropped on ##{channel.id}, now #{current&.provider.inspect}")
    true
  end

  # The same check for the move the provider cannot see: the inbox was pointed at another
  # instance of the same provider, so the key did not change, only the address and the
  # token behind it. What arrives is another instance's traffic, filed here as if this
  # inbox had received it, down to a state naming a phone number this one never paired.
  #
  # Also a check rather than a fence, for the same reason, and the one write that can be
  # fenced properly is: `ConnectionState` carries the instance into the writer, which
  # compares it inside the row lock.
  def repointed?
    return false if instance.blank?
    return false if instance == Whatsapp::Session::Registry.instance_fingerprint(current)

    Rails.logger.warn("[WHATSAPP SESSION] #{event.type} for a previous instance dropped on ##{channel.id}")
    true
  end

  def skip(reason)
    Rails.logger.debug { "[WHATSAPP SESSION] #{event.type} skipped on inbox #{channel.inbox&.id}: #{reason}" }
    :ignored
  end
end

Whatsapp::Session::Inbound::Dispatcher.prepend_mod_with('Whatsapp::Session::Inbound::Dispatcher')
