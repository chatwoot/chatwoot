module Conversations
  class SummaryService
    include Stark::ApiHandler

    attr_reader :conversation, :force_refresh, :skip_rate_limit

    def initialize(conversation:, force_refresh: false, skip_rate_limit: false)
      @conversation = conversation
      @force_refresh = force_refresh
      @skip_rate_limit = skip_rate_limit
    end

    def perform
      # Check 24h rate limit for force refresh
      if force_refresh && !skip_rate_limit && limited_by_frequency?
        return {
          success: true,
          data: build_response(cached: true, alert_message: rate_limit_alert_message)
        }
      end

      # Return cached summary if available and not forcing refresh
      if !force_refresh && !skip_rate_limit && cached_summary_available?
        return {
          success: true,
          data: build_response(cached: true)
        }
      end

      summary_url = GlobalConfig.get_value('CONVERSATION_SUMMARY_API_URL')
      return { success: false, error: 'Summary service not configured', status: :service_unavailable } if summary_url.blank?

      fetch_and_update_summary(summary_url)
    rescue StandardError => e
      Rails.logger.error "Error fetching summary: #{e.message}"
      { success: false, error: e.message, status: :internal_server_error }
    end

    private

    def limited_by_frequency?
      @conversation.conversation_summary_last_generated_at.present? &&
        @conversation.conversation_summary_last_generated_at > 24.hours.ago
    end

    def cached_summary_available?
      @conversation.summary.present? && @conversation.summary_updated_at.present?
    end

    def rate_limit_remaining_seconds
      24.hours - (Time.current - @conversation.conversation_summary_last_generated_at)
    end

    def rate_limit_alert_message
      hours = (rate_limit_remaining_seconds / 1.hour).to_i
      minutes = ((rate_limit_remaining_seconds % 1.hour) / 1.minute).to_i
      time_string = "#{hours}h #{minutes}m"
      I18n.t('conversations.summary.rate_limit_alert', time: time_string)
    end

    def build_response(cached:, alert_message: nil)
      {
        summary: @conversation.summary,
        updated_at: @conversation.summary_updated_at,
        last_generated_at: @conversation.conversation_summary_last_generated_at,
        cached: cached,
        alert_message: alert_message
      }
    end

    def fetch_and_update_summary(url)
      messages_payload = format_recent_messages(@conversation)

      response = HTTParty.post(
        url,
        body: { messages: messages_payload }.to_json,
        headers: build_request_headers,
        timeout: 10
      )

      if response.success?
        process_successful_response(response)
      else
        Rails.logger.error "Summary service error: #{response.code} - #{response.body}"
        { success: false, error: "Summary service failed with status #{response.code}", status: :bad_gateway }
      end
    end

    def process_successful_response(response)
      response_body = JSON.parse(response.body)
      summary = response_body.dig('body', 'data', 'summary') || response_body.dig('data', 'summary')

      if summary
        update_conversation(summary)
        { success: true, data: build_response(cached: false) }
      else
        Rails.logger.warn "Summary response missing summary field: #{response.body}"
        { success: false, error: 'No summary returned', status: :bad_gateway }
      end
    end

    def update_conversation(summary)
      update_params = {
        summary: summary,
        summary_updated_at: Time.current
      }
      # Only update the refresh timestamp if this was triggered by a force refresh (button click)
      update_params[:conversation_summary_last_generated_at] = Time.current if force_refresh

      @conversation.update(update_params)
    end

    # Explicitly using the one from ApiHandler or overriding if needed.
    # The controller used one that had STARK_API_KEY.
    # Stark::ApiHandler also uses STARK_API_KEY.
    def build_request_headers
      {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{ENV.fetch('STARK_API_KEY', '')}"
      }
    end
  end
end
