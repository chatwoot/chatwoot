require 'httparty'

class AiAgents::FlowiseService
  include HTTParty
  base_uri 'https://ai.radyalabs.id/api/v1'

  class << self
    def load_chat_flow(name:, flow_data:, is_public: false, deployed: false, type: 'CHATFLOW')
      raise ArgumentError, 'Template cannot be nil' if flow_data.nil?

      response = post(
        '/chatflows',
        body: {
          'name' => name,
          'flowData' => flow_data.to_json,
          'isPublic' => is_public,
          'deployed' => deployed,
          'type' => type
        }.to_json,
        headers: headers
      )

      raise "Error loading chat flow: #{response.code} #{response.message}" unless response.success?

      response.parsed_response
    end

    def delete_chat_flow(id:)
      response = delete("/chatflows/#{id}", headers: headers)

      raise "Error deleting chat flow: #{response.code} #{response.message}" unless response.success?

      response.parsed_response
    end

    private

    def headers
      {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'Authorization' => 'Bearer d3YPZUOXkeq3xHy105Km7SeGerjsATPQ7M9sAFT9lSE='
      }
    end
  end
end
