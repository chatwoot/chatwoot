class MonthlyReports::SendMonthlyReportJob < ApplicationJob
    queue_as :default
  
    def perform(account_id, start_date, end_date)
      account = Account.find_by(id: account_id)
      return if account.nil?
  
      metrics = MonthlyReports::GenerateMetricsService.new(account, start_date, end_date).perform

    # AgentNotifications::MonthlyImpactReportMailer.monthly_report(
    #   account: account,
    #   start_date: start_date,
    #   end_date: end_date,
    #   metrics: metrics
    # ).deliver_later

    send_slack_notification_for_monthly_report(account, start_date, end_date, metrics)
  end

  private

  def send_slack_notification_for_monthly_report(account, start_date, end_date, metrics)
    base_url = ENV.fetch('FRONTEND_URL', nil)
    report_url = "#{base_url}/app/accounts/#{account.id}/reports/overview"
    
    date_range = "#{start_date.strftime('%m/%d')} - #{end_date.strftime('%m/%d')}"
    report_guide_url = "https://courier.getcruisecontrol.com/hc/account-and-agent-setup-in-courier/articles/1765973892-weekly-impact-report-metrics-guide"
    
    # Format conversations by channel
    channel_breakdown = if metrics[:conversations_by_channel].present?
      metrics[:conversations_by_channel].map { |channel, count| "#{channel}: #{count}" }.join("\n")
    else
      "N/A"
    end
    
    message = "Account Name: #{account.name}\n\n" \
              "*Cruise Control Monthly Impact Report - #{date_range}*\n" \
              "Here's a snapshot of your dealership's performance for the month:\n\n" \
              "• New conversations: #{metrics[:new_conversations]}\n" \
              "• Total messages: #{metrics[:total_messages]}\n" \
              "• New CRM leads pushed: #{metrics[:booking_forms_completed]}\n" \
              "• New handoff requests: #{metrics[:handoff_forms_completed]}\n" \
              "• Bookings conversion rate: #{metrics[:conversion_rate]}%\n\n" \
              "• *Bookings Estimated value: $#{metrics[:estimated_value]}*\n\n" \
              "Check out our <#{report_guide_url}|Impact reports guide> to understand what each of our metrics mean.\n\n" \
              "Visit our reports dashboard for a more detailed breakdown:\n" \
              "<#{report_url}|View Reports Dashboard>"
    
    chart_path = Reports::MonthlyPieChart.generate(metrics[:conversations_by_channel] || {})
    
    # Send message with chart to Slack
    if chart_path && File.exist?(chart_path)
      send_slack_message_with_chart(message, chart_path)
      # Clean up the temporary chart file
      File.delete(chart_path) if File.exist?(chart_path)
    else
       SlackNotifierService.call(text: message, is_impact_report: true)
    end
  end

  def send_slack_message_with_chart(message, chart_path)
    slack_token = ENV['SLACK_BOT_TOKEN']
    channel = ENV['SLACK_IMPACT_REPORT_CHANNEL']
    
    unless slack_token.present?
      Rails.logger.error("SLACK_BOT_TOKEN is missing in environment variables")
      return
    end
    
    unless channel.present?
      Rails.logger.error("SLACK_IMPACT_REPORT_CHANNEL is missing in environment variables")
      return
    end

    begin
      slack_client = Slack::Web::Client.new(token: slack_token)
      
      # Read the chart file content as binary
      chart_content = File.binread(chart_path)
      
      # Upload the chart file to Slack with the message as initial comment
      file_result = slack_client.files_upload_v2(
        channel_id: channel,
        filename: 'monthly_impact_chart.png',
        content: chart_content,
        title: 'Monthly Impact Breakdown',
        initial_comment: message
      )
      
      Rails.logger.info("Monthly report chart uploaded to Slack successfully")
    rescue Slack::Web::Api::Errors::SlackError => e
      Rails.logger.error("Failed to upload chart to Slack: #{e.message}")
      # SlackNotifierService.call(text: message, channel: channel)
      SlackNotifierService.call(text: message, is_impact_report: true)
    rescue => e
      Rails.logger.error("Failed to send Slack message with chart: #{e.message}")
      # SlackNotifierService.call(text: message, channel: channel)
      SlackNotifierService.call(text: message, is_impact_report: true)
    end
  end
end