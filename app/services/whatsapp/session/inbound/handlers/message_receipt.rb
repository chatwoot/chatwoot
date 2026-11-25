# Delivery receipts for messages this session sent, and read marks the contact made.
class Whatsapp::Session::Inbound::Handlers::MessageReceipt < Whatsapp::Session::Inbound::Handlers::Base
  # One query for the whole batch. A receipt is a batch by nature and a large one by
  # habit: opening a chat produced a single read event naming 246 messages, most of them
  # from before the inbox existed, and a lookup per id put hundreds of round trips on the
  # queue that inbound messages share.
  #
  # Never deferred, unlike the events that mutate one message. Waiting for the ids it
  # names would replay that whole batch five times over the ones that are never coming,
  # and losing a receipt is self-correcting in a way that losing a revoke is not: the
  # next one on the chat carries the same marker forward.
  def perform
    messages = find_messages(Array(payload.message_ids).compact_blank).to_a
    return :ignored if messages.empty?

    updated = messages.count { |message| apply(message) }
    updated.positive? ? :handled : :ignored
  end

  private

  def apply(message)
    seen = mark_conversation_seen(message) if read_on_our_side?(message) && !own_receipt?(message)
    changed = inbound::StatusTransition.apply(message, payload.type, error: payload.error)
    changed || seen.present?
  end

  # A read receipt for an *incoming* message is one of this account's own devices
  # marking the chat read, so somebody here saw it. A read receipt for an outgoing
  # message is the contact reading us, which says nothing about what we have seen:
  # counting it would clear the unread badge for incoming messages nobody here opened.
  def read_on_our_side?(message)
    payload.type == 'read' && message.incoming?
  end

  # This app's own receipt, echoed back by the provider. It is not a device of this account
  # opening the chat, and treating it as one clears the unread badge for a conversation
  # nobody here has read -- which is exactly what an agent bot's provider-only receipt is
  # not allowed to do.
  def own_receipt?(message)
    acknowledged_in(message.conversation).include?(message.source_id)
  end

  # Read once per conversation, not once per message: this handler resolves a whole receipt
  # in one query on purpose, and asking Redis per message would undo that.
  def acknowledged_in(conversation)
    @acknowledged_in ||= {}
    @acknowledged_in[conversation.id] ||= Whatsapp::SelfReadReceipts.acknowledged(conversation, payload.message_ids)
  end

  # The receipt says the chat was read *at that moment*, not now. Unread counts compare
  # a message's creation time against these markers, so stamping `Time.current` marks
  # every incoming message that arrived since as seen too: a read receipt delivered late,
  # or an HTTP event job running out of order, would clear the badge for messages nobody
  # here has opened. The markers only ever move forward.
  def mark_conversation_seen(message)
    conversation = message.conversation
    seen_at = read_at(message)

    # Compared and written under the row lock. Two read receipts for one conversation can
    # be processed at once, and comparing outside the lock lets both pass against the old
    # value, after which the older receipt can land last and walk the marker backwards,
    # making messages that were already seen show up unread again.
    conversation.with_lock do
      next false if conversation.agent_last_seen_at.present? && conversation.agent_last_seen_at >= seen_at

      attributes = { agent_last_seen_at: seen_at }
      attributes[:assignee_last_seen_at] = seen_at if conversation.assignee_id.present?
      conversation.update_columns(attributes) # rubocop:disable Rails/SkipsModelValidations
      true
    end
  end

  # The receipt's own time when the provider reports one, otherwise the message it names:
  # reading a message cannot have happened before that message existed.
  def read_at(message)
    return Time.zone.at(payload.timestamp / 1000) if payload.timestamp.present?

    message.created_at
  end
end
