module Stark
  module ApiHandler
    extend ActiveSupport::Concern

    included do
      AUTH_TOKEN = ENV.fetch('STARK_API_KEY', nil)
      include HTTParty
      include StarkRetryable
    end

    def get_stark_response(conversation, content)
      return nil unless valid_dealership_id?(conversation.account&.dealership_id)

      with_stark_retry(conversation) do
        response = make_api_request(conversation, content)

        return nil if response.nil?
        return handle_error_response(response) if error_response?(response)

        parse_stark_response(response)
      end
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

      parse_response_body(response)
    end

    def parse_response_body(response)
      return nil unless response&.body

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse Stark response: #{e.message}")
      Rails.logger.error("Response body: #{response.body}")
      raise StandardError, 'Invalid response format from Stark server'
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
      data = response['body']['data']
      {
        'content' => data['answer'],
        'action' => data['human_redirect'] ? nil : nil #'handoff if human_redirect is true'
      }
    end

    def error_response?(response)
      return true unless response.is_a?(Hash)
      return true unless response['body'].is_a?(Hash)

      response['body']['status'] == 'error' ||
        (response['metadata'] && response['metadata']['status_code'].to_i >= 400)
    end

    def handle_error_response(response)
      error_message = response.dig('body', 'message')
      errors = response.dig('body', 'errors')
      status_code = response.dig('metadata', 'status_code')

      error_details = {
        message: error_message,
        errors: errors,
        status_code: status_code
      }

      Rails.logger.error("Stark API Error: #{error_details}")
      raise StandardError, error_message || 'Stark API Error'
    end
  end
end
