# Turns a canonical Party into the ContactInbox that holds it.
#
# WhatsApp addresses the same person by LID in some chats and by phone number in
# others, and a contact can already exist under either. Every inbound path goes
# through here so that consolidation (merging a phone-keyed contact into its LID) and
# the "is this name a placeholder?" rule are decided in exactly one place.
#
# `overwrite` separates the two callers: the peer of a 1:1 chat is authoritative about
# its own phone and identifier, while a group participant is described partially and
# may only fill in what is still blank.
class Whatsapp::Session::Inbound::ContactResolver
  attr_reader :inbox, :party, :overwrite, :skip_avatar

  def initialize(inbox:, party:, overwrite: false, skip_avatar: false)
    @inbox = inbox
    @party = party
    @overwrite = overwrite
    @skip_avatar = skip_avatar
  end

  def perform
    return if party.blank? || party.source_id.blank?

    consolidate
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: source_id, inbox: inbox, contact_attributes: contact_attributes
    ).perform

    update_contact(contact_inbox.contact)
    enqueue_avatar(contact_inbox.contact)
    contact_inbox
  end

  private

  # The key the contact is already filed under, when that is one of this number's other
  # ninth-digit forms. Consolidation cannot help here: it needs a phone *and* a LID, and
  # a phone-only party has no LID to consolidate towards. Without this the builder does
  # an exact match, misses the row, and files the same person twice, with a second
  # conversation to go with it.
  def source_id
    @source_id ||= existing_variant_source_id || party.source_id
  end

  # The number as reported wins whenever it is already filed: an unordered `IN` over
  # both ninth-digit forms can hand back the other row, which files the message under
  # the wrong contact and then, with `overwrite`, tries to move the exact number onto a
  # contact that does not own it and fails the uniqueness check, losing the message.
  def existing_variant_source_id
    return if party.lid.present? || party.phone.blank?

    variants = Whatsapp::Session::PhoneMatch.variants(party.phone) - [party.phone]
    return if variants.blank?
    return if inbox.contact_inboxes.exists?(source_id: party.phone)

    inbox.contact_inboxes.where(source_id: variants).pick(:source_id)
  end

  # A contact created from a phone-keyed message keeps its own contact_inbox; when the
  # LID for the same person shows up later, this merges the two before the builder can
  # create a second contact.
  def consolidate
    return if party.phone.blank? && party.lid.blank?

    Whatsapp::ContactInboxConsolidationService.new(
      inbox: inbox, phone: party.phone, lid: party.lid, identifier: party.identifier
    ).perform
  end

  # The alternate numbers are for a contact with no contact_inbox here, which only its
  # number can find: one created by hand or through the API (#776).
  def contact_attributes
    {
      name: party.name.presence || party.phone.presence || party.lid,
      phone_number: party.phone_e164,
      phone_number_candidates: alternate_contact_phone_numbers,
      identifier: party.identifier
    }.compact
  end

  def alternate_contact_phone_numbers
    Whatsapp::PhoneNumberNormalizationService.new(inbox).alternate_contact_phone_numbers(party.phone).presence
  end

  def update_contact(contact)
    params = {
      phone_number: (party.phone_e164 if update_phone?(contact)),
      identifier: (party.identifier if update_identifier?(contact)),
      name: (party.name if update_name?(contact))
    }.compact
    contact.update!(params) if params.present?
    contact
  end

  def update_phone?(contact)
    return false if party.phone.blank?

    overwrite ? contact.phone_number != party.phone_e164 : contact.phone_number.blank?
  end

  def update_identifier?(contact)
    return false if party.identifier.blank?

    overwrite ? contact.identifier != party.identifier : contact.identifier.blank?
  end

  def update_name?(contact)
    party.name.present? && placeholder_name?(contact.name)
  end

  # A name equal to the contact's phone (in any normalized "9"-variant), to its LID or
  # to the "<lid>@lid" identifier was auto-generated, not typed by a human, so the push
  # name may replace it. Comparing normalized variants is what rescues a contact whose
  # name was stranded by phone normalization.
  def placeholder_name?(name)
    return true if name.blank?
    return true if name == party.identifier
    # Nothing but a number and the punctuation a number is written with. Stripping the
    # separators first would read "Ana 2" as the digit 2; requiring the whole name to
    # look like a phone keeps a real name out, while still catching the formatted forms
    # ("+55 41 99999-0000") a conversion or an import leaves behind.
    return false unless name.match?(/\A\+?[\d\s().-]+\z/)

    digits = Whatsapp::Session::PhoneMatch.digits(name)
    return false if digits.blank?
    return true if digits.in?([party.phone, party.lid].compact)

    party.phone.present? && Whatsapp::Session::PhoneMatch.same_number?(digits, party.phone)
  end

  def enqueue_avatar(contact)
    return if skip_avatar
    return if contact.avatar.attached?
    return unless inbox.channel.session_capabilities.include?('profile_picture')

    Whatsapp::Session::UpdateContactAvatarJob.perform_later(contact, inbox, party.to_h)
  end
end
