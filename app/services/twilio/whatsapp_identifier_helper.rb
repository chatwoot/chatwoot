module Twilio::WhatsappIdentifierHelper
  TWILIO_WHATSAPP_BSUID_SOURCE_ID_REGEX = Regexp.new("\\Awhatsapp:#{RegexHelper::WHATSAPP_BSUID_PATTERN}\\z")

  def update_twilio_whatsapp_identifiers
    return unless twilio_channel.whatsapp?

    Whatsapp::IdentifierSyncService.new(contact_inbox: @contact_inbox, contact: @contact).perform(
      source_ids: twilio_whatsapp_source_ids,
      username: params[:ProfileUsername].presence || params[:Username],
      phone_number: phone_number.presence
    )
  end

  def twilio_whatsapp_phone_source?
    params[:From].to_s.match?(/\Awhatsapp:\+\d{1,15}\z/)
  end

  def twilio_whatsapp_bsuid
    params[:ExternalUserId].presence || twilio_whatsapp_bsuid_source_id
  end

  def twilio_whatsapp_display_identifier
    twilio_whatsapp_bsuid.to_s.delete_prefix('whatsapp:').presence
  end

  def twilio_whatsapp_source_ids
    [
      twilio_whatsapp_phone_source_id,
      twilio_whatsapp_source_id(params[:ExternalUserId].presence) || twilio_whatsapp_bsuid_source_id,
      twilio_whatsapp_source_id(params[:ParentExternalUserId].presence)
    ].compact_blank.uniq
  end

  def twilio_whatsapp_primary_source_id
    twilio_whatsapp_source_ids.first
  end

  def twilio_whatsapp_phone_source_id
    return if phone_number.blank?

    Whatsapp::PhoneNumberNormalizationService.new(inbox).normalize_and_find_contact_by_provider("whatsapp:#{phone_number}", :twilio)
  end

  def twilio_whatsapp_source_id(identifier)
    identifier = identifier.to_s
    return if identifier.blank?

    "whatsapp:#{identifier.delete_prefix('whatsapp:')}"
  end

  def twilio_whatsapp_bsuid_source_id
    from = params[:From].to_s
    return from if from.match?(TWILIO_WHATSAPP_BSUID_SOURCE_ID_REGEX)
  end

  def twilio_contact_inbox(source_id)
    ContactInboxSourceIdResolver.new(
      inbox: inbox,
      source_ids: twilio_contact_inbox_source_ids(source_id),
      contact_attributes: contact_attributes
    ).perform
  end

  def twilio_contact_inbox_source_ids(source_id)
    return [source_id] unless twilio_channel.whatsapp?

    twilio_whatsapp_source_ids.presence || [source_id]
  end
end
