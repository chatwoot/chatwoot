# Someone reacted to a message, or took their reaction back.
class Whatsapp::Session::Inbound::Handlers::MessageReaction < Whatsapp::Session::Inbound::Handlers::Base
  def perform
    return :ignored unless actionable?

    inbound::Locks.with_chat_lock(inbox, chat_lock_ids) do
      payload.removal? ? remove : add
    end
  end

  private

  def actionable?
    return false if ignorable_chat?(payload.chat)
    return capability?(:groups) if payload.chat.group?

    true
  end

  # Checked before the sender is resolved: resolving creates a Contact, a ContactInbox
  # and an avatar job, and a removal aimed at a reaction this sender never made has
  # nothing to remove. Without this, every stray removal leaves a contact behind, which
  # is why the lookup here is the non-creating one.
  #
  # Nothing recorded at all is the out-of-order case rather than the stray one, and it is
  # the half of it that deferring the *add* cannot cover: a removal that ran first would
  # be dropped here, and the add behind it would then write a reaction the sender has
  # already taken back, which nothing later corrects. A row that exists and is already
  # gone is the ordinary echo of a removal made here, and answers itself.
  def remove
    known = payload.from_me ? nil : inbound::ContactLookup.contact(inbox: inbox, party: peer_party)
    return :deferred unless recorded?(known)

    unless inbound::ReactionStore.active?(inbox: inbox, target_id: payload.target_id, sender: known, from_me: payload.from_me)
      # Nothing to take away, but the removal still dates the last one: a reaction replayed
      # after it, off the ordered stream, is measured against this.
      store(known).note_removal
      return :ignored
    end

    store(sender_contact).remove ? :handled : :ignored
  end

  # No contact says the same thing as no row: the add is what resolves one, so a removal
  # that finds nobody arrived before the reaction it takes back.
  def recorded?(known)
    return false if known.nil? && !payload.from_me

    inbound::ReactionStore.recorded?(inbox: inbox, target_id: payload.target_id,
                                     sender: known, from_me: payload.from_me)
  end

  def add
    return :duplicate if find_message(payload.id)

    # A reaction Chatwoot sent reserves its id like any other message, so a lost send
    # response makes the echo arrive under an id we never stored. The reservation is
    # what identifies it, on its own and before any contact is resolved; writing again
    # would leave two reactions on the same bubble.
    return :handled if inbound::EchoMatcher.new(inbox: inbox, message_id: payload.id).perform

    # The reaction belongs in the thread holding the message it annotates, and that is
    # checked before anybody is resolved: resolving creates a Contact, a ContactInbox and
    # an avatar job, and a reaction whose target was never stored has nothing to annotate.
    # It is never given a thread of its own to live in; on an unordered transport it waits
    # for the message instead, and is dropped only once the retries are spent.
    target = find_message(payload.target_id)
    return :deferred if target.nil?

    contact_inbox = resolve_contact_inbox
    return :ignored if contact_inbox.nil? || silenced?(contact_inbox.contact)

    written = store(reactor(contact_inbox)).write(target.conversation)
    # nil when a newer reaction from the same sender is already on the bubble, which is
    # what an emoji swap looks like when its two halves arrive the wrong way round.
    written.nil? ? :ignored : :handled
  end

  # Who the reaction is filed under: the contact of a 1:1 chat, the author in a group.
  def reactor(contact_inbox) = payload.chat.group? ? sender_contact : contact_inbox.contact

  # Whatsapp::BlockedSender, in a 1:1 chat only: in a group the contact resolved here is the
  # group itself.
  def silenced?(contact) = !payload.chat.group? && Whatsapp::BlockedSender.silenced?(contact, from_me: payload.from_me)

  def store(sender)
    inbound::ReactionStore.new(inbox: inbox, reaction: payload, sender: sender)
  end

  def resolve_contact_inbox
    return group_result&.group_contact_inbox if payload.chat.group?

    inbound::ContactResolver.new(inbox: inbox, party: peer_party, overwrite: true).perform
  end

  def sender_contact
    return nil if payload.from_me

    payload.chat.group? ? group_result&.sender_contact : resolve_contact_inbox&.contact
  end

  def group_result
    @group_result ||= inbound::GroupResolver.new(inbox: inbox, group: payload.chat, sender: payload.sender).perform
  end

  def peer_party
    return payload.sender if !payload.from_me && payload.sender.present?

    model::Party.from_address(payload.chat)
  end

  # Same aliasing as an inbound message: the peer is named by phone in one event and by
  # LID in the next, and both have to serialize against each other.
  def chat_lock_ids
    return [payload.chat.id] if payload.chat.group?

    # Every ninth-digit form as well: WhatsApp reports a Brazilian or Argentinian line
    # with or without the extra digit, `ContactResolver` files both under one contact,
    # and two keys differing by that digit would not serialize against each other.
    [payload.chat.id, peer_party&.lid, *Whatsapp::Session::PhoneMatch.variants(peer_party&.phone)]
  end
end
