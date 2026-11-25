# Asks an inbox's paired session whether a phone number has a WhatsApp account, and lines a
# contact up with the number WhatsApp knows it by.
#
# WhatsApp matches the canonical phone for an account, but a paired session requires the
# exact number registered there. For Brazilian mobile numbers the leading "9" may or may not
# be present in the user-typed value, and sending to the wrong variant fails silently. A
# number with no account at all fails the same way: the server acknowledges the message (one
# check) and nobody ever receives it.
class Whatsapp::NumberCheck
  # `exists` is what WhatsApp answered; `phone` is the canonical number ("+<digits>") when it
  # found one.
  Answer = Struct.new(:exists, :phone, keyword_init: true)

  pattr_initialize [:inbox!]

  # A session inbox answers through its paired session, so with the session not open (never
  # paired, dropped, still connecting) nobody can answer: the check would only wait out its
  # timeout before falling back to the typed number anyway, and long enough to take the
  # request down with it (#838). Baileys reports its connection elsewhere and keeps its own
  # HTTP timeout, so it is left as it was.
  def answerable?
    channel = inbox.channel
    return true unless channel.session_provider?

    channel.provider_connection.to_h['connection'] == 'open'
  end

  # nil when there is no answer: the provider failed, timed out or cannot check numbers.
  # Callers treat that as "unknown", never as "no". `deadline` as in the providers' on_whatsapp.
  def lookup(phone_number, deadline: :provider)
    response = inbox.channel.on_whatsapp(phone_number, deadline: deadline)
    return unless response.is_a?(Hash)
    return Answer.new(exists: false) unless response['exists']

    jid_digits = response['jid'].to_s.split('@').first
    Answer.new(exists: true, phone: jid_digits.present? ? "+#{jid_digits}" : nil)
  rescue StandardError => e
    Rails.logger.warn("[WHATSAPP] number check via on_whatsapp failed (ignored): #{e.class.name}: #{e.message}")
    nil
  end

  # Returns the contact that now holds the canonical phone: the same one, updated, or the
  # contact that already had that phone, with this one merged into it. Write and merge errors
  # surface, so the caller never carries on with half-applied state.
  def align_contact(contact, canonical_phone)
    return contact if canonical_phone == contact.phone_number

    existing = inbox.account.contacts.where.not(id: contact.id).find_by(phone_number: canonical_phone)
    return ContactMergeAction.new(account: inbox.account, base_contact: existing, mergee_contact: contact).perform if existing

    contact.update!(phone_number: canonical_phone)
    contact
  end
end
