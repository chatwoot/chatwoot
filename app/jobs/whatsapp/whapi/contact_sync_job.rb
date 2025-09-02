class Whatsapp::Whapi::ContactSyncJob < ApplicationJob
  queue_as :low
  retry_on StandardError, wait: 1.minute, attempts: 3

  def perform(contact_id, phone_number)
    contact = Contact.find_by(id: contact_id)
    return unless contact

    # Find the WhatsApp channel through contact_inboxes
    whatsapp_inbox = contact.inboxes.where(channel_type: 'Channel::Whatsapp').first
    return unless whatsapp_inbox
    
    whatsapp_channel = whatsapp_inbox.channel

    service = Whatsapp::Providers::WhapiService.new(whatsapp_channel: whatsapp_channel)
    contact_info = service.fetch_contact_info(phone_number)
    
    if contact_info
      update_attributes = {}
      
      # Update name if WHAPI has a better name
      update_attributes[:name] = contact_info[:name] if contact_info[:name].present?
      
      # Add business name if available
      if contact_info[:business_name].present?
        update_attributes[:additional_attributes] = (contact.additional_attributes || {}).merge(
          business_name: contact_info[:business_name]
        )
      end
      
      # Update contact if we have new information
      contact.update!(update_attributes) if update_attributes.any?
      
      # Schedule avatar update if available
      if contact_info[:avatar_url].present?
        ::Avatar::AvatarFromUrlJob.perform_later(contact, contact_info[:avatar_url])
      end
      
      Rails.logger.debug "ContactSyncJob: Updated contact #{contact_id} with WHAPI info"
    end
  rescue StandardError => e
    Rails.logger.warn "ContactSyncJob: Failed to sync contact #{contact_id}: #{e.message}"
    raise e
  end
end
