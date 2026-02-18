# Business profile, phone number, and commerce settings management via YCloud API.
# https://docs.ycloud.com/reference/whatsapp-phone-numbers
module Whatsapp::Ycloud
  class ProfileService
    pattr_initialize [:whatsapp_channel!]

    # --- Phone Numbers ---

    # List all registered phone numbers.
    def list_phone_numbers(page: 1, limit: 20)
      client.get('/whatsapp/phoneNumbers', page: page, limit: limit)
    end

    # Retrieve a specific phone number by ID.
    def get_phone_number(phone_number_id)
      client.get("/whatsapp/phoneNumbers/#{phone_number_id}")
    end

    # Register a phone number.
    # @param params [Hash]:
    #   - wabaId [String] WhatsApp Business Account ID
    #   - phoneNumber [String] Phone number to register
    #   - pin [String] Two-step verification PIN
    def register_phone_number(params)
      client.post('/whatsapp/phoneNumbers/register', params)
    end

    # --- Business Profile ---

    # Retrieve business profile for a phone number.
    def get_business_profile(phone_number_id)
      client.get("/whatsapp/phoneNumbers/#{phone_number_id}/profile")
    end

    # Update business profile.
    # @param params [Hash]:
    #   - about [String] About/description text
    #   - address [String] Business address
    #   - description [String] Business description
    #   - email [String] Business email
    #   - vertical [String] Industry category
    #   - websites [Array<String>] Website URLs
    #   - profilePictureUrl [String] Profile photo URL
    def update_business_profile(phone_number_id, params)
      client.patch("/whatsapp/phoneNumbers/#{phone_number_id}/profile", params)
    end

    # Update the display name for a phone number (requires Meta approval).
    def update_display_name(phone_number_id, display_name)
      client.patch("/whatsapp/phoneNumbers/#{phone_number_id}/display-name", { displayName: display_name })
    end

    # --- Phone Number Settings ---

    # Retrieve phone number settings.
    def get_settings(phone_number_id)
      client.get("/whatsapp/phoneNumbers/#{phone_number_id}/settings")
    end

    # Save phone number settings.
    def update_settings(phone_number_id, params)
      client.post("/whatsapp/phoneNumbers/#{phone_number_id}/settings", params)
    end

    # --- Commerce Settings ---

    # Retrieve commerce settings for a phone number.
    def get_commerce_settings(phone_number_id)
      client.get("/whatsapp/phoneNumbers/#{phone_number_id}/commerce-settings")
    end

    # Update commerce settings (enable/disable catalog, etc.).
    def update_commerce_settings(phone_number_id, params)
      client.patch("/whatsapp/phoneNumbers/#{phone_number_id}/commerce-settings", params)
    end

    private

    def client
      @client ||= ApiClient.new(whatsapp_channel: whatsapp_channel)
    end
  end
end
