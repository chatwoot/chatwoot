class Whatsapp::InboundCallIdentityBuilder
  pattr_initialize [:inbox!, :params!]

  # Build the message path's source_id set plus contact attributes, so the resolver lands a call
  # on the identity that preserves conversation continuity. If the phone row already has history,
  # mixed phone+BSUID call webhooks should stay there; if only the BSUID row has history, keep that
  # continuity. Brand-new callers use the phone when Meta still provides it and the BSUID when it
  # does not.
  def perform(payload)
    contact = caller_contact(payload)
    phone = contact[:wa_id].presence || payload[:from].presence
    identifiers = [
      payload[:from_parent_user_id].presence || contact[:parent_user_id].presence,
      payload[:from_user_id].presence || contact[:user_id].presence
    ]
    source_ids = Whatsapp::IdentitySourceIdOrderer.new(inbox: inbox, phone_source_id: phone_source_id(phone), source_ids: identifiers).perform

    { source_ids: source_ids, contact_attributes: contact_attributes(contact, phone, source_ids.first) }
  end

  private

  # Normalize the wa_id the same way messaging does so a call matches its stored source_id.
  def phone_source_id(phone)
    return unless phone.to_s.match?(/\A\d{1,15}\z/)

    Whatsapp::PhoneNumberNormalizationService.new(inbox).normalize_and_find_contact_by_provider(phone.to_s, :cloud)
  end

  # The fallback name prefers the phone over the leading source_id: when an identifier leads, a
  # caller who sends no profile name would otherwise be displayed as a machine-readable value. The
  # identifier still serves as the last resort, so a BSUID-only caller is not left unnamed.
  def contact_attributes(contact, phone, fallback_identifier)
    name = contact.dig(:profile, :name).presence || phone.presence || fallback_identifier
    return { name: name } unless phone.to_s.match?(/\A\d{1,15}\z/)

    formatted = "+#{phone}"
    { name: name == phone ? formatted : name, phone_number: formatted }
  end

  # Match the contacts entry to THIS caller so batched payloads don't borrow another's identity.
  def caller_contact(payload)
    Array(params[:contacts]).map(&:with_indifferent_access).find do |c|
      identifier_match?(c[:wa_id], payload[:from]) ||
        identifier_match?(c[:user_id], payload[:from_user_id]) ||
        identifier_match?(c[:parent_user_id], payload[:from_parent_user_id])
    end || {}.with_indifferent_access
  end

  def identifier_match?(left, right)
    left.present? && right.present? && left.to_s == right.to_s
  end
end
