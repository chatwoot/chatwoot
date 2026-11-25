# What an import owes a conversation after the rows are in.
#
# Writing history with the ordinary callbacks suppressed (see SilentWrite) leaves the two
# clocks the inbox sorts and reports by untouched, and a thread the run opened carrying
# stamps that describe the import rather than the conversation. Both are put right here,
# once per conversation instead of once per message, and only in the direction that is
# true.
#
# Shared because there are several importers and only one correct answer: the session
# layer files the canonical WhatsApp providers, the Baileys one runs the legacy pipeline
# for the frozen provider, and the IMAP one files a mailbox. None of this is channel
# specific -- it is Conversation and Message bookkeeping -- so a copy in each would drift,
# and the drift would show up as a thread sorted to the wrong place in the list, which
# nobody reads as a bug in an importer.
#
# The includer provides two things: `opened`, the ids of conversations this run created,
# and `announcing`, the block wrapper that lets the dashboard push through.
module Import::HistorySettlement
  # What a buffering importer lets pile up before it sends. Big enough that the job count
  # is a thousandth of the message count, small enough that an interrupted run leaves at
  # most this many rows for the next pass -- which finds them stored and re-settles them,
  # so nothing is lost either way.
  SEARCH_INDEX_BATCH = 500

  # Everything still owed to the index, handed over. Public because it is a contract with
  # whatever runs the import rather than a step inside a settlement: an importer that
  # buffers has to be emptied by the thing that knows the run is over, and a buffer left
  # unflushed is a row missing from the index with nothing anywhere to say so.
  def flush_search_index
    ids = @search_backlog.presence&.uniq
    return if ids.blank?

    # Dropped from the backlog inside the handoff and nowhere else, which covers the two
    # ways it can fail to happen. The enqueue can raise -- Redis away, Sidekiq away -- and
    # the transaction this is called from can roll back, and Rails then discards the
    # callback without running it. Cleared up front, either would take the ids with it: the
    # rows are committed, their per-row callback was suppressed, and every later pass skips
    # them as already stored, so a batch lost here is a batch nothing indexes again. The
    # threshold flush makes that a live case rather than a careful one -- it fires inside
    # the mail importer's transaction, carrying ids from hundreds of messages that
    # committed long before it.
    ActiveRecord.after_all_transactions_commit do
      ::Message.where(id: ids).reindex(mode: :async)
      @search_backlog -= ids
    end
  end

  private

  # Both halves are settled together rather than one after the other, because a chat can
  # hand rows to each and the stamps have to see all of them at once: split in two, the
  # archive pass would read a conversation's rows without the newer gap rows beside them.
  # Which conversations may announce is therefore carried separately from the rows.
  def settle(archived, gap)
    announced = gap.compact.filter_map(&:conversation).uniq
    settled = (archived + gap).compact
    settled.group_by(&:conversation).each do |conversation, rows|
      stamp_activity(conversation, rows)
      stamp_waiting(conversation, rows)
      stamp_seen(conversation, rows)
      stamp_contact(conversation, rows)
      if announced.include?(conversation)
        announcing { Whatsapp::Session::Inbound::ChatList.refresh(conversation) }
      else
        Whatsapp::Session::Inbound::ChatList.refresh(conversation)
      end
    end
    index_for_search(settled)
  end

  # The archive's half of advanced search. `Message#reindex_for_search` fires per record
  # and enqueues a Searchkick job for each, which the guards stop precisely so this can
  # happen instead: the batch goes over whole, and Searchkick splits it into a bulk job per
  # thousand rows. What that buys is not import speed, it is the live queue -- half a
  # million single-row jobs sit ahead of the reply an agent sends while the import runs.
  #
  # Async rather than inline, so an import does not fail because the search cluster is
  # having a bad afternoon. Per batch rather than once at the end, so an interrupted run
  # leaves indexed everything it settled. `should_index?` is Searchkick's own per-record
  # hook and Message defines it, so the relation form drops exactly the rows the callback
  # would have -- activity messages and, on cloud, an account without the flag.
  #
  # Buffered, because a settlement is not a batch. Searchkick splits rows within one
  # `reindex` call and not across calls, so a job per settlement is a job per *message* on
  # the IMAP path, which settles one mail at a time -- exactly the flood the guard was put
  # in to stop, wearing a different job class.
  #
  # After the transaction commits, and that is the whole of why the send is not a one-liner.
  # The IMAP importer settles inside a transaction with the write, and this app does not run
  # `enqueue_after_transaction_commit`: a worker is free to pick the job up before the rows
  # exist, find nothing, and leave them out of the index for good, since the per-row
  # callback that would have caught it later is the one this replaced. Outside a transaction
  # the block runs immediately.
  def index_for_search(rows)
    return if search_index_batch.nil?
    return unless ChatwootApp.advanced_search_allowed?

    @search_backlog = Array(@search_backlog).concat(rows.filter_map(&:id))
    flush_search_index if @search_backlog.length >= search_index_batch
  end

  # How much to let pile up, and `nil` for an importer that does not index at all. The two
  # shapes want opposite answers. A WhatsApp importer is handed a webhook's worth of rows
  # and thrown away: a buffer there would hold the tail of every batch until a request that
  # may never come, and a batch that raised after some rows committed would lose them
  # entirely -- they never reach here, and the retry filters them out as already stored. So
  # it indexes nothing and keeps Message's own per-row callback, which is what the guard
  # leaves alone for it. A backfill outlives every settlement it makes and ends somewhere it
  # can empty the buffer, so it names a size, wraps its writes with `indexing: true` and
  # takes on both the batching and the flush.
  def search_index_batch = nil

  # Where the inbox sorts, and where a thread appears in the list. `set_conversation_activity`
  # assigns whatever row it has just written, unconditionally: left to run over history it
  # would drag a thread answered this morning back to 2025. A thread this run opened takes
  # the batch outright, because it was born stamped with the time of the import; one that
  # already existed only ever moves forward.
  def stamp_activity(conversation, rows)
    newest = rows.filter_map(&:created_at).max
    return if newest.blank?
    return if opened.exclude?(conversation.id) && conversation.last_activity_at.present? &&
              conversation.last_activity_at >= newest

    conversation.update_columns(last_activity_at: newest) # rubocop:disable Rails/SkipsModelValidations
  end

  # The clock the queue and the unattended reports read. Live traffic keeps it by hand: a
  # message from the contact starts it, an answer of ours clears it. An archive thread is
  # resolved and runs no clock at all; an open one gets the same reading live traffic
  # would have left, taken over the whole batch.
  #
  # The archive has to be cleared rather than skipped. `handle_resolved_status_change`
  # clears the clock on a thread that *becomes* resolved, and an archive thread is born
  # resolved instead, so that callback never sees a status change -- leaving whatever
  # `ensure_waiting_since` stamped on it at creation. `Conversation.unattended` reads
  # `waiting_since` with no status of its own, so an import would otherwise file every
  # thread it created as unattended forever.
  def stamp_waiting(conversation, rows)
    return clear_waiting(conversation) if conversation.resolved?

    waiting_since = first_unanswered(rows)
    return unless restamp_waiting?(conversation, waiting_since)

    conversation.update_columns(waiting_since: waiting_since) # rubocop:disable Rails/SkipsModelValidations
  end

  def clear_waiting(conversation)
    return if conversation.waiting_since.blank?

    conversation.update_columns(waiting_since: nil) # rubocop:disable Rails/SkipsModelValidations
  end

  # The unread badge the conversation list draws. `unread_messages` counts every message
  # when `agent_last_seen_at` is nil, so an archive filed resolved -- filed that way
  # precisely so it asks for no attention -- would still arrive wearing a count.
  #
  # A thread holding nothing but imported incoming rows is the test, rather than one this
  # run created: a dump arrives in frames filed by separate workers, so the thread a later
  # frame adds to was created by a worker whose `opened` this one cannot see, and keying on
  # that left a stamp three minutes behind the newest row. What the test protects is the
  # same thing either way -- on a thread that ever received live traffic an unread message
  # is somebody's real backlog, and hiding it would be the worse error.
  #
  # Read off the thread rather than off `rows`, and never moved backwards, so frames may
  # land in any order and each one leaves the same answer.
  # When the contact last said anything, which the dashboard sorts and filters contacts by.
  # Live traffic keeps it in `Message#update_contact_activity`, inside the after-create
  # callbacks the import suppresses wholesale -- so without this an imported contact has a
  # decade of mail and a null clock, and sorts below people who have never written.
  #
  # Not the value the live path would have written, which is `DateTime.now`: on a replay
  # that stamps every contact in the archive with the moment of the import. The row's own
  # date is the true answer, taken only from incoming rows because it is the contact's
  # activity and not ours, and only ever forwards -- a contact with live traffic has a real
  # clock and history must not drag it backwards.
  #
  # Grouped by the row's own sender rather than taken from the conversation, because on a
  # group chat those are different people: the conversation's contact is the group and each
  # incoming row was written by a participant. Stamping the conversation's contact gives
  # the group a clock it never earned and leaves every participant at null. Read off
  # `sender_id` rather than `sender`, so the resume path -- which reads the thread back off
  # the database -- costs one query for the batch instead of one per row.
  #
  # Strictly greater rather than greater-or-equal, because the clock and the roll-up under
  # it are two writes with nothing holding them together: a run that stops between them
  # leaves the contact stamped and the company stale, and `>=` would then make every retry
  # skip both -- the contact is already current, so the roll-up it never got is never asked
  # for again. Falling through costs a write of the value already there and a company rule
  # that refuses to move backwards; skipping costs a company clock wrong forever.
  def stamp_contact(_conversation, rows)
    newest = newest_per_contact(rows)
    return if newest.empty?

    ::Contact.where(id: newest.keys).find_each do |contact|
      at = newest[contact.id]
      next if contact.last_activity_at.present? && contact.last_activity_at > at

      contact.update_columns(last_activity_at: at) # rubocop:disable Rails/SkipsModelValidations
      roll_up(contact, at)
    end
  end

  # A contact rolls its activity up to its company, on installations that have companies.
  # `update_columns` skips the callback that would do it, which is the point everywhere
  # else -- the import writes clocks without firing the machinery around them -- so the one
  # part of that machinery which is itself a clock is asked for explicitly.
  #
  # `record_activity_at!` is the company's own rule and already refuses to move backwards,
  # which is what history needs: a company somebody is talking to today keeps its clock.
  def roll_up(contact, at)
    contact.company&.record_activity_at!(at)
  end

  def newest_per_contact(rows)
    written_by_contacts(rows).group_by(&:sender_id)
                             .transform_values { |sent| sent.filter_map(&:created_at).max }
                             .compact_blank
  end

  def written_by_contacts(rows)
    rows.select { |row| row.incoming? && row.sender_type == 'Contact' && row.sender_id.present? }
  end

  def stamp_seen(conversation, _rows)
    return unless conversation.resolved?
    return if conversation.messages.incoming.where.not(Import::IMPORTED_SQL).exists?

    newest = conversation.messages.maximum(:created_at)
    return if newest.blank?
    return if conversation.agent_last_seen_at.present? && conversation.agent_last_seen_at >= newest

    conversation.update_columns(agent_last_seen_at: newest) # rubocop:disable Rails/SkipsModelValidations
  end

  # A thread this run opened carries what `ensure_waiting_since` stamps on every new
  # conversation, which reads "waiting since now" about a message from Saturday: an
  # artifact, replaced by whatever the batch says, nil included. On a thread that already
  # existed the stored clock is real, and only an older unanswered message may pull it back.
  def restamp_waiting?(conversation, waiting_since)
    return true if opened.include?(conversation.id)
    return false if waiting_since.blank?

    conversation.waiting_since.blank? || conversation.waiting_since > waiting_since
  end

  # The oldest message the contact sent that nothing of ours came after.
  def first_unanswered(rows)
    answered_at = rows.select(&:outgoing?).filter_map(&:created_at).max
    pending = rows.select { |row| row.incoming? && (answered_at.blank? || row.created_at > answered_at) }
    pending.first&.created_at
  end
end

Import::HistorySettlement.prepend_mod_with('Import::HistorySettlement')
