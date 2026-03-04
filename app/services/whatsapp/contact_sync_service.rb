# Processes WhatsApp Business App contact sync webhooks (Coexistence feature).
# Receives smb_app_state_sync webhooks with the business's WhatsApp contacts,
# and creates or updates Contact records in AirysChat.
#
# Triggers:
#   - Initial sync: when solution provider requests contacts via POST /smb_app_data
#   - Ongoing: when business adds, edits, or removes a contact in the WhatsApp Business App
#
# Reference: https://developers.facebook.com/documentation/business-messaging/whatsapp/embedded-signup/onboarding-business-app-users
class Whatsapp::ContactSyncService
  def initialize(inbox:, params:)
    @inbox = inbox
    @channel = inbox.channel
    @account = inbox.account
    @params = params
  end

  def perform
    state_sync_data = extract_state_sync_data
    return if state_sync_data.blank?

    state_sync_data.each do |entry|
      process_contact_entry(entry)
    end
  end

  private

  def extract_state_sync_data
    @params.dig(:entry, 0, :changes, 0, :value, :state_sync) ||
      @params.dig(:entry, 0, 'changes', 0, 'value', 'state_sync')
  end

  # Reads a key from a hash that may have string or symbol keys
  def flexible_get(hash, key)
    hash[key.to_sym] || hash[key.to_s]
  end

  def process_contact_entry(entry)
    contact_data = flexible_get(entry, :contact)
    return if contact_data.blank?

    phone_number = flexible_get(contact_data, :phone_number)
    return if phone_number.blank?

    normalized_phone = phone_number.start_with?('+') ? phone_number : "+#{phone_number}"

    route_contact_action(flexible_get(entry, :action), contact_data, normalized_phone)
  rescue StandardError => e
    Rails.logger.warn "[WHATSAPP COEXISTENCE] Error syncing contact: #{e.message}"
  end

  def route_contact_action(action, contact_data, phone_number)
    case action
    when 'add'
      sync_contact(contact_data, phone_number)
    when 'remove'
      Rails.logger.info "[WHATSAPP COEXISTENCE] Contact removed from Business App: #{phone_number}"
    end
  end

  def sync_contact(contact_data, phone_number)
    display_name = resolve_display_name(contact_data, phone_number)

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: phone_number.delete('+'),
      inbox: @inbox,
      contact_attributes: { name: display_name, phone_number: phone_number }
    ).perform

    return unless contact_inbox

    update_contact_name(contact_inbox.contact, display_name, phone_number)
    Rails.logger.info "[WHATSAPP COEXISTENCE] Contact synced: #{display_name} (#{phone_number})"
  end

  def resolve_display_name(contact_data, phone_number)
    flexible_get(contact_data, :full_name).presence ||
      flexible_get(contact_data, :first_name).presence ||
      phone_number
  end

  def update_contact_name(contact, display_name, phone_number)
    stripped_phone = phone_number.delete('+')
    contact.update!(name: display_name) if [phone_number, stripped_phone].include?(contact.name)
  end
end
