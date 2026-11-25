# Files one chat's history into a Baileys inbox.
#
# A subclass of the webhook service, and that is the whole design. A `messaging-history.set`
# message is a `WAMessage`, byte for byte the shape `messages.upsert` carries, so an
# imported row can be made indistinguishable from a live one by running the code a live one
# runs: the same content extraction, the same fifteen content types, the same rich parsing,
# the same contact resolution. A translator written alongside it would be a second reading
# of the same payload, and the day the two disagree is the day history stops matching what
# the inbox already holds.
#
# What is not reused is the per-message ceremony around that pipeline, and each omission
# has a reason:
#
#   the message lock       the chat is held for the whole batch instead, so a live message
#                          for the same chat cannot open a second conversation beside the
#                          one being filled. The per-message lock lives in the same Redis
#                          namespace, so taking both would be this job waiting on itself.
#   the contact lookup     resolved once per run rather than once per message. Nine hundred
#                          messages is the difference between seconds and minutes.
#   the avatar fetch       skipped. A first pairing would otherwise ask the provider for
#                          five hundred profile pictures at once, which is how an instance
#                          gets rate limited on the day it is set up. A live message fills
#                          it in.
#   the conversation       picked by Inbound::ConversationFinder, which knows about the
#                          archive: a message from last year must not reopen work, and the
#                          reopen policy the live path follows would do exactly that.
#
# Everything the import may set off is suppressed by Import::SilentWrite for the
# whole run: no notifications, no automations, no outgoing webhooks, no bots, no
# out-of-office replies, no read receipts on the contact's phone. The gap half runs one
# level down, where the dashboard push survives, because somebody is watching the queue it
# lands in.
class Whatsapp::Baileys::HistoryImporter < Whatsapp::IncomingMessageBaileysService
  include Import::HistorySettlement

  # All Inbound::Coverage asks of a message is when it was sent. The raw Baileys hash is
  # not a model and never will be, so it is asked through this rather than by teaching
  # Coverage a second shape.
  Occurrence = Struct.new(:sent_at)

  # Threads this run created, which is what tells an artifact from a fact: a new
  # conversation is stamped waiting-since-now and active-now, and for a message from
  # Saturday both readings are wrong.
  attr_reader :opened

  def perform
    @opened = Set.new
    return if messages.empty?
    # The kill switch, asked once for the whole batch rather than at each write. A dump is
    # not filtered by the bridge the way live traffic is, so a build that handles no groups
    # is still sent theirs -- and everything this class would do with them, filing rows and
    # naming the chat alike, is group processing. Asked here so there is one answer: the
    # rename below is a write of its own and would otherwise reach a subsystem that is off.
    return if group? && !Whatsapp::Providers::WhatsappBaileysService.groups_enabled?

    Whatsapp::Session::Inbound::Locks.with_chat_lock(
      inbox, lock_ids, ttl: inbound::Locks::IMPORT_CHAT_LOCK_TTL, defer_to_waiters: true
    ) do
      Import::SilentWrite.wrap do
        rename_group
        file
      end
    end
  end

  private

  # `batch` and not `messages`: what survives the filter is what there is to file, and a
  # chat whose whole slice is markers must not leave a contact and an empty resolved
  # conversation behind. The rename above it runs either way, because a numbered group's
  # slice being all markers is the ordinary case rather than an exception -- 519 of 614
  # threads on a real pairing.
  def file
    return if batch.empty?

    pending = unstored(batch.sort_by { |raw| timestamp_of(raw) })
    return if pending.empty?

    runs = pending.group_by { |raw| gap?(raw) }
    # Archive first: the two halves land in different threads, and the older one has to
    # exist before the reopen policy is asked which thread is current.
    #
    # An unrequested pile keeps only its gap. The phone offers its whole history at every
    # pairing, and an inbox nobody asked would otherwise fill with a year of somebody's
    # conversations. A first pairing has no coverage at all, so `gap?` calls the whole pile
    # archive and this drops all of it, which is the privacy protection the old outright
    # refusal was standing in for.
    #
    # The archive is silent because a pairing dump is a year of somebody else's
    # conversations arriving at once, and nobody asked to watch that. An answer to a press
    # is the opposite: the operator is looking at the thread it lands in.
    archived = requested ? maybe_announcing { import_run(runs[false], archived: true) } : []
    gap = announcing { import_run(runs[true], archived: false) }
    settle(archived, gap)
  end

  def messages = @messages ||= Array(processed_params[:messages])
  def batch = @batch ||= messages.select { |raw| writable?(raw) }
  def requested = processed_params[:requested]
  def announce = processed_params[:announce]
  def maybe_announcing(&) = announce ? announcing(&) : yield
  def watermark = processed_params[:watermark]
  def inbound = Whatsapp::Session::Inbound

  # The live path answers this with nil -- a `messages.upsert` says nothing about what the
  # group is called, and the subject arrives on its own through `groups.update`. A dump has
  # no such event behind it, so an imported group was filed under its own jid and only a
  # later live event ever fixed it: 34 of 46 groups on a real pairing, and the twelve that
  # escaped were the ones somebody happened to write in afterwards.
  #
  # The subject rides on the frame (see the bridge's `groupNames`). Absent, this returns
  # nil and the jid is used exactly as before, which is also what a bridge too old to send
  # it produces.
  def extract_group_name = processed_params[:group_name]

  # What an import may do to a group's name, and it is the same answer on both paths that
  # reach here: name a group that has none, and leave alone one that has.
  #
  # The subject was read when the frame was queued, and the frames carry no ordering. A
  # `groups.update` may have landed in between and is then the fresher fact, which this has
  # no way to see -- so writing over a real name would make the import a second writer on
  # the field, blind to the first. A group that has a name has the live path keeping it
  # current; a group that has only its jid has nobody.
  #
  # Only the name is withheld. `group_type` is a fact about the chat rather than a race.
  def update_group_contact_info(contact)
    return super if contact.name.blank? || contact.name == extract_group_source_id

    contact.update!(group_type: :group) unless contact.group_type_group?
  end

  # Clearing the backlog of groups filed under their own jid, which is a different job from
  # naming the group a dump is currently filing messages for, even though the rule above is
  # shared.
  #
  # It cannot be tied to writing rows, because the groups it exists for are numbered exactly
  # when their messages are already stored: the dump that finally carries a subject has
  # nothing new to file, and every slice of it may be markers besides.
  #
  # Silent like the rest of the import, so a backdated archive does not wake automations by
  # changing a name.
  def rename_group
    return unless group?
    return if extract_group_name.blank?

    contact = inbox.contact_inboxes.find_by(source_id: extract_group_source_id)&.contact
    return if contact.nil?

    update_group_contact_info(contact)
  end

  # A row that will never become a message: a system marker (`messageStubType`), a revoke
  # or a reaction removal, which mutate a row that has to exist rather than adding one and
  # replayed out of a dump would either no-op or act on a row a later message in the same
  # dump has not written yet, and the markers `ignore_message?` already drops live.
  #
  # Asked here, of the whole batch, rather than at the write: everything between the two
  # -- the contact, its contact_inbox, the conversation -- is resolved once per chat and
  # created before the first row is written, so a chat whose dump holds nothing but markers
  # would leave a contact and an empty resolved conversation behind. Measured on a real
  # pairing: 519 of 614 threads.
  def writable?(raw)
    @raw_message = raw
    return false if raw[:messageStubType].present?

    !(protocol_revoke? || ignore_message? || reaction_removal?)
  end

  # Every id this chat can be addressed by, because WhatsApp names the same peer by phone
  # in one message and by LID in the next, and the live path locks by whichever one its
  # message happened to carry.
  def lock_ids
    return [extract_group_jid] if group?

    [extract_from_jid(type: 'pn'), extract_from_jid(type: 'lid')]
  end

  # One batch is one chat: the handler groups a frame by `remoteJid` before enqueueing it,
  # so the first message answers this for all of them.
  def group?
    @raw_message = messages.first
    jid_type == 'group'
  end

  # One query for the chat rather than one per message, and inside the lock, so a
  # redelivery cannot pass this check alongside the run writing the rows it checks for.
  # `uniq` first because the phone repeats itself within a single dump.
  def unstored(ordered)
    ordered = ordered.uniq { |raw| raw.dig(:key, :id) }
    ids = ordered.filter_map { |raw| raw.dig(:key, :id) }
    stored = inbox.messages.where(source_id: ids).pluck(:source_id).to_set
    ordered.reject { |raw| stored.include?(raw.dig(:key, :id)) }
  end

  def gap?(raw)
    inbound::Coverage.gap?(Occurrence.new(sent_at_of(raw)), watermark)
  end

  def timestamp_of(raw) = baileys_extract_message_timestamp(raw[:messageTimestamp]).to_i

  def sent_at_of(raw)
    seconds = timestamp_of(raw)
    seconds.positive? ? Time.zone.at(seconds) : nil
  end

  # A run is one chat's messages that all belong on the same side of the boundary, so the
  # contact and the conversation behind them are resolved once for the whole run.
  def import_run(run, archived:)
    return [] if run.blank?

    @raw_message = identifying(run)
    return import_group_run(run, archived) if jid_type == 'group'
    # The same two gates the live path applies: a chat this build has no representation
    # for is not filed, and a 1:1 chat is identified by its LID.
    return [] unless %w[lid user].include?(jid_type)
    return [] if extract_from_jid(type: 'lid').blank?

    set_contact
    run = fileable(run)
    return [] if run.empty?

    file_slices(@contact_inbox, run, archived) { |conversation, raw| write(conversation, @contact, raw) }
  end

  # The message that says the most about who the chat belongs to: an incoming one carries
  # phone and LID together, while an echo only carries whatever the chat is addressed by.
  def identifying(run)
    run.find { |raw| !raw.dig(:key, :fromMe) } || run.first
  end

  # What of a 1:1 run is filed: nothing without a contact, and what Whatsapp::BlockedSender
  # lets through for a blocked one.
  def fileable(run)
    return [] if @contact.blank?

    run.reject { |raw| Whatsapp::BlockedSender.silenced?(@contact, from_me: raw.dig(:key, :fromMe) == true) }
  end

  # A group is the one chat whose author changes from message to message, so its sender is
  # resolved per message while the group contact and its threads are resolved once.
  def import_group_run(run, archived)
    @group_contact_inbox, @group_contact = find_or_create_group_contact
    file_slices(@group_contact_inbox, run, archived) do |conversation, raw|
      @raw_message = raw
      resolve_group_sender_contact
      add_group_member(@group_contact, @sender_contact) if @sender_contact
      write(conversation, @sender_contact, raw)
    end
  end

  # Hands each message of the run to the block with the thread it is filed in. A gap is
  # one thread, the one the reopen policy picks; an archive is filed by date and can span
  # several (see ConversationFinder.archive_slices).
  def file_slices(contact_inbox, run, archived)
    slices = if archived
               inbound::ConversationFinder.archive_slices(inbox: inbox, contact_inbox: contact_inbox, messages: run) { |raw| sent_at_of(raw) }
             else
               [[conversation_for(contact_inbox, run.first, archived), run]]
             end
    slices.flat_map do |conversation, slice|
      track(conversation)
      slice.filter_map { |raw| yield(reaction_thread(raw) || conversation, raw) }
    end
  end

  # A reaction annotates a message already filed, so it goes to that message's thread, as on
  # the live path (ConversationFinder#conversation_for_reaction). Filed by its own date it
  # can land in another thread, where the reply lookup cannot find its target and the
  # thread never shows it. The run is oldest first, so a target in the same run is stored.
  def reaction_thread(raw)
    target = unwrap_message_content(raw[:message])&.dig(:reactionMessage, :key, :id)
    inbox.messages.find_by(source_id: target)&.conversation if target.present?
  end

  def conversation_for(contact_inbox, raw, archived)
    inbound::ConversationFinder.new(
      inbox: inbox, contact: contact_inbox.contact, contact_inbox: contact_inbox,
      archived: archived, occurred_at: sent_at_of(raw)
    ).perform
  end

  def track(conversation)
    opened << conversation.id if conversation.previously_new_record?
    conversation
  end

  # The per-message half of the live pipeline, minus the routing that only makes sense for
  # an arrival. Everything the dump carries that is not a message was dropped by `writable?`
  # before any of this chat's records were resolved.
  def write(conversation, sender, raw)
    @raw_message = raw
    @message = nil

    message = build_and_save_message(conversation: conversation, sender: sender, attach_media: should_attach_media?)
    backdate(message)
  end

  # Dated to when it was sent, not to when it was filed. The thread renders in `created_at`
  # order, so rows written at today's timestamp would stack a year of conversation on top
  # of this morning's. Applied after the insert because `webhook_message_attributes` takes
  # no date, and safe there because SilentWrite has already suppressed the callbacks that
  # would have read the wrong one.
  #
  # A shared-contacts message writes one row per card under a single provider id, so those
  # are moved by id rather than through the one row the builder hands back.
  def backdate(message)
    return if message.blank?

    sent_at = sent_at_of(@raw_message)
    return message if sent_at.blank?

    if message_type == 'contact'
      inbox.messages.where(source_id: raw_message_id).update_all(created_at: sent_at) # rubocop:disable Rails/SkipsModelValidations
      message.reload
    else
      message.update_column(:created_at, sent_at) # rubocop:disable Rails/SkipsModelValidations
    end
    message
  end

  # History carries no media bytes, and the bridge does not fetch them for a dump either,
  # so the file the live path downloads from /media was never written: every media message
  # in an import would be a round trip to a guaranteed 404, three hundred of them on a
  # single chat. Flagged directly instead, which is the row the live path ends up with when
  # a download fails.
  def attach_media_to_message
    @message.is_unsupported = true
  end

  # Says the row was filed after the fact, which is what a report excluding backfilled
  # traffic reads, and what keeps the coverage boundary from moving under its own import.
  def build_message_content_attributes
    super.merge(imported: true)
  end

  # An import must not ask the provider for a profile picture. See the class comment.
  def try_update_contact_avatar(contact = nil); end

  # Raises the flag for the stretch it wraps. Only the gap ever asks for it, and only the
  # dashboard push gets through: see Import::SilentWrite.
  def announcing(&) = Import::SilentWrite.wrap(announce: true, &)
end
