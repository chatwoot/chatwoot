# Handles the WhatsApp Coexistence `smb_app_state_sync` webhook: the business customer's
# contact roster delivered right after onboarding and on subsequent changes.
#
# The payload carries a clear contact structure, so we seed/update Contacts (name + phone):
#   state_sync[].contact { full_name, first_name, phone_number }, action: 'add' | 'remove'
# - action 'add'    -> create-or-update the ContactInbox/Contact (name + phone).
# - action 'remove' -> name fields are omitted; we do NOT delete Chatwoot contacts (destructive,
#   and the contact may hold live conversations). We log and ignore.
#
# Best-effort & crash-safe: any malformed entry is logged and skipped, never raised (a 500
# would make Meta retry the whole batch).
# https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/reference/smb_app_state_sync
class Whatsapp::ContactStateSyncService
  def initialize(inbox:, params:)
    @inbox = inbox
    @params = params
  end

  def perform
    value = @params.dig(:entry, 0, :changes, 0, :value) || {}
    Array(value[:state_sync]).each do |entry|
      process_entry(entry)
    end
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Contact state sync failed for inbox #{@inbox&.id}: #{e.message}")
  end

  private

  def process_entry(entry)
    return unless entry[:type] == 'contact'

    contact = entry[:contact] || {}
    if entry[:action] == 'remove'
      Rails.logger.info("[WHATSAPP] state_sync remove ignored for inbox #{@inbox.id} (#{contact[:phone_number]})")
      return
    end

    upsert_contact(contact)
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Contact state sync entry skipped for inbox #{@inbox.id}: #{e.message}")
  end

  def upsert_contact(contact)
    digits = phone_digits(contact[:phone_number])
    return if digits.blank?

    source_id = Whatsapp::PhoneNumberNormalizationService.new(@inbox)
                                                         .normalize_and_find_contact_by_provider(digits, :cloud)
    name = contact[:full_name].presence || contact[:first_name].presence || "+#{digits}"
    ContactInboxSourceIdResolver.new(
      inbox: @inbox,
      source_ids: [source_id],
      contact_attributes: { name: name, phone_number: "+#{digits}" }
    ).perform
  end

  def phone_digits(identifier)
    identifier.to_s.gsub(/\D/, '').presence
  end
end
