# Asks again whether a number flagged as having no WhatsApp has registered since. Runs when an
# agent opens the conversation and the flag is older than the recheck window: without it a
# stale "no WhatsApp" keeps itself alive, since the warning discourages the send whose
# delivery receipt would clear it.
#
# Messages sent while the number had no account stay undelivered either way: they had no
# device to be encrypted to. Only what is sent from now on reaches the contact.
class Whatsapp::NumberRecheckService
  pattr_initialize [:conversation!]

  # Above the 90 s a Baileys lookup may take, so the claim outlives the call it guards.
  LOCK_TIMEOUT = 100.seconds

  def perform
    return unless contact_inbox&.whatsapp_missing_recheck_due?

    # Two agents opening the same stale conversation enqueue two jobs. Only one asks the
    # provider; the other leaves, and the date cannot serve as the claim because a failed
    # lookup has to leave it untouched.
    Redis::LockManager.new.with_lock("whatsapp_number_recheck:#{contact_inbox.id}", LOCK_TIMEOUT) { recheck }
  end

  private

  def recheck
    # Re-read under the claim: a worker that held it before may have answered already.
    return unless contact_inbox.reload.whatsapp_missing_recheck_due?
    return unless number_check.answerable?

    flag_before = contact_inbox.whatsapp_missing_checked_at
    phone = contact_inbox.contact.phone_number
    return if phone.blank?

    asked_at = Time.current
    answer = number_check.lookup(phone)
    # No answer is not a "no": the flag and its date stay as the last real answer left them.
    return if answer.nil?
    return contact_inbox.mark_whatsapp_missing_for!(phone, flag_before: flag_before, asked_at: asked_at) unless answer.exists

    found_under_lock(answer.phone, phone, flag_before)
  end

  # The claim only keeps other rechecks out. A phone correction may have landed while the
  # provider was answering, so the alignment runs only if the contact still has the phone that
  # was looked up and the flag still holds what was read before asking. The contact's row lock
  # is what a phone correction waits on. A "no" goes through the same guard, plus the evidence
  # check, in ContactInbox#mark_whatsapp_missing_for!.
  def found_under_lock(canonical_phone, phone, flag_before)
    contact_inbox.contact.with_lock do
      contact_inbox.lock!
      next unless contact_inbox.contact.phone_number == phone && contact_inbox.whatsapp_missing_checked_at == flag_before

      found(canonical_phone)
    end
  end

  def contact_inbox
    @contact_inbox ||= conversation.contact_inbox
  end

  def number_check
    @number_check ||= Whatsapp::NumberCheck.new(inbox: contact_inbox.inbox)
  end

  # The same alignment a new conversation gets from ContactInboxBuilder: the contact takes the
  # canonical phone, and the address this thread sends to follows it when it was derived from
  # the old phone. Another contact inbox already holding the canonical address keeps it; this
  # one then stays where it was rather than breaking the unique index.
  #
  # The answer is about the phone the contact now holds, so every thread of that contact in
  # this inbox stops warning, including those of the contact a merge handed this one to. This
  # thread's own row is cleared through the instance that may have just moved its address:
  # inside one transaction Rails runs commit callbacks only for the first instance saved per
  # row, so a second instance's clear would never reach the dashboard.
  def found(canonical_phone)
    if canonical_phone.present?
      old_source_id = contact_inbox.contact.phone_number.delete('+')
      number_check.align_contact(contact_inbox.contact, canonical_phone)
      contact_inbox.reload
      move_source_id(old_source_id, canonical_phone.delete('+'))
    end
    contact_inbox.clear_whatsapp_missing!
    sibling_threads.find_each(&:clear_whatsapp_missing!)
  end

  def sibling_threads
    contact_inbox.contact.contact_inboxes.where(inbox_id: contact_inbox.inbox_id).where.not(id: contact_inbox.id)
  end

  def move_source_id(old_source_id, new_source_id)
    return unless contact_inbox.source_id == old_source_id
    return if contact_inbox.inbox.contact_inboxes.exists?(source_id: new_source_id)

    contact_inbox.update!(source_id: new_source_id)
  end
end
