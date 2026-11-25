# WhatsApp echoes back every message the session sends, including the ones Chatwoot
# itself dispatched. Those echoes are normally recognized by `source_id`, which is
# written from the send response, but when that response is lost and the job retries,
# the echo carries an id Chatwoot never stored: it would land as a new sender-less
# outgoing message, rendered as if an agent had replied from the phone.
#
# Session sends reserve their WhatsApp id before the request (Outbound::SourceIdReservation),
# so the echo is matched on that reservation instead, and the id the response never
# delivered is filled in here.
class Whatsapp::Session::Inbound::EchoMatcher
  attr_reader :inbox, :message_id, :client_ref

  # `client_ref` is the correlation token for a provider that assigns its own message
  # id and cannot take ours: the echo then comes back under an id Chatwoot has never
  # seen, and this token is the only thing tying it to the message that was sent.
  def initialize(inbox:, message_id:, client_ref: nil)
    @inbox = inbox
    @message_id = message_id
    @client_ref = client_ref
  end

  # Returns the already-stored message this echo belongs to, or nil.
  def perform
    reserved = reserved_message
    return if reserved.nil?

    confirm_source_id(reserved)
    reserved
  end

  private

  # The whole inbox, not the peer's conversations. A reservation is a WhatsApp message
  # id this session generated, so it identifies the message on its own, and scoping the
  # lookup to a contact only means the echo of a chat addressed by a key that contact is
  # not filed under yet misses its own reservation and is stored a second time.
  def reserved_message
    references = [message_id, client_ref].compact_blank
    return if references.empty?

    inbox.messages
         .where(message_type: :outgoing)
         .where("(content_attributes#>>'{}')::jsonb->>'pending_source_id' IN (?)", references)
         .first
  end

  # The id the send never got to store is what a revoke needs, so a message deleted while
  # that send was in flight can only be taken off the contact's phone once this echo
  # supplies it. Same rule as the send response, through the same helper: whoever moves
  # `source_id` from blank to set owes the revoke, decided under the row lock, enqueued
  # after it commits. Enqueued inside, the job can run before the commit, read a blank id
  # and return, while the other writer sees the id already set and enqueues nothing.
  def confirm_source_id(reserved)
    return if message_id.blank?
    return unless Whatsapp::Session::Outbound::SourceIdReservation.assign(reserved, { source_id: message_id }) == :revoke

    Messages::DeleteOnChannelJob.perform_later(reserved.id)
  end
end
