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
    
        status_code = response.dig('metadata', 'status_code').to_i
    
        case status_code
        when 200
          parse_stark_response(response)
        when 400, 500
          log_stark_error(status_code, response)
          nil
        else
          log_and_notify_slack(
            "[STARK API ERROR] Unexpected response: #{response.inspect}"
          )
          nil
        end
      end
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse Stark response: #{e.message}")
      nil
    rescue StandardError => e
      log_and_notify_slack(
        "[STARK API ERROR] Stark server error persisted: #{e.message}"
      )
      nil
    end

    private

    def make_api_request(conversation, content)
      response = HTTParty.post(
        agent_bot.outgoing_url,
        body: build_request_payload(conversation, content).to_json,
        headers: build_request_headers,
        timeout: 60
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
        dealership_id: conversation.account&.dealership_id,
        customer_id: conversation.contact&.id,
        recent_messages: format_recent_messages(conversation)
      }
    end

    def format_recent_messages(conversation)
      conversation.messages
                  .not_activity
                  .not_template
                  .left_outer_joins(:attachments)
                  .where(attachments: { id: nil })
                  .where.not(content: [nil, ''])
                  .reorder(created_at: :desc)
                  .limit(10)
                  .map do |message|
        {
          conversation_id: message.conversation_id,
          message_type: message.message_type,
          content: message.content,
          created_at: message.created_at,
          is_follow_up_message: message.content_attributes['follow_up'] || false,
        }
      end
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
      ConversationHandoffService.new(conversation).process_handoff if data['human_redirect']

      {
        'content' => data['answer'],
        'action' => nil,
        'stop_follow_up' => data['stop_follow_up'],
        'attachments' => data['attachments'] || []
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

    def log_stark_error(status_code, response)
      message = response.dig('body', 'message')
      errors  = response.dig('body', 'errors')
    
      error_text = case status_code
                   when 400
                     "400 Bad Request: #{message}, Errors: #{errors}"
                   when 500
                     "500 Server Error: #{message}"
                   else
                     "Unknown Error (#{status_code}): #{response.inspect}"
                   end
    
      log_and_notify_slack("[STARK API ERROR] #{error_text}")
    end
    
    def log_and_notify_slack(message)
      Rails.logger.error(message)
      SlackNotifierService.call(
        text: message
      )
    end
  end
end
