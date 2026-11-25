# A message was deleted for everyone: by the contact, or from the connected phone.
#
# A revoke that arrives before the message it points at is answered `:deferred`, which an
# unordered transport retries. Nothing is persisted in the meantime: a revoke that outlives
# the retries leaves the message on screen rather than deleting it later.
class Whatsapp::Session::Inbound::Handlers::MessageRevoked < Whatsapp::Session::Inbound::Handlers::Base
  def perform
    targets = find_messages(payload.message_id).to_a
    return :deferred if targets.empty?

    revoked = targets.select { |target| claims_the_author_of?(target) && revoke(target) == :handled }
    return :ignored if revoked.empty?

    # The conversations of the rows this actually changed, not the first row's. One id can
    # hold rows belonging to different people, and now that a claim can rule some of them
    # out, the first row is not always one of the ones that moved.
    revoked.map(&:conversation).uniq.each { |conversation| inbound::ChatList.refresh(conversation) }
    :handled
  end

  private

  def revoke(target) = payload.by_self? ? revoke_by_self(target) : revoke_by_contact(target)

  # WhatsApp addresses a message by `(id, participant)`, not by id alone, so a deletion's
  # key names an author and the phones apply nothing when that name is wrong. Any member
  # of a group can send one naming somebody who did not write the message: every phone in
  # the group goes on showing it, and this side used to mark it deleted for the agent
  # alone, who then saw a bubble nobody deleted.
  #
  # Asked per target rather than once: `find_messages` returns every row carrying that
  # source_id across the inbox, and they can belong to different people.
  #
  # A blank claim keeps exactly the old behaviour. It means the key named nobody, which is
  # every direct chat and every sender deleting their own message: there `sender` and `by`
  # already say who claimed what. A group's revoke always carries it, so a group is where
  # this decides anything.
  #
  # What it does not establish: WhatsApp also requires the revoke's sender to be that
  # author or an admin of the group, so a non-admin naming the correct author is refused
  # there and applied here. Settling that needs a group metadata round trip per deletion,
  # which the connector deliberately does not spend. #486 carries the reasoning.
  # Only a contact sender is the person WhatsApp names. An outgoing row carries the agent
  # who typed it, or nobody when it came off the phone, and WhatsApp attributes all of
  # those to the connected account: comparing an agent's user record against a claimed
  # contact would refuse every deletion of a message Chatwoot itself sent.
  def claims_the_author_of?(target)
    return true if payload.message_author.blank?

    # What the row itself recorded about who wrote it, which is the only answer that does
    # not move: an agent editing the contact's phone, or a merge rewriting it, changes
    # what the contact answers to without changing who wrote the message.
    stored = target.content_attributes['external_author']
    if stored.present?
      return true if same_party?(stored, payload.message_author)
      # A snapshot answers only in the namespaces it holds, and the contract lets an event
      # carry just one: a message that arrived naming its author by LID alone cannot say
      # anything about a claim that names them by phone alone. Unanswered, not refused,
      # or a valid deletion would be turned down by a snapshot that never knew.
      return false if answerable?(stored, payload.message_author)
    end

    # Rows written before this was recorded, or a claim the snapshot cannot speak to,
    # which have only the contact to go on.
    return claims_the_connected_account? unless target.sender.is_a?(::Contact)

    answers_to_the_claim?(target.sender)
  end

  # Whether the snapshot and the claim meet in a namespace both of them name, which is
  # what makes a mismatch a real answer rather than a gap.
  def answerable?(stored, claimed)
    (claimed.lid.present? && stored['lid'].present?) ||
      (claimed.phone.present? && stored['phone'].present?)
  end

  # One namespace at a time, for the reason `answers_to_the_claim?` gives: WhatsApp treats
  # a LID and a phone as different identities even when their digits are equal, and the
  # claim is written by whoever sent the deletion.
  def same_party?(stored, claimed)
    return true if claimed.lid.present? && stored['lid'].to_s == claimed.lid

    numbers = Whatsapp::Session::PhoneMatch.variants(claimed.phone)
    written = Whatsapp::Session::PhoneMatch.digits(stored['phone'])

    written.present? && numbers.include?(written)
  end

  # Asked of the stored author rather than resolved into one. `ContactLookup` picks a
  # single row and prefers the LID-keyed one on purpose, so while the same person still
  # holds a phone-keyed row and a LID-keyed one it answers with the copy the message does
  # not point at, and a valid deletion would be refused for that whole window.
  #
  # One namespace at a time, and never a bare digit comparison across the two. WhatsApp
  # treats a LID and a phone number as different identities even when their digits are
  # equal, and the claim is written by whoever sent the deletion: a flat set of digits
  # lets a group member name a phone whose digits are the victim's LID and walk straight
  # through this. So a LID is compared as `<digits>@lid`, which is the form both sides
  # carry, and a phone only against the number stored on the contact.
  #
  # Nothing is created, and a claim naming somebody this inbox has never seen matches
  # neither, like any other name that is not the author's.
  #
  # `ContactInbox.source_id` is deliberately not consulted, though it would survive an
  # agent editing the contact's phone or a merge rewriting it. It is bare text and the
  # table carries no namespace, so a LID and a phone are indistinguishable there, and
  # comparing it is what let a claimed phone match a victim's LID. #494 carries the
  # cost of leaving it out and the two ways to put a type on that key.
  def answers_to_the_claim?(contact)
    claimed = payload.message_author

    same_lid?(contact, claimed) || same_phone?(contact, claimed)
  end

  def same_lid?(contact, claimed)
    claimed.identifier.present? && contact.identifier == claimed.identifier
  end

  # Every ninth-digit form, because WhatsApp reports a Brazilian or Argentinian line with
  # or without the extra digit and the contact was filed under whichever came first.
  def same_phone?(contact, claimed)
    numbers = Whatsapp::Session::PhoneMatch.variants(claimed.phone)
    stored = Whatsapp::Session::PhoneMatch.digits(contact.phone_number)

    stored.present? && numbers.include?(stored)
  end

  # The pairing keys are what this session knows about itself. Compared on either, because
  # WhatsApp names the same account by phone in one event and by LID in the next.
  def claims_the_connected_account?
    claimed = payload.message_author
    paired = channel.provider_connection.to_h
    return true if claimed.lid.present? && claimed.lid.to_s == paired['lid'].to_s

    numbers = Whatsapp::Session::PhoneMatch.variants(claimed.phone)
    numbers.present? && numbers.include?(Whatsapp::Session::PhoneMatch.digits(paired['phone_number']))
  end

  # Deleted from the connected phone: same outcome as deleting it from Chatwoot, which
  # is also what the echo of a Chatwoot deletion looks like (hence the guard). Same
  # outcome means the same as the messages controller produces, attachments included:
  # leaving the files behind would keep the deleted media readable through the API and
  # in storage. The reserved id survives, so a send still in flight stays matchable.
  def revoke_by_self(target)
    return :ignored if target.deleted?

    # Under the row lock: the reserved id is read out of the hash that is about to be
    # replaced, so an echo confirming a send in between would otherwise be thrown away
    # and the message could never be taken off the contact's phone.
    target.with_lock do
      next :ignored if target.deleted?

      attributes = { 'deleted' => true, 'pending_source_id' => target.pending_source_id }.compact
      target.update!(content: I18n.t('conversations.messages.deleted'), content_type: :text,
                     content_attributes: attributes)
      target.attachments.destroy_all
      :handled
    end
  end

  # The contact deleted it: keep the stored content and only flag it, so the agent can
  # still read what was said while the UI marks it as deleted.
  def revoke_by_contact(target)
    return :ignored if target.deleted_by_contact

    # `deleted_by_contact` lives in the content_attributes JSON, so writing it off a
    # stale instance rewrites the whole hash.
    target.update_under_lock!(deleted_by_contact: true)
    :handled
  end
end
