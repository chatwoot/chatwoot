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
          { message: response.dig('body', 'message'), metadata: response.dig('body', 'metadata') || {} }
        when 400
          # Invalid data: log and return nil
          message = response.dig('body', 'message')
          errors = response.dig('body', 'errors')
          log_and_notify_slack(
            Stark::SlackMessageFormatter.format_follow_up_error(400, message, errors, @conversation, @follow_up_number)
          )
          nil
        when 500
          # Server error: log and return nil
          message = response.dig('body', 'message')
          log_and_notify_slack(
            Stark::SlackMessageFormatter.format_follow_up_error(500, message, nil, @conversation, @follow_up_number)
          )
          nil
        else
          # Unexpected status: log and return nil
          log_and_notify_slack(
            Stark::SlackMessageFormatter.format_follow_up_unexpected_response(response, @conversation, @follow_up_number)
          )
          nil
        end
      rescue JSON::ParserError => e
        log_and_notify_slack(
          Stark::SlackMessageFormatter.format_follow_up_parse_error(e, @conversation, @follow_up_number)
        )
        nil
      rescue StandardError => e
        retries += 1
        if retries <= MAX_RETRIES
          Rails.logger.warn("Stark server error encountered (#{e.message}). Attempt #{retries} of #{MAX_RETRIES}. Retrying in #{RETRY_DELAY} seconds...")
          sleep(RETRY_DELAY)
          retry
        end

        log_and_notify_slack(
          Stark::SlackMessageFormatter.format_follow_up_general_error(e, @conversation, @follow_up_number)
        )
        nil
      end
    end

    private

    def make_api_request
      stark_endpoint = GlobalConfig.get_value('STARK_FOLLOW_UP_ENDPOINT')

      response = HTTParty.post(
        "#{stark_endpoint}",
        body: build_follow_up_payload.to_json,
        headers: build_request_headers,
        timeout: 60
      )

      parse_response_body(response)
    end

    def build_follow_up_payload
      {
        follow_up: true,
        follow_up_number: @follow_up_number,
        session_id: @conversation.id,
        dealership_id: @conversation.account&.dealership_id,
        account_id: @conversation.account_id,
        customer_id: @conversation.contact&.id,
        customer_name: extract_customer_name(@conversation.contact, @conversation.inbox.platform_name),
        platform: @conversation.inbox.platform_name,
        recent_messages: format_recent_messages
      }
    end

    def build_request_headers
      {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{ENV.fetch('STARK_API_KEY')}"
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
        contact = message.sender.is_a?(Contact) ? message.sender : @conversation.contact
        {
          conversation_id: message.conversation_id,
          message_type: message.message_type,
          content: message.content,
          customer_name: extract_customer_name(contact, @conversation.inbox.platform_name),
          created_at: message.created_at,
          is_follow_up_message: message.content_attributes['follow_up'] || false,
          is_image_attached: message_has_image?(message),
          is_story_mentioned: is_story_mentioned?(message),
          metadata: message.metadata
        }
      end
    end

    def message_has_image?(message)
      return false if message.nil?

      message.attachments.exists?(file_type: :image)
    end

    def is_story_mentioned?(message)
      return false if message.nil?

      message.content_attributes[:image_type] == 'story_mention'
    end

    def log_and_notify_slack(message)
      Rails.logger.error(message)
      SlackNotifierService.call(
        text: message
      )
    rescue StandardError => e
      Rails.logger.error("Failed to send Slack notification: #{e.message}")
    end

    def extract_customer_name(contact, platform)
      return nil if contact.nil?

      if platform == 'Website'
        return contact.name if contact.email.present?
        return nil
      end

      if platform == 'Instagram'
        return contact.additional_attributes&.dig('social_instagram_user_name') ||
               contact.additional_attributes&.dig('social_profiles', 'instagram') ||
               contact.name
      end

      if platform == 'Facebook'
        return contact.additional_attributes&.dig('social_profiles', 'facebook') ||
               contact.name
      end

      contact.name
    end
  end
end
