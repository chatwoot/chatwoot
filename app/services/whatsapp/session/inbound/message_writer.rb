# Turns a canonical InboundMessage into the Chatwoot message row (or rows, for shared
# contacts). Every provider in the session family goes through this one writer, so the
# stored shape does not depend on who delivered the message.
#
# Media is downloaded here only for a backend that asks for it (`inline_media?`), so the
# message is stored with its file and `message_created` carries it. Everywhere else the
# bytes are fetched by MediaFetchJob and attached afterwards: downloading inline would
# stall the consumer thread that keeps a session's events in order.
class Whatsapp::Session::Inbound::MessageWriter
  # The key a recovered row carries while it still owes an announcement. Written in the same save as
  # the content and taken off once the announcement is enqueued, so it names a debt rather than a fact
  # about the row's past (#646).
  RECOVERY_OWED = 'recovery_announcement_owed_at'.freeze

  attr_reader :conversation, :inbound, :sender, :imported

  # `imported` marks a row the history import is writing rather than one that just
  # arrived. It changes two things and deliberately nothing else: the row is dated to when
  # it was sent, and WhatsApp is not told it was received.
  def initialize(conversation:, inbound:, sender: nil, imported: false)
    @conversation = conversation
    @inbound = inbound
    @sender = sender
    @imported = imported
  end

  # The media an inbound message carries, whichever shape holds it, or nil. Says nothing
  # about whether its bytes are reachable: a media message published with no `ref` is one
  # whose file did not come with it, and `media.download_failed` is what explains that.
  def self.media_in(inbound)
    content = inbound.content
    media = content if content&.wire_type == 'media'
    media ||= content.media if content&.wire_type == 'rich'
    media.presence
  end

  # Queues the fetch for a message that is already stored.
  #
  # The row is committed before the job is queued, so an attempt that failed in between
  # (the job transport is its own Redis, and it goes down on its own schedule) leaves a
  # message that will never be asked for again: every retry finds the stored source_id
  # and reports a duplicate. So the duplicate path comes back through here, and this
  # stands down when the bytes are already attached or the fetch has given up.
  def self.fetch_media_for(message, inbound)
    media = media_in(inbound)
    # A media message with no reference has no bytes to collect yet, and asking for them
    # here would ask on behalf of every file that is gone for good as well. The failure
    # that follows this message is what knows the difference, and Handlers::
    # MediaDownloadFailed queues the fetch for the one file worth asking about.
    return if media.nil? || media.ref.blank?
    return if message.attachments.any? || Whatsapp::Session::Inbound::MessageAttributes.given_up?(message)

    Whatsapp::Session::HistoryMedia.route(message, inbound, media)
  end

  # Replaces the placeholder a message left behind with the message itself.
  #
  # A message the backend could not decrypt in time is published as an unsupported
  # placeholder carrying the real message's id, and the message that finally arrives
  # carries that same id -- so it reaches Chatwoot as a duplicate of its own placeholder.
  # The content is the part that was missing, so the content is what is written over, in
  # the row that is already there: the bubble the agent is looking at becomes the message,
  # keeping its id, its place in the thread, and anything that quotes it.
  #
  # Answers whether it did, because a caller it says no to still has a duplicate to report.
  #
  # The media fetch is the caller's to queue, after the save and after it has announced the recovery
  # (Handlers::MessageReceived#recovered). Queued here it would sit between the content write and that
  # announcement, and a failure in between loses the announcement for good: the redelivery finds the row
  # written and comes back as a duplicate. The bytes are the other way round, repaired by that same
  # duplicate through `fetch_media_for`.
  def reconcile(message)
    written = false
    # Under the row lock and off the row the lock reloads, which is what every other
    # writer of this flag does (`Message#update_under_lock!`). `content_attributes` is
    # one JSON column: a revoke or a media failure landing between the read and the save
    # would be written away by a merge computed off the stale hash, and the eligibility
    # that was true a moment ago is exactly what such a write would have changed.
    message.with_lock do
      next unless reconcilable?(message)

      written = content_type == 'contacts' ? reconcile_as_a_share(message) : reconcile_in_place(message)
    end
    written
  end

  def reconcile_in_place(message)
    # An edit reached the row before the recovery did, and it is the newer body: the one
    # this message carries is the text that edit superseded. Everything around the body
    # is still only here, so the row takes that and keeps what it is showing.
    unless message.is_edited
      message.content = recovered_body
      attach_location(message)
    end
    settle(message)
    message.save!
    true
  end

  # A share of one contact becomes that contact, in the row that is already there.
  #
  # A share of several does not, and the reason is that the row is not the only thing a
  # message leaves behind. Chatwoot already ran this message's arrival when the
  # placeholder landed: it reopened the conversation, moved `waiting_since`, fired the
  # automations and the notifications. Writing the extra cards as new inbound rows runs
  # all of that a second time, so a conversation an agent resolved while the message was
  # late reopens itself, and the rules fire again on a message from an hour ago.
  #
  # Backdating them to the placeholder is what makes the thread read right and is also
  # what makes them unreachable: `MessageFinder` takes the latest page by `created_at`
  # and pages backwards by `id < before_id`, so a row with a fresh id and an old
  # timestamp falls out of both once twenty newer messages exist. Not backdating them
  # splits one share between its own place in the thread and the bottom of it.
  #
  # So the several-card share stays the unsupported bubble it already was, which is what
  # it was before any of this, and #488 carries what the way out would have to solve.
  #
  # A share whose cards say nothing readable is not a recovery either: `perform` stores
  # exactly the unsupported bubble for that, and this row already is one.
  def reconcile_as_a_share(message)
    cards = Array(content.contacts).select { |card| Whatsapp::Session::Inbound::ContactCard.readable?(card) }
    return false unless cards.one?
    return false unless apply_contact_card(message, cards.first)

    settle(message)
    message.save!
    true
  end

  # What the recovery settles about the row regardless of shape: the attributes the
  # message carried, and the marker that said the row was still waiting for one.
  #
  # `rich` is left out for a row an edit already settled. It describes the body, and the
  # body is not this message's to describe any more: a card drawn around text the edit
  # replaced reads worse than no card. Everything else here is about the message's place
  # rather than its content, which an edit of the body does not move.
  def settle(message)
    recovered = content_attributes.stringify_keys
    recovered = recovered.except('rich') if message.is_edited
    recovered['external_author'] = every_alias_seen(message, recovered['external_author'])
    # Written here, in the same save as the content, because it is what the announcement after it has
    # no other way to owe. Once the content is committed the row stops being reconcilable, so a
    # redelivery reads it as an ordinary duplicate and announces nothing -- and the announcement is the
    # one thing a redelivery cannot repair on its own (#646).
    #
    # A debt and not a history: the handler takes it off as soon as the announcement is enqueued, so
    # a row that owes nothing announces nothing. Keeping it would mean every later redelivery
    # re-evaluated the rules against whatever the row says by then, and an edit landing in between
    # would run rules on a body they never matched -- a reply to the contact that no arrival and no
    # recovery asked for.
    #
    # It names the body it owes the announcement for, as a fingerprint taken here and never rebuilt. The
    # redelivery that pays the debt is a different delivery and must not work it out from its own
    # payload: `message_content` resolves mentions against the contacts as they are now, so a contact
    # renamed in between would produce a different string for a message nobody edited, and the debt
    # would be settled announcing nothing.
    #
    # Of what this delivery recovered, not of what the row is about to show. An edit that got here first
    # keeps its own body above, and fingerprinting that would have the redelivery announce the editor's
    # text as recovered content -- the arrival's rules answering about a body no recovery ever carried,
    # which is the whole of #661.
    #
    # Two keys off one digest, and the second outlives the first. The debt says an announcement is owed and
    # comes off the moment one is enqueued; `RECOVERED_BODY` says the body on this row came from a recovery,
    # which stays true afterwards and is what a later write-back reads to know whether the body it just
    # restored is that one (#666).
    recovered[Message::RECOVERED_BODY] = Digest::SHA256.hexdigest(recovered_body.to_s)
    recovered[RECOVERY_OWED] = { 'at' => Time.current.to_i, 'body' => recovered[Message::RECOVERED_BODY] }

    message.content_attributes = message.content_attributes.merge(recovered.compact)
                                        .except('is_unsupported', 'unsupported_reason')
  end

  # The union of what the placeholder was told and what the message itself carries. The
  # contract lets each of them name the author by one alias, and they need not be the
  # same one, so a plain merge of the two hashes would drop whichever the recovery did
  # not repeat -- and a later deletion naming that one would be back to asking the
  # contact, which is the question this field exists to stop asking.
  def every_alias_seen(message, recovered)
    seen = message.content_attributes['external_author'].to_h.merge(recovered.to_h)

    seen.compact.presence
  end

  # The body this delivery carries, and so the body a recovery of it speaks of (#661). Not the body the
  # row ends up showing: an edit that reached the row first keeps its own (`reconcile_in_place`), and
  # whether the two say the same thing is exactly what the reader of that announcement has to be able to
  # ask. Read again by the redelivery that pays an announcement debt, which is the same message and
  # therefore carries the same body.
  # Worked out once and kept: it is the body that gets written, the body the debt is fingerprinted on and
  # the body the announcement names, and `message_content` resolves mentions against the contacts as they
  # are now. Three calls are three chances for a rename landing between them to make those three disagree,
  # which reads downstream as a message somebody edited.
  def recovered_body
    return @recovered_body if defined?(@recovered_body)

    @recovered_body = content_type == 'contacts' ? single_card_line : message_content
  end

  def perform
    return build_contact_messages if content_type == 'contacts'

    message = conversation.messages.build(content: message_content, **message_attributes)
    attach_location(message)
    # Not for an imported message: a history batch holds the chat for hundreds of messages,
    # and a download each would hold it for all their files. The fetch below collects those.
    Whatsapp::Session::Inbound::MediaAttachment.download(message, inbound) unless imported
    message.save!
    enqueue_media_fetch(message)
    acknowledge([message])
    message
  end

  private

  def inbox = conversation.inbox
  def content = inbound.content
  def incoming? = inbound.incoming?

  # The kind of content, as the string the contract names it by. Never as a class: a
  # class captured before a reload no longer matches the payload's own, and every branch
  # below would fall through in silence.
  def content_type = content&.wire_type

  def message_attributes
    attributes = {
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      source_id: inbound.id,
      sender: incoming? ? sender : nil,
      message_type: incoming? ? :incoming : :outgoing,
      # WhatsApp already has an echo: it is the phone reporting what it sent. Leaving it
      # at the default `sent` would show the agent a message stuck on one tick that no
      # receipt is ever going to move.
      status: incoming? ? :sent : :delivered,
      content_attributes: content_attributes
    }
    # Dated to when it was sent, not to when it was filed. The thread renders in
    # `created_at` order, so an import written at today's timestamp would stack a year of
    # conversation on top of this morning's, in whatever order it was imported. It is also
    # the clock Inbound::Coverage reads to decide what a later import already had eyes on.
    attributes[:created_at] = inbound.sent_at if imported
    attributes
  end

  def message_content
    case content_type
    when 'text' then convert_mentions(content.body)
    when 'media' then content.caption
    # In the account's language: a catalog card's text is written from its data here, and
    # this runs in Sidekiq, whose locale is the installation's default.
    when 'rich' then I18n.with_locale(inbox.account.locale) { content.preview_text }
    end
  end

  # Built here and read by the recovery too, so a placeholder that later receives its
  # message settles under the same attributes the writing path would have given it.
  def attributes
    @attributes ||= Whatsapp::Session::Inbound::MessageAttributes.new(inbound: inbound, imported: imported)
  end

  def content_attributes = attributes.to_h
  def unsupported? = attributes.unsupported?

  # The reasons a message may still arrive under the id its placeholder was published
  # with. `unknown_type` and `masked` are not among them: the first is a body that did
  # arrive and this build has no arm for, and the second is one WhatsApp withholds from
  # every linked device on purpose.
  #
  # `unavailable` is here because it is the one that recovers on its own: WhatsApp answers
  # a companion device that way for a view-once photo and asks the primary phone to
  # forward it.
  RECOVERABLE = %w[undecryptable unavailable].freeze

  # Only a placeholder is replaced, and only by something that is not one.
  #
  # Read from the reason and not from `is_unsupported`, because that flag answers a
  # different question: `MediaFetchJob#give_up`, `MediaDownloadFailed` and the outbound
  # sender all raise it on messages that arrived intact, and writing content over one of
  # those would clear a failure the agent is looking at and ask for the bytes again.
  #
  # An edit that landed first leaves this marker where it is: `MessageEdited#apply` takes
  # only `is_unsupported` off, so the row stays eligible and the delayed recovery still
  # lands on it, which is the point -- everything the message carried around the body is
  # still only on the recovery. What stops it from writing the original body over an edit
  # of it is the `unless message.is_edited` guard in `reconcile_in_place`, and the marker
  # comes off in `settle`, on the recovery itself. The edit costs that recovery the `rich`
  # attributes alone, because they describe a body it replaced; the quoted link is taken
  # like any other, and the attribution the caller records either way. #492.
  #
  def reconcilable?(message)
    RECOVERABLE.include?(message.content_attributes['unsupported_reason']) &&
      content.present? && !unsupported?
  end

  def convert_mentions(text)
    return text if text.blank? || inbound.mentions.blank?

    Whatsapp::MentionConverterService.convert_incoming_mentions(
      text, { mentionedJid: Array(inbound.mentions).map(&:to_jid) }, inbox.account, inbox
    )
  end

  # Location carries no downloadable bytes: the coordinates are the attachment.
  def attach_location(message)
    return unless content_type == 'location'

    name = [content.name, content.address].compact_blank.join(', ')
    message.attachments.build(
      account_id: inbox.account_id,
      file_type: :location,
      coordinates_lat: content.latitude,
      coordinates_long: content.longitude,
      fallback_title: name.presence
    )
  end

  # A rich card carries its header image, video or document in `media`, which is the
  # same downloadable reference a plain media message has: without this the card is
  # stored with its text and no attachment.
  def enqueue_media_fetch(message) = self.class.fetch_media_for(message, inbound)

  # One message per shared contact, each with a native contact attachment, so the
  # dashboard renders them in the contact bubble instead of as plain text.
  # One transaction for the whole share, as the Cloud path wraps its own message
  # creation: a card failing to save after its siblings were committed would leave the
  # event's source id stored, and the redelivery would then be read as a duplicate and
  # drop the cards that never landed.
  def build_contact_messages
    messages = ActiveRecord::Base.transaction do
      Array(content.contacts).filter_map { |card| build_contact_message(card) }
    end
    return acknowledge(messages).last if messages.present?

    unsupported_contact_message
  end

  # Tells WhatsApp the message was received, which is what puts the second tick on the
  # contact's screen and, when the inbox asks for it, marks the chat read. The Baileys
  # and Z-API writers both do this for every incoming row; without it every message this
  # layer stores stays unread on the contact's phone forever.
  def acknowledge(messages)
    # Never for an import. These are messages the contact sent long ago, or while nobody
    # was watching, and reading them is an agent's act: acknowledging on their behalf puts
    # the second tick on the contact's screen for a message no human has opened, and with
    # `mark_as_read` on it empties the unread badge of the whole chat on the phone.
    return messages if imported
    return messages unless incoming? && messages.present?

    inbox.channel.received_messages(messages, conversation)
    messages
  rescue Whatsapp::Session::Errors::NotSupported
    # The backend cannot acknowledge, or has not shipped yet. Storing the message is what
    # matters; the tick on the contact's screen is not worth failing the event over.
    messages
  end

  # An empty share, or one whose cards carry no name, no phone and no vCard, leaves
  # nothing to render, but the conversation has already been opened by the caller and
  # nothing would hold the inbound source id: the thread would sit empty and every
  # redelivery would walk the same path again. The unsupported bubble is what the agent
  # should see anyway, and storing it is what closes the deduplication.
  def unsupported_contact_message
    attributes = message_attributes
    attributes[:content_attributes] = attributes[:content_attributes].merge(is_unsupported: true)
    message = conversation.messages.create!(content: nil, **attributes)
    acknowledge([message])
    message
  end

  def build_contact_message(card)
    message = apply_contact_card(conversation.messages.build(**message_attributes), card)
    return if message.nil?

    message.save!
    message
  end

  # Fills a row, new or already stored, with one card. Answers nil for a card that says
  # nothing, which is what keeps an empty one from taking a row.
  # The line a share of exactly one readable card is stored as, which is what `reconcile_as_a_share`
  # writes and therefore what a recovery of that share is about. Nothing for a share of several or of
  # none: that one stays the unsupported bubble it already was, and recovers nothing.
  def single_card_line
    cards = Array(content.contacts).select { |card| Whatsapp::Session::Inbound::ContactCard.readable?(card) }
    return unless cards.one?

    name, phone = card_identity(cards.first)
    Whatsapp::Session::Inbound::ContactCard.line(name, phone) if phone.present? || name.present?
  end

  # `display_name` is what the contract calls it. Reading `name` found nothing, so a
  # card with a phone lost its name and a name-only card was dropped entirely, leaving
  # the conversation that had just been opened with no message in it. Both fields are
  # optional on the wire and a card may arrive as nothing but its vCard, which is why
  # that is read too rather than dropping the share.
  def card_identity(card)
    card = card.to_h.stringify_keys

    [card['display_name'].presence || Whatsapp::Session::Inbound::ContactCard.name_in(card['vcard']),
     card['phone'].presence || Whatsapp::Session::Inbound::ContactCard.phone_in(card['vcard'])]
  end

  def apply_contact_card(message, card)
    name, phone = card_identity(card)
    return if phone.blank? && name.blank?

    message.content = Whatsapp::Session::Inbound::ContactCard.line(name, phone)
    message.attachments.build(
      account_id: inbox.account_id, file_type: :contact,
      fallback_title: phone || name, meta: { firstName: name }.compact
    )
    message
  end
end
