# Picks the conversation an inbound message belongs to, or opens one.
#
# Lifted from Whatsapp::IncomingMessageBaseService so the session layer does not have
# to touch that file (it is one of the three the upstream sync keeps rewriting). The
# rules are the upstream ones: a reaction lands in the thread holding its target, and
# everything else follows the inbox reopen policy.
class Whatsapp::Session::Inbound::ConversationFinder
  attr_reader :inbox, :contact, :contact_inbox, :attribution, :reaction_target_id, :archived, :occurred_at

  # `attribution` is the first-touch payload ({ 'referral' =>, 'entry_point' => }) the
  # message carried, already compacted by the handler.
  #
  # `archived` is the history import saying this message predates the inbox's coverage
  # (see Inbound::Coverage): it never had a chance to be answered here, so it must not
  # open work. `occurred_at` is when it actually happened, which picks the thread an
  # archived message is filed in and dates a thread that has to be created for it.
  # rubocop:disable Metrics/ParameterLists -- every one of these is an independent fact
  # about the message being filed; an options object would only move the list elsewhere.
  def initialize(inbox:, contact:, contact_inbox:, attribution: {}, reaction_target_id: nil, archived: false, occurred_at: nil)
    @inbox = inbox
    @contact = contact
    @contact_inbox = contact_inbox
    @attribution = attribution.presence || {}
    @reaction_target_id = reaction_target_id
    @archived = archived
    @occurred_at = occurred_at
  end
  # rubocop:enable Metrics/ParameterLists

  # When the message reuses an existing thread, what conversation_params would have
  # persisted on create never lands. Backfill only the keys still missing, so a genuine
  # first touch is never overwritten by a later one.
  #
  # Reachable without a lookup because a caller can already hold the thread: a message
  # written over the placeholder it left behind has its conversation in hand, and must
  # not come through `perform` to get here -- that would open a second thread whenever
  # the first one is resolved.
  def self.backfill_first_touch(conversation, attribution)
    return conversation if attribution.blank?

    existing = conversation.additional_attributes || {}
    missing = attribution.reject { |key, _| existing.key?(key) }
    conversation.update!(additional_attributes: existing.merge(missing)) if missing.present?
    conversation
  end

  # An archived run split by the thread each part is filed in, as [conversation, messages]
  # pairs. A run can span several threads, since an archive is filed by date, so each part
  # runs up to where the next thread was opened: one lookup per thread crossed rather than
  # one per message. `messages` is oldest first and the block reads when one was sent,
  # which a Baileys record can leave blank: such a message sorts first and is filed with
  # the first slice.
  #
  # An inbox locked to one conversation files the whole run in it. Every slice also takes
  # the first message left, whatever thread the finder picked: the boundary is read off
  # that thread, and a pick that is not the thread of that message by date (the lock
  # takes the highest id, which a backdated thread need not have) would otherwise leave
  # the message out of every slice and the loop going forever.
  def self.archive_slices(inbox:, contact_inbox:, messages:)
    slices = []
    until messages.empty?
      first, *rest = messages
      conversation = new(inbox: inbox, contact: contact_inbox.contact, contact_inbox: contact_inbox,
                         archived: true, occurred_at: yield(first)).perform
      return slices << [conversation, messages] if inbox.lock_to_single_conversation

      following = inbox.conversations.where(contact_id: contact_inbox.contact_id)
                       .where.not(created_at: ..conversation.created_at).minimum(:created_at)
      slice, messages = rest.partition do |message|
        at = yield(message)
        following.nil? || at.nil? || at < following
      end
      slices << [conversation, [first, *slice]]
    end
    slices
  end

  # The thread an archived message sent at `at` is filed in: the last one opened at or
  # before it, or the oldest when it predates them all, or when nothing says when it was
  # sent.
  def self.thread_at(inbox:, contact:, at:)
    chain = contact.conversations.where(inbox_id: inbox.id).reorder(:created_at, :id)
    (chain.where(created_at: ..at).last if at) || chain.first
  end

  def perform
    conversation = conversation_for_reaction || conversation_by_inbox_config
    return backfill_first_touch(mark_as_group(conversation)) if conversation

    ::Conversation.create!(conversation_params)
  end

  private

  # A reaction annotates a message that already exists, so it must land in that
  # message's thread rather than follow the reopen policy: reacting to a message in a
  # resolved conversation would otherwise open a stray blank one.
  def conversation_for_reaction
    return if reaction_target_id.blank?

    inbox.messages.find_by(source_id: reaction_target_id)&.conversation
  end

  def conversation_by_inbox_config
    # Scoped to the contact across all its contact_inboxes: one person can hold several
    # source_ids in the same inbox (phone and LID), and reopen must see all of them.
    conversations = contact.conversations.where(inbox_id: inbox.id)
    # An inbox locked to one conversation keeps the history in it too: the thread reads
    # in date order on its own, and filing by date would put it in threads from before the
    # lock was turned on.
    return conversations.last if inbox.lock_to_single_conversation
    return archive_thread if archived

    conversations.where.not(status: :resolved).last
  end

  # An archived message goes to the thread that was current when it happened: the last one
  # opened at or before it, open or resolved, or the oldest when it predates them all.
  #
  # The reopen policy is the wrong question for it twice over: skipping a resolved thread
  # would open a new one for a message from last year, and doing that per message would end
  # an import of nine hundred messages with nine hundred conversations. The contact's last
  # thread is the wrong answer too, which is what this used to be. Each press of the button
  # then filed its page into whatever thread was newest that day, and the dashboard, which
  # walks a contact's threads by creation date, read August after the 27th and the 27th
  # nowhere near it (measured at a customer in 2026-10).
  #
  # Filed by date, walking back from the newest thread reads everything in the order it
  # happened.
  def archive_thread = self.class.thread_at(inbox: inbox, contact: contact, at: occurred_at)

  def conversation_params
    params = {
      account_id: inbox.account_id, inbox_id: inbox.id,
      contact_id: contact.id, contact_inbox_id: contact_inbox.id
    }
    params[:additional_attributes] = attribution if attribution.present?
    params[:group_type] = :group if group?
    # Dated to the message, so a thread reads as the past it is: an inbox sorted by
    # creation does not show a decade of history as having started this afternoon, and a
    # conversation never claims to be younger than the messages inside it.
    params[:created_at] = occurred_at if occurred_at.present?
    # Resolved from the start, never resolved afterwards. The difference is the whole
    # reason the archive is free: `notify_status_change` and `create_activity` are
    # after_update callbacks, so a thread born in this state fires no resolution reporting
    # event and writes no "resolved by" line into itself. Transitioning to the same state
    # would do both, and every imported thread would land in today's figures.
    params[:status] = :resolved if archived
    params
  end

  # Asked of the contact rather than passed in: the group contact is the one thing that
  # already knows, and a caller that forgot the flag would open an ordinary thread for a
  # group. A thread that predates the group being recognised as one is repaired here,
  # which is what GroupConversationHandler also does when it reuses a conversation.
  def group? = contact.group_type_group?

  def mark_as_group(conversation)
    conversation.update!(group_type: :group) if group? && !conversation.group_type_group?
    conversation
  end

  def backfill_first_touch(conversation) = self.class.backfill_first_touch(conversation, attribution)
end
