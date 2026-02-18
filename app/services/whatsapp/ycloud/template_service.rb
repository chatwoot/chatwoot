# Full CRUD for WhatsApp message templates via YCloud API.
# https://docs.ycloud.com/reference/whatsapp-templates
module Whatsapp::Ycloud
  class TemplateService
    pattr_initialize [:whatsapp_channel!]

    # Create a new message template.
    # @param params [Hash] Template params:
    #   - name [String] Template name (lowercase, underscores only)
    #   - language [String] Language code (e.g., 'en_US')
    #   - category [String] AUTHENTICATION | UTILITY | MARKETING
    #   - components [Array] Array of component hashes (HEADER, BODY, FOOTER, BUTTONS)
    #   - wabaId [String] (optional) WhatsApp Business Account ID
    def create(params)
      client.post('/whatsapp/templates', params)
    end

    # List templates with pagination.
    # @param page [Integer] Page number (1-based)
    # @param limit [Integer] Items per page (max 100)
    # @return [HTTParty::Response]
    def list(page: 1, limit: 100)
      client.get('/whatsapp/templates', page: page, limit: limit)
    end

    # Retrieve a specific template by name and language.
    def retrieve(name, language)
      client.get("/whatsapp/templates/#{name}/#{language}")
    end

    # Edit/update an existing template.
    # Only templates in APPROVED or REJECTED status can be edited.
    # @param name [String] Template name
    # @param language [String] Language code
    # @param params [Hash] Fields to update (components, category, etc.)
    def update(name, language, params)
      client.patch("/whatsapp/templates/#{name}/#{language}", params)
    end

    # Delete all language variants of a template.
    def delete_all(name)
      client.delete("/whatsapp/templates/#{name}")
    end

    # Delete a specific template by name and language.
    def delete(name, language)
      client.delete("/whatsapp/templates/#{name}/#{language}")
    end

    private

    def client
      @client ||= ApiClient.new(whatsapp_channel: whatsapp_channel)
    end
  end
end
