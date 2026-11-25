# A read receipt this app sends comes back as an inbound one. Uazapi answers our own
# `/message/markread` with a `read` webhook naming the very messages we just acknowledged
# (see the `RECEIPTS` note in its webhook translator), and both inbound handlers read that
# as "a device of this account opened the chat" and move `agent_last_seen_at`.
#
# That is harmless while the only sender is an agent opening the thread: the controller has
# already written the same marker, and the handlers only ever move it forward. It is not
# harmless for an agent bot's receipt, which is provider-only by design -- the echo would
# clear the unread badge for a conversation no human has read, and `bot_handoff!` does not
# rewind it, so the thread would reach the human queue already looking read.
#
# So every receipt this app sends records the provider ids it acknowledged, and the inbound
# handlers skip the *timestamp* for a message whose id is on that list. Only the timestamp:
# the message's own status still transitions, because a message we acknowledged really is
# read.
module Whatsapp::SelfReadReceipts
  # Keyed by the provider message id, which is the identity a receipt is addressed by, and
  # neither of the two things next to it. Not the row: one `source_id` can resolve to
  # several rows (a shared-contact payload stores a card each) and the handler applies the
  # receipt to all of them, so a per-row marker covers whichever row the sender named and
  # lets its siblings clear the badge. Not the conversation: that suppresses a genuine read
  # from the paired phone for every *other* message in the chat, and since each receipt
  # refreshes the key, a busy bot thread would never let a device read through again.
  #
  # One key per id, each with its own expiry, rather than a set per conversation: a thread
  # answered by a bot takes a receipt every few seconds, and a set whose TTL is pushed out
  # by every write never ages anything out -- it grows for as long as the conversation is
  # active, and every read transfers the whole of it. The batching that a set was there for
  # is a pipeline on the write and an `MGET` on the read, so the cost is still one round
  # trip each way, and the read now carries only the ids the receipt names.
  #
  # Held far longer than the echo takes to arrive (seconds), because the failure is
  # asymmetric. The inbound path defers and retries on its own ladder --
  # `wait: :polynomially_longer, attempts: 6` is roughly a quarter of an hour before the
  # last try -- and a queue backlog stacks on top of that, so a marker sized to the echo
  # would be gone by the time the echo is finally handled, which is the bug. Held too long
  # it only declines to re-read messages this app has already acknowledged.
  TTL = 30.minutes

  module_function

  # Before the send rather than after: uazapi can have the webhook in flight by the time its
  # HTTP response lands here, and a marker left behind by a send that then failed costs
  # nothing but a window in which this app declines to move a marker it never meant to move.
  def record(conversation, messages)
    ids = source_ids(messages)
    return if ids.empty?

    Redis::Alfred.with do |conn|
      conn.pipelined { |pipe| ids.each { |id| pipe.setex(key(conversation, id), TTL.to_i, '1') } }
    end
  end

  # The ids of `source_ids` this app acknowledged, as a Set. Asked for a whole receipt at a
  # time: one is a batch by nature and a large one by habit -- opening a chat produced a
  # single read event naming 246 messages -- and the handlers resolve all of them in one
  # query for that reason, so a lookup per message would put that many round trips back on
  # the queue inbound messages share.
  def acknowledged(conversation, source_ids)
    ids = Array(source_ids).compact_blank.uniq
    return Set.new if ids.empty?

    values = Redis::Alfred.with { |conn| conn.mget(*ids.map { |id| key(conversation, id) }) }
    Set.new(ids.zip(values).filter_map { |id, value| id if value })
  end

  def key(conversation, source_id)
    format(Redis::Alfred::WHATSAPP_SELF_READ_RECEIPT, conversation_id: conversation.id, source_id: source_id)
  end

  # `pluck` on a relation so a backlog is one column of strings rather than a row each; the
  # providers materialize what they need on their own terms.
  def source_ids(messages)
    ids = messages.is_a?(ActiveRecord::Relation) ? messages.pluck(:source_id) : messages.map(&:source_id)
    ids.compact_blank.uniq
  end
end
