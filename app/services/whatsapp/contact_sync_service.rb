class Whatsapp::ContactSyncService
  include Rails.application.routes.url_helpers

  pattr_initialize [:inbox!, :params!]

  def perform
    return unless valid_sync_event?

    sync_contacts_from_webhook
  end

  private

  def valid_sync_event?
    return false unless params.dig(:entry, 0, :changes, 0, :field) == 'smb_app_state_sync'
    return false if params.dig(:entry, 0, :changes, 0, :value, :state_sync).blank?

    true
  end

  def sync_contacts_from_webhook
    state_sync_data = params.dig(:entry, 0, :changes, 0, :value, :state_sync)

    state_sync_data.each do |sync_item|
      next unless sync_item[:type] == 'contact'

      process_contact_sync(sync_item)
    end
  end

  def process_contact_sync(sync_item)
    contact_data = sync_item[:contact]
    action = sync_item[:action]
    phone_number = contact_data[:phone_number]

    case action
    when 'add'
      create_or_update_contact(contact_data, phone_number)
    when 'remove'
      remove_contact(phone_number)
    else
      Rails.logger.warn "[WHATSAPP] Unknown contact sync action: #{action}"
    end
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Contact sync failed for #{phone_number}: #{e.message}"
  end

  def create_or_update_contact(contact_data, phone_number)
    formatted_phone = format_phone_number(phone_number)

    # Find existing contact or create new one
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: phone_number, # WhatsApp uses phone number without + as source_id
      inbox: inbox,
      contact_attributes: {
        name: contact_data[:full_name] || contact_data[:first_name] || formatted_phone,
        phone_number: formatted_phone,
        additional_attributes: {
          whatsapp_contact_synced: true,
          whatsapp_contact_sync_timestamp: Time.current.to_i,
          whatsapp_contact_first_name: contact_data[:first_name],
          whatsapp_contact_full_name: contact_data[:full_name]
        }
      }
    ).perform

    Rails.logger.info "[WHATSAPP] Contact synced: #{contact_data[:full_name]} (#{formatted_phone})"
    contact_inbox
  end

  def remove_contact(phone_number)
    # Find the contact inbox for this phone number
    contact_inbox = inbox.contact_inboxes.find_by(source_id: phone_number)

    if contact_inbox
      # Mark contact as removed from WhatsApp Business App (don't delete to preserve conversation history)
      contact = contact_inbox.contact
      contact.additional_attributes ||= {}
      contact.additional_attributes[:whatsapp_contact_synced] = false
      contact.additional_attributes[:whatsapp_contact_removed_timestamp] = Time.current.to_i
      contact.save!

      Rails.logger.info "[WHATSAPP] Contact marked as removed: #{contact.name} (#{phone_number})"
    else
      Rails.logger.warn "[WHATSAPP] Contact not found for removal: #{phone_number}"
    end
  end

  def format_phone_number(phone_number)
    # Ensure phone number starts with +
    phone_number.start_with?('+') ? phone_number : "+#{phone_number}"
  end
end
