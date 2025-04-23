module Stark
  module ApiHandler
    extend ActiveSupport::Concern

    included do
      AUTH_TOKEN = ENV.fetch('STARK_API_KEY', nil)
      include HTTParty
    end

    def get_stark_response(conversation, content)
      return nil unless valid_dealership_id?(conversation.account&.dealership_id)

      response = make_api_request(conversation, content)
      return handle_error_response(response) if error_response?(response)

      parse_stark_response(response)
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse Stark response: #{e.message}")
      nil
    end

    private

    def make_api_request(conversation, content)
      response = HTTParty.post(
        agent_bot.outgoing_url,
        body: build_request_payload(conversation, content).to_json,
        headers: build_request_headers
      )
      JSON.parse(response.body)
    end

    def build_request_payload(conversation, content)
      {
        question: content,
        session_id: conversation.id,
        dealership_id: conversation.account&.dealership_id
      }
    end

    def build_request_headers
      {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{AUTH_TOKEN}"
      }
    end

    def parse_stark_response(response)
      {
        'content' => response.dig('body', 'data', 'answer'),
        'action' => response.dig('body', 'data', 'human_redirect') ? 'handoff' : nil
      }
    end

    def error_response?(response)
      response['body']&.fetch('status', nil) == 'error'
    end

    def handle_error_response(response)
      error_message = response.dig('body', 'message')
      errors = response.dig('body', 'errors')
      Rails.logger.error("Stark API Error: #{error_message}, Errors: #{errors}")
      nil
    end
  end
end
