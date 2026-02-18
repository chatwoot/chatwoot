# WhatsApp Flows management via YCloud API.
# Flows are interactive forms/mini-apps within WhatsApp conversations.
# https://docs.ycloud.com/reference/whatsapp-flows
module Whatsapp::Ycloud
  class FlowService
    pattr_initialize [:whatsapp_channel!]

    # Create a new flow (starts in DRAFT state).
    # @param params [Hash]:
    #   - name [String] Flow name
    #   - wabaId [String] WhatsApp Business Account ID
    #   - categories [Array<String>] e.g., ['CUSTOMER_SUPPORT', 'SURVEY']
    #   - flowJson [String] (optional) JSON structure for single-request creation
    #   - publish [Boolean] (optional) Auto-publish after creation
    def create(params)
      client.post('/whatsapp/flows', params)
    end

    # List all flows.
    # @param page [Integer] Page number
    # @param limit [Integer] Items per page
    def list(page: 1, limit: 20)
      client.get('/whatsapp/flows', page: page, limit: limit)
    end

    # Retrieve a specific flow by ID.
    def retrieve(flow_id)
      client.get("/whatsapp/flows/#{flow_id}")
    end

    # Update flow metadata (name, categories, endpoint URI).
    def update_metadata(flow_id, params)
      client.patch("/whatsapp/flows/#{flow_id}/metadata", params)
    end

    # Update flow structure (the JSON definition).
    def update_structure(flow_id, params)
      client.patch("/whatsapp/flows/#{flow_id}/structure", params)
    end

    # Delete a draft flow.
    def delete(flow_id)
      client.delete("/whatsapp/flows/#{flow_id}")
    end

    # Publish a draft flow (makes it available for use).
    def publish(flow_id)
      client.post("/whatsapp/flows/#{flow_id}/publish")
    end

    # Deprecate a published flow (stops new interactions).
    def deprecate(flow_id)
      client.post("/whatsapp/flows/#{flow_id}/deprecate")
    end

    # Generate a web preview URL for testing a flow.
    def preview(flow_id)
      client.get("/whatsapp/flows/#{flow_id}/preview")
    end

    private

    def client
      @client ||= ApiClient.new(whatsapp_channel: whatsapp_channel)
    end
  end
end
