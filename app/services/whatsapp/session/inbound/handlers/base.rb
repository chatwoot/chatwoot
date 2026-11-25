# Common ground for every inbound handler: what the event is about, and the four
# answers a handler may give.
#
#   :handled   the event changed something
#   :ignored   the event is not actionable here (disabled capability, unknown chat...)
#   :duplicate the event had already been processed
#   :deferred  the message this event is about is not stored yet
#
# `:deferred` is about delivery order. An HTTP webhook can run an edit before the message
# it edits, so its job retries. The connector delivers a session's events in order, but a
# history slice is filed by a job of its own, so a target can still be waiting for its
# import: the consumer hands the event to Whatsapp::Session::DeferredEventJob, which tries
# again for a while and then drops it.
class Whatsapp::Session::Inbound::Handlers::Base
  attr_reader :channel, :event, :instance

  # `instance` is the provider instance the event was authenticated against, when the
  # transport can tell. Only the connection record can act on it (the writer compares it
  # inside the row lock); for everything else the dispatcher's check is the whole fence.
  def initialize(channel:, event:, instance: nil)
    @channel = channel
    @event = event
    @instance = instance
  end

  def perform
    raise NotImplementedError, "#{self.class} must implement #perform"
  end

  private

  # Resolved on every call, never held in a constant. Both are implicit namespaces (no
  # `model.rb`, no `inbound.rb`), so a constant here captures a module object that a
  # reload strips of its autoloads, and every handler inheriting it then raises
  # `uninitialized constant` on the first lookup through it. Asking for the full path
  # each time is what makes the tree survive a reload.
  def model = Whatsapp::Session::Model
  def inbound = Whatsapp::Session::Inbound

  def payload = event.payload
  def inbox = channel.inbox
  def account = inbox.account

  def capability?(capability)
    channel.session_capabilities.include?(capability.to_s)
  end

  # Chats Chatwoot has no representation for. The connector already drops most of them,
  # but a hosted API forwards everything its instance sees.
  def ignorable_chat?(address)
    address.blank? || address.ignorable?
  end

  def find_message(source_id) = find_messages(source_id).first

  # A shared-contact payload is stored as one row per card, all carrying the provider's
  # single id, which is how the Baileys layer and the Cloud provider store it too.
  # Anything mutating a message by that id therefore has to reach every row, or a revoke
  # takes one card off the screen and leaves the rest of the share behind.
  def find_messages(source_id)
    return Message.none if source_id.blank?

    inbox.messages.where(source_id: source_id).order(:id)
  end
end
