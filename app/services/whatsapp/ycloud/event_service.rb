# YCloud Custom Events system.
# Define and emit custom events for automation triggers.
# https://docs.ycloud.com/reference/custom-events
module Whatsapp::Ycloud
  class EventService
    pattr_initialize [:whatsapp_channel!]

    # --- Event Definitions ---

    # Create a custom event definition.
    # @param params [Hash]:
    #   - name [String] Event name (e.g., 'purchase_completed')
    #   - label [String] Human-readable label
    #   - description [String] Event description
    def create_definition(params)
      client.post('/custom-events/definitions', params)
    end

    # Retrieve an event definition.
    def get_definition(definition_id)
      client.get("/custom-events/definitions/#{definition_id}")
    end

    # Update an event definition.
    def update_definition(definition_id, params)
      client.patch("/custom-events/definitions/#{definition_id}", params)
    end

    # --- Property Definitions ---

    # Create a property definition for a custom event.
    # @param params [Hash]:
    #   - eventDefinitionId [String] Parent event definition ID
    #   - name [String] Property name
    #   - type [String] Property type (string, number, boolean, datetime)
    def create_property_definition(params)
      client.post('/custom-events/property-definitions', params)
    end

    # Update a property definition.
    def update_property_definition(property_id, params)
      client.patch("/custom-events/property-definitions/#{property_id}", params)
    end

    # Delete a property definition.
    def delete_property_definition(property_id)
      client.delete("/custom-events/property-definitions/#{property_id}")
    end

    # --- Emit Events ---

    # Send a custom event.
    # @param params [Hash]:
    #   - eventName [String] Event name matching a definition
    #   - contact [Hash] Contact identifier { phoneNumber: '...' }
    #   - properties [Hash] Event property values
    #   - occurredAt [String] ISO 8601 timestamp
    def send_event(params)
      client.post('/custom-events', params)
    end

    private

    def client
      @client ||= ApiClient.new(whatsapp_channel: whatsapp_channel)
    end
  end
end
