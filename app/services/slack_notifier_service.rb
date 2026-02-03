class SlackNotifierService
    SLACK_API_URL = "https://slack.com/api/chat.postMessage".freeze
  
    def self.call(text:, channel: nil, is_impact_report: false)
        new(text: text, channel: channel, is_impact_report: is_impact_report).call
    end

    def initialize(text:, channel: nil, is_impact_report: false)
      @channel = if is_impact_report
                   ENV['SLACK_IMPACT_REPORT_CHANNEL']
                 else
                   channel.presence || ENV['SLACK_DEFAULT_CHANNEL']
                 end
      @text = text
      @slack_token = ENV['SLACK_BOT_TOKEN']
    end
  
    def call
      unless @slack_token.present?
        Rails.logger.error("SLACK_BOT_TOKEN is missing in environment variables")
        return
      end
  
      response = HTTParty.post(
        SLACK_API_URL,
        headers: {
          "Authorization" => "Bearer #{@slack_token}",
          "Content-Type" => "application/json"
        },
        body: {
          channel: @channel,
          text: @text
        }.to_json
      )
  
      unless response&.parsed_response&.dig("ok")
        Rails.logger.error("Slack API Error: #{response&.body}")
      end
    rescue => e
      Rails.logger.error("Failed to send Slack message: #{e.message}")
    end
  end
  