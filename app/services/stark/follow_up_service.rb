module Stark
  class FollowUpService
    include StarkRetryable

    MAX_RETRIES = 1
    RETRY_DELAY = 3

    def initialize(conversation, follow_up_number)
      @conversation = conversation
      @follow_up_number = follow_up_number
    end

    def get_follow_up_content
      return nil unless valid_dealership_id?(@conversation.account&.dealership_id)

      retries = 0
      begin
        response = make_api_request

        status_code = response.dig('metadata', 'status_code').to_i
        case status_code
        when 200
          # Success: return the message
          response.dig('body', 'message')
        when 400
          # Invalid data: log and return nil
          Rails.logger.error("Stark invalid data: #{response.dig('body', 'message')}, errors: #{response.dig('body', 'error')}")
          nil
        when 500
          # Server error: log and return nil
          Rails.logger.error("Stark server error: #{response.dig('body', 'message')}")
          nil
        else
          # Unexpected status: log and return nil
          Rails.logger.error("Unexpected Stark response: #{response.inspect}")
          nil
        end
      rescue StandardError => e
        retries += 1
        if retries <= MAX_RETRIES
          Rails.logger.warn("Stark server error encountered (#{e.message}). Attempt #{retries} of #{MAX_RETRIES}. Retrying in #{RETRY_DELAY} seconds...")
          sleep(RETRY_DELAY)
          retry
        end
        Rails.logger.error("Stark server error persisted: #{e.message}")
        nil
      rescue JSON::ParserError => e
        Rails.logger.error("Failed to parse Stark response: #{e.message}")
        nil
      end
    end

    private

    def make_api_request
      response = HTTParty.post(
        "#{ENV.fetch('STARK_HOST')}/api/v1/stark/follow-up/",
        body: build_follow_up_payload.to_json,
        headers: build_request_headers
      )

      parse_response_body(response)
    end

    def build_follow_up_payload
      {
        follow_up: true,
        follow_up_number: @follow_up_number,
        session_id: @conversation.id,
        dealership_id: @conversation.account&.dealership_id,
        customer_id: @conversation.contact&.id,
        recent_messages: format_recent_messages
      }
    end

    def build_request_headers
      {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{ENV.fetch('STARK_API_KEY', nil)}"
      }
    end

    def parse_response_body(response)
      return nil unless response&.body

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse Stark response: #{e.message}")
      Rails.logger.error("Response body: #{response.body}")
      raise StandardError, 'Invalid response format from Stark server'
    end

    def parse_stark_response(response)
      data = response['body']['data']
      {
        'content' => data['answer'],
        'action' => nil
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

    def valid_dealership_id?(dealership_id)
      dealership_id.present? && dealership_id.match?(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
    end

    def format_recent_messages
      @conversation.messages
                   .not_activity
                   .not_template
                   .reorder(created_at: :desc)
                   .limit(10)
                   .map do |message|
        {
          conversation_id: message.conversation_id,
          message_type: message.message_type,
          content: message.content,
          created_at: message.created_at
        }
      end
    end

    def agent_bot
      @agent_bot ||= @conversation.inbox.agent_bot
    end
  end
end
