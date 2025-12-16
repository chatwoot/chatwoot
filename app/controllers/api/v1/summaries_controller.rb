class Api::V1::SummariesController < Api::BaseController
  include Stark::ApiHandler
  before_action :set_conversation

  def show
    force_refresh = params[:force_refresh] == 'true'

    # Validation: prevent refresh if within 24 hours
    if force_refresh && @conversation.conversation_summary_last_generated_at.present? &&
       @conversation.conversation_summary_last_generated_at > 24.hours.ago
      force_refresh = false

      remaining_seconds = 24.hours - (Time.current - @conversation.conversation_summary_last_generated_at)
      hours = (remaining_seconds / 1.hour).to_i
      minutes = ((remaining_seconds % 1.hour) / 1.minute).to_i
      time_string = "#{hours}h #{minutes}m"

      alert_message = I18n.t('conversations.summary.rate_limit_alert', time: time_string)
    end

    # Return cached summary if available and not forcing refresh
    if !force_refresh && @conversation.summary.present? && @conversation.summary_updated_at.present?
      render json: {
        summary: @conversation.summary,
        updated_at: @conversation.summary_updated_at,
        last_generated_at: @conversation.conversation_summary_last_generated_at,
        cached: true,
        alert_message: alert_message
      }
      return
    end

    summary_url = GlobalConfig.get_value('CONVERSATION_SUMMARY_API_URL')

    if summary_url.blank?
      render json: { error: 'Summary service not configured' }, status: :service_unavailable
      return
    end

    # Get last 10 messages formatted for the API
    messages_payload = format_recent_messages(@conversation)

    begin
      response = HTTParty.post(
        summary_url,
        body: { messages: messages_payload }.to_json,
        headers: build_request_headers,
        timeout: 10
      )

      if response.success?
        response_body = JSON.parse(response.body)
        summary = response_body.dig('body', 'data', 'summary') || response_body.dig('data', 'summary')

        if summary
          # Save summary to database
          update_params = {
            summary: summary,
            summary_updated_at: Time.current
          }

          # Only update the refresh timestamp if this was triggered by a force refresh (button click)
          update_params[:conversation_summary_last_generated_at] = Time.current if force_refresh

          @conversation.update(update_params)

          render json: {
            summary: summary,
            updated_at: @conversation.summary_updated_at,
            last_generated_at: @conversation.conversation_summary_last_generated_at,
            cached: false
          }
        else
          Rails.logger.warn "Summary response missing summary field: #{response.body}"
          render json: { error: 'No summary returned' }, status: :bad_gateway
        end
      else
        Rails.logger.error "Summary service error: #{response.code} - #{response.body}"
        render json: { error: "Summary service failed with status #{response.code}" }, status: :bad_gateway
      end
    rescue StandardError => e
      Rails.logger.error "Error fetching summary: #{e.message}"
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  private

  def set_conversation
    # Get conversation_id from query parameters
    conversation_id = params[:conversation_id]

    unless conversation_id.present?
      render json: { error: 'conversation_id is required' }, status: :bad_request
      return
    end

    # Find conversation by display_id
    @conversation = Conversation.find_by!(display_id: conversation_id)

    # Basic access check
    return if Current.user

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  # Helper to access headers from concern mixed in, or simple override if needed
  def build_request_headers
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'Authorization' => "Bearer #{ENV.fetch('STARK_API_KEY', '')}"
    }
  end
end
