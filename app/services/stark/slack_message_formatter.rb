module Stark
  class SlackMessageFormatter
    def self.format_retry_failure(error, conversation, max_retries)
      message_parts = [
        "*🚨 STARK API ERROR*",
        "",
        "*Status:* Stark server error persisted after #{max_retries} retries",
        "*Action:* Conversation handed off to human agent",
        "",
        "*Error Details:*",
        "• Type: `#{error.class}`",
        "• Message: `#{error.message}`"
      ]

      add_conversation_details(message_parts, conversation)
      message_parts.join("\n")
    end

    def self.format_http_error(status_code, message, errors = nil, conversation = nil)
      message_parts = [
        "*🚨 API ERROR*",
        "",
        "*HTTP Status:* `#{status_code}`",
        "*Message:* #{message || 'No message provided'}"
      ]

      if errors.present?
        message_parts << "*Errors:* `#{errors}`"
      end

      add_conversation_link(message_parts, conversation)
      message_parts.join("\n")
    end

    def self.format_unexpected_response(response, conversation = nil)
      message_parts = [
        "*🚨 API ERROR*",
        "",
        "*Status:* Unexpected response from Stark API",
        "*Response:* `#{response.inspect[0..500]}#{'...' if response.inspect.length > 500}`"
      ]

      add_conversation_link(message_parts, conversation)
      message_parts.join("\n")
    end

    def self.format_general_error(error, conversation = nil)
      message_parts = [
        "*🚨 API ERROR*",
        "",
        "*Status:* Stark server error",
        "*Error Type:* `#{error.class}`",
        "*Error Message:* `#{error.message}`"
      ]

      add_conversation_link(message_parts, conversation)
      message_parts.join("\n")
    end

    def self.format_follow_up_error(status_code, message, errors = nil, conversation = nil, follow_up_number = nil)
      message_parts = [
        "*🚨 STARK FOLLOW-UP ERROR*",
        "",
        "*HTTP Status:* `#{status_code}`",
        "*Message:* #{message || 'No message provided'}"
      ]

      if errors.present?
        message_parts << "*Errors:* `#{errors}`"
      end

      if follow_up_number.present?
        message_parts << "*Follow-up Number:* `#{follow_up_number}`"
      end

      add_conversation_link(message_parts, conversation)
      message_parts.join("\n")
    end

    def self.format_follow_up_unexpected_response(response, conversation = nil, follow_up_number = nil)
      message_parts = [
        "*🚨 STARK FOLLOW-UP ERROR*",
        "",
        "*Status:* Unexpected response from Stark API",
        "*Response:* `#{response.inspect[0..500]}#{'...' if response.inspect.length > 500}`"
      ]

      if follow_up_number.present?
        message_parts << "*Follow-up Number:* `#{follow_up_number}`"
      end

      add_conversation_link(message_parts, conversation)
      message_parts.join("\n")
    end

    def self.format_follow_up_parse_error(error, conversation = nil, follow_up_number = nil)
      message_parts = [
        "*🚨 STARK FOLLOW-UP PARSE ERROR*",
        "",
        "*Status:* Failed to parse Stark response",
        "*Error Type:* `#{error.class}`",
        "*Error Message:* `#{error.message}`"
      ]

      if follow_up_number.present?
        message_parts << "*Follow-up Number:* `#{follow_up_number}`"
      end

      add_conversation_link(message_parts, conversation)
      message_parts.join("\n")
    end

    def self.format_follow_up_general_error(error, conversation = nil, follow_up_number = nil)
      message_parts = [
        "*🚨 STARK FOLLOW-UP ERROR*",
        "",
        "*Status:* Stark server error",
        "*Error Type:* `#{error.class}`",
        "*Error Message:* `#{error.message}`"
      ]

      if follow_up_number.present?
        message_parts << "*Follow-up Number:* `#{follow_up_number}`"
      end

      add_conversation_link(message_parts, conversation)
      message_parts.join("\n")
    end

    class << self
      private

      def add_conversation_details(message_parts, conversation)
        return unless conversation

        message_parts << ""
        message_parts << "*Conversation Details:*"
        message_parts << "• Conversation ID: `#{conversation.id}`"
        message_parts << "• Account ID: `#{conversation.account_id}`"
        message_parts << "• Display ID: `#{conversation.display_id}`" if conversation.respond_to?(:display_id)

        add_conversation_link(message_parts, conversation)
      end

      def add_conversation_link(message_parts, conversation)
        return unless conversation

        frontend_url = ENV.fetch('FRONTEND_URL', nil)
        return unless frontend_url && conversation.respond_to?(:display_id) && conversation.display_id

        has_conversation_section = message_parts.any? { |part| part.include?("Conversation") }
        
        message_parts << "" unless has_conversation_section
        message_parts << "*Conversation:*" unless has_conversation_section
        
        conversation_link = "<#{frontend_url}/app/accounts/#{conversation.account_id}/conversations/#{conversation.display_id}|View Conversation>"
        message_parts << conversation_link
      end
    end
  end
end