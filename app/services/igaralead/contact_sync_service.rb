module Igaralead
  class ContactSyncService
    attr_reader :contact, :account

    def initialize(contact:)
      @contact = contact
      @account = contact.account
    end

    def perform
      return unless HubClient.configured?

      if contact.hub_id.present?
        update_contact_on_hub
      else
        create_contact_on_hub
      end
    rescue Faraday::Error => e
      Rails.logger.error("[Igaralead::ContactSyncService] Hub sync failed for contact #{contact.id}: #{e.message}")
    end

    private

    def create_contact_on_hub
      client = HubClient.new
      slug = account.hub_client_slug
      return if slug.blank?

      response = client.post("/c/#{slug}/contacts", body: contact_payload)
      return unless response.is_a?(Hash) && response['id'].present?

      contact.update(hub_id: response['id'], hub_synced_at: Time.current)
    end

    def update_contact_on_hub
      client = HubClient.new
      slug = account.hub_client_slug
      return if slug.blank?

      client.put("/c/#{slug}/contacts/#{contact.hub_id}", body: contact_payload)
      contact.update(hub_synced_at: Time.current)
    end

    def contact_payload
      {
        name: contact.name,
        email: contact.email,
        phone: contact.phone_number,
        contact_type: contact.contact_type,
        custom_attributes: contact.custom_attributes
      }
    end
  end
end
