# Files a batch of history into the inbox.
#
# What arrives is one undifferentiated pile: the phone answers a request with everything
# it has for a chat, and answers the first connection with everything it has, full stop.
# One live instance answered a request for fifty messages with nine hundred and forty
# seven. So the policy on volume, on status and on what may be set off is applied here, on
# the way in, and never assumed of the provider.
#
# Two decisions run through it, and they are not the same decision:
#
#   what it is       Inbound::Coverage splits the pile against the last moment the inbox
#                    was known to be receiving. Newer means nobody has had the chance to
#                    read it: that is late mail and it belongs in the queue. Older is
#                    history and it belongs in the archive, filed resolved.
#   what it may do   almost nothing. Import::SilentWrite holds for the whole
#                    run, so no imported message notifies, automates, posts a webhook,
#                    wakes a bot or answers with a template, whichever half it lands in.
#                    The one exception follows the same split: the gap half is written
#                    announcing, so the queue an operator is watching updates itself,
#                    while the archive stays silent because a reader has nothing to gain
#                    from eight hundred backdated rows arriving one cable frame at a time,
#                    unless the pile answers a press of the button: then somebody is
#                    watching the thread for exactly those rows (`announce`).
class Whatsapp::Session::Inbound::HistoryImporter
  include Import::HistorySettlement

  attr_reader :channel, :messages

  # Threads this run created, which is what tells an artifact from a fact. A new
  # conversation is stamped by its own callbacks as waiting since now and active now, and
  # for a message from Saturday both readings are wrong; on a thread that already existed
  # the same two columns hold something real that the import may only refine.
  attr_reader :opened

  # Whether anybody asked for this pile. False is the phone volunteering what it has,
  # which happens at every pairing, and then only the gap is filed: see `import_chat`.
  attr_reader :requested

  # How the pile is filed, beyond what is in it. `announce` is true for an answer somebody
  # is watching arrive, which files the archive half announcing too; `group_name` is what
  # the phone calls the group the slice is about; `exhausted` is the chat the phone said
  # it has nothing older for.
  attr_reader :announce, :group_name, :exhausted

  UNREAD = Object.new.freeze

  # `watermark` is read here when the caller did not read it first. A caller filing
  # slices in parallel reads it once and hands it to all of them: see HistoryImportJob.
  def initialize(channel:, messages:, requested: true, watermark: UNREAD, announce: false, group_name: nil, exhausted: nil) # rubocop:disable Metrics/ParameterLists
    @channel = channel
    @messages = messages
    @requested = requested
    @watermark = watermark
    @announce = announce
    @group_name = group_name.presence
    @exhausted = exhausted
    @opened = Set.new
  end

  def perform
    batches = importable.group_by { |message| message.chat.to_jid }
    # Read once, before anything is written. Every message in the run is classified
    # against the same boundary, or the first imported message would move the line the
    # rest of its own batch is measured against.
    watermark = @watermark.equal?(UNREAD) ? inbound::Coverage.watermark(inbox) : @watermark
    Whatsapp::Session::HistoryMediaJob.holding(inbox) do
      Import::SilentWrite.wrap do
        batches.each_value { |batch| import_chat(batch, watermark) }
      end
    end
    # After the messages, so a slice that is both the last of a chat and the first this
    # inbox sees of it marks the thread its own messages just opened.
    marked = announcing { mark_exhausted }
    batches.empty? && !marked ? :ignored : :handled
  end

  private

  def inbox = channel.inbox
  def inbound = Whatsapp::Session::Inbound

  def importable
    messages.select { |message| importable?(message) }
  end

  # The same gate the live path applies, for the same reasons: a chat Chatwoot has no
  # representation for is not filed, and a group is only filed when the inbox handles
  # groups. A history dump is where an inbox without the capability would otherwise
  # discover several years of group traffic at once.
  def importable?(message)
    return false if message.id.blank? || message.chat.blank? || message.chat.ignorable?
    return channel.session_capabilities.include?('groups') if message.group?

    true
  end

  # Oldest first, which is what makes the thread read in the order it happened and what
  # lets `settle` take the last row as the state the conversation ended in. Archive before
  # gap for the same reason: the two land in different threads, and the older one has to
  # exist first or the reopen policy picks it up as the current conversation.
  def import_chat(batch, watermark)
    ordered = batch.sort_by { |message| message.timestamp.to_i }

    lock_ids = inbound::ChatIdentity.lock_ids(ordered.first)
    inbound::Locks.with_chat_lock(inbox, lock_ids, ttl: inbound::Locks::IMPORT_CHAT_LOCK_TTL, defer_to_waiters: true) do
      pending = unstored(ordered)
      next if pending.empty?

      runs = pending.group_by { |message| inbound::Coverage.gap?(message, watermark) }
      # An unrequested pile keeps only its gap. The phone offers its whole history at every
      # pairing, and an inbox nobody asked would otherwise fill with a year of somebody's
      # conversations; what arrived while the session was down is a different thing, and it
      # is the only part of that offer this inbox is missing. A first pairing has no
      # coverage at all, so `gap?` calls the whole pile archive and this drops all of it,
      # which is what the old outright refusal was protecting.
      archived = file_archive(runs[false])
      gap = announcing { import_run(runs[true], archived: false) }
      settle(archived, gap)
    end
  end

  # Inside the lock, so a redelivery cannot pass this check alongside the run that is
  # writing the rows it is checking for. One query for the chat rather than one per
  # message: a batch is up to two hundred of them.
  #
  # `uniq` before the query, because the phone repeats itself: forty six of the nine
  # hundred and forty seven messages one instance sent were second copies of an id already
  # in the same dump. They happened to fall in different batches there, where the stored
  # row catches them, but nothing promises that.
  #
  # A row already stored may be one whose file was never queued: a retry of a batch that
  # failed between writing it and tracking it skips it here, so it is tracked again (track
  # only queues what is still pending and inside the window).
  def unstored(ordered)
    ordered = ordered.uniq(&:id)
    rows = inbox.messages.where(source_id: ordered.map(&:id))
    rows.where.missing(:attachments).find_each { |row| Whatsapp::Session::HistoryMedia.track(row) }
    stored = rows.pluck(:source_id).to_set
    ordered.reject { |message| stored.include?(message.id) }
  end

  # A run is one chat's messages that all belong on the same side of the boundary, so the
  # contact and the conversation behind them are resolved once rather than once per
  # message. On nine hundred messages that is the difference between an import that takes
  # seconds and one that takes minutes.
  def import_run(run, archived:)
    return [] if run.blank?
    return run.filter_map { |message| import_group(message, archived) } if run.first.group?

    contact_inbox = resolve_contact(identifying(run))
    run = fileable(run, contact_inbox)
    return [] if run.empty?

    slices(contact_inbox, run, archived).flat_map do |conversation, slice|
      track(conversation)
      slice.filter_map { |message| write(conversation, contact_inbox.contact, message) }
    end
  end

  # A gap is one slice, in the thread the reopen policy picks; an archive is filed by date
  # and can span several threads.
  def slices(contact_inbox, run, archived)
    return [[conversation_for(contact_inbox, run.first, archived), run]] unless archived

    inbound::ConversationFinder.archive_slices(inbox: inbox, contact_inbox: contact_inbox, messages: run, &:sent_at)
  end

  # The message in the run that says the most about who the chat belongs to: an incoming
  # one carries phone and LID together, while an echo only carries whatever the chat is
  # addressed by, which can be a LID with no number behind it.
  def identifying(run)
    run.find(&:incoming?) || run.first
  end

  # What of a 1:1 run is filed: nothing without a contact, and what Whatsapp::BlockedSender
  # lets through for a blocked one.
  def fileable(run, contact_inbox)
    return [] if contact_inbox.nil?

    run.reject { |message| Whatsapp::BlockedSender.silenced?(contact_inbox.contact, from_me: !message.incoming?) }
  end

  def conversation_for(contact_inbox, message, archived)
    inbound::ConversationFinder.new(
      inbox: inbox, contact: contact_inbox.contact, contact_inbox: contact_inbox,
      archived: archived, occurred_at: message.sent_at
    ).perform
  end

  # A group is the one chat whose author changes from message to message, so its sender
  # is resolved per message. Its own contact and thread are looked up each time too, which
  # is a query a group batch pays and a 1:1 batch does not.
  def import_group(message, archived)
    resolver = inbound::GroupResolver.new(inbox: inbox, group: message.chat, sender: message.sender, subject: subject_for(message.chat))
    group = resolver.perform
    conversation = track(resolver.conversation_for(group.group_contact_inbox, archived: archived, occurred_at: message.sent_at))

    write(conversation, group.sender_contact, message)
  end

  # `overwrite: false` because the push name on a message from last June is what the
  # contact was called last June, and the live path has been keeping it current since.
  # Avatars are skipped for the same kind of reason and one more: an inbox connecting for
  # the first time would otherwise ask the provider for five hundred profile pictures in
  # one go, which is how an instance gets itself rate limited on the day it is set up. A
  # live message fills the avatar in.
  def resolve_contact(message)
    inbound::ContactResolver.new(
      inbox: inbox, party: inbound::ChatIdentity.peer_party(message), overwrite: false, skip_avatar: true
    ).perform
  end

  def track(conversation)
    opened << conversation.id if conversation.previously_new_record?
    conversation
  end

  # A file the dump carried no reference for goes to the inbox's history queue, which asks
  # for it by message id (Whatsapp::Session::HistoryMedia).
  def write(conversation, sender, message)
    inbound::MessageWriter.new(conversation: conversation, inbound: message, sender: sender, imported: true).perform
                          .tap { |stored| Whatsapp::Session::HistoryMedia.track(stored) if stored.is_a?(Message) }
  end

  # What the suppressed callbacks would have kept up to date, applied once per
  # conversation instead of once per message, and only in the direction that is true.
  # Raises the flag for the stretch it wraps. Only the gap ever asks for it, and only the
  # dashboard push gets through: see Import::SilentWrite.
  # Filed when somebody asked for it. When nobody did, nothing is filed, but the newest
  # message of what was dropped is kept as the place a later request for this chat can
  # page back from: see HistoryAnchors.
  def file_archive(run)
    return maybe_announcing { import_run(run, archived: true) } if requested

    Whatsapp::Session::HistoryAnchors.remember(inbox, run.max_by { |message| message.timestamp.to_i }) if run.present?
    []
  end

  def announcing(&) = Import::SilentWrite.wrap(announce: true, &)
  # The archive half of an answer somebody is watching: announced, and still archive.
  def maybe_announcing(&) = announce ? Import::SilentWrite.wrap(announce: true, archive: true, &) : yield

  # The name the phone gives a group, for a group this inbox has no name for yet: one it
  # has never seen, or one filed under its own id because nothing had named it. A name
  # already there came from the group's own events or a roster sync, which are newer than
  # anything in a dump, so it is left alone.
  def subject_for(group)
    return if group_name.blank?

    (@subjects ||= {}).fetch(group.id) { @subjects[group.id] = (group_name if unnamed?(group)) }
  end

  # The account's contact for the group, not only this inbox's: another inbox may already
  # know it, and the builder reuses that contact by identifier, so a name decided here
  # lands on every inbox that shares it.
  def unnamed?(group)
    contact = inbox.contact_inboxes.find_by(source_id: group.id)&.contact ||
              inbox.account.contacts.find_by(identifier: group.to_jid)
    known = contact&.name
    known.blank? || [group.id, group.to_jid].include?(known)
  end

  # The phone saying this chat has nothing older, which it says on the answer to a request
  # and nowhere else. Recorded on every thread of the chat rather than the one somebody was
  # reading: the request pages back from the oldest message across all of them, so the
  # answer is about the chat. Looked up the way the live path finds a contact, because the
  # answer can address the chat by the other half of the phone and LID pair.
  def mark_exhausted
    return false if exhausted.blank?

    conversations_for(exhausted).find_each do |conversation|
      next if conversation.additional_attributes&.dig('history_exhausted')

      conversation.update!(additional_attributes: (conversation.additional_attributes || {}).merge('history_exhausted' => true))
      # Said out loud: `history_exhausted` is not among the keys whose change announces a
      # conversation, and the thread somebody is reading has to drop the button now, not
      # on the next reload. Inside `announcing`, so the dashboard hears it and nothing
      # else does: no automation or webhook fires for every old thread of the contact.
      conversation.dispatch_conversation_updated_event(conversation.previous_changes, broadcast_metadata: { source: 'history_exhausted' })
    end
    true
  end

  def conversations_for(chat)
    contact_inbox = contact_inbox_for(chat)
    return Conversation.none if contact_inbox.blank?

    inbox.conversations.where(contact_id: contact_inbox.contact_id)
  end

  # A LID alone finds nothing in ContactLookup when the row is still keyed by the phone,
  # and the contact then knows its LID only as its identifier.
  def contact_inbox_for(chat)
    return inbox.contact_inboxes.find_by(source_id: chat.id) if chat.group?

    inbound::ContactLookup.find(inbox: inbox, party: party_for(chat)) ||
      (inbox.contact_inboxes.joins(:contact).find_by(contact: { identifier: chat.to_jid }) if chat.lid?)
  end

  def party_for(chat)
    chat.lid? ? Whatsapp::Session::Model::Party.new(lid: chat.id) : Whatsapp::Session::Model::Party.new(phone: chat.id)
  end
end
