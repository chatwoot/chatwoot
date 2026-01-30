class AgentNotifications::MonthlyImpactReportMailer < ApplicationMailer
  def monthly_report(account:, start_date:, end_date:, metrics:)
    return unless smtp_config_set_or_development?

    @account = account
    ensure_current_account(@account)
    
    # If account is suspended, send to SuperAdmins only
    if @account.suspended?
      recipients = super_admin_emails(@account)
      return if recipients.blank?
    else
      return if account.users.blank?
      recipients = account.users.pluck(:email)
    end

    @start_date = start_date
    @end_date = end_date

    # Metrics
    @dealership_name          = account.name
    @new_conversations        = metrics[:new_conversations]
    @total_messages           = metrics[:total_messages]
    @booking_links_sent       = metrics[:booking_links_sent]
    @booking_forms_completed  = metrics[:booking_forms_completed]
    @handoff_links_sent       = metrics[:handoff_links_sent]
    @handoff_forms_completed  = metrics[:handoff_forms_completed]
    @conversion_rate          = metrics[:conversion_rate]
    @estimated_value          = metrics[:estimated_value]

    base_url = ENV.fetch('FRONTEND_URL')
    @report_url = "#{base_url}/app/accounts/#{account.id}/reports/overview"

    # Generate inline pie chart image (CID) using Gruff
    chart_path = Reports::MonthlyPieChart.generate(metrics[:conversations_by_channel] || {})

    @weekly_impact_chart = false

    if chart_path && File.exist?(chart_path)
      begin
        attachments.inline['monthly_impact_chart.png'] = {
          mime_type: 'image/png',
          content: File.read(chart_path),
          # Explicit Content-ID so we can reference it from HTML
          content_id: '<weekly_impact_chart>'
        }

        @weekly_impact_chart = true
        # Used in Liquid template as cid:{{ weekly_impact_chart_cid }}
        @weekly_impact_chart_cid = 'weekly_impact_chart'
      rescue StandardError => e
        Rails.logger.error "WeeklyImpactReportMailer chart attach failed: #{e.class} - #{e.message}"
      ensure
        File.delete(chart_path) if File.exist?(chart_path)
      end
    end

    subject = "Cruise Control Impact Monthly Report - #{@start_date.strftime('%m/%d')} - #{@end_date.strftime('%m/%d')}"

    send_mail_with_liquid(
      to: recipients,
      subject: subject
    )
  end

  private

  def liquid_droppables
    super.merge!(
      account: @account,
      start_date: @start_date,
      end_date: @end_date,
      new_conversations: @new_conversations,
      total_messages: @total_messages,
      booking_links_sent: @booking_links_sent,
      booking_forms_completed: @booking_forms_completed,
      handoff_links_sent: @handoff_links_sent,
      handoff_forms_completed: @handoff_forms_completed,
      conversion_rate: @conversion_rate,
      estimated_value: @estimated_value,
      dealership_name: @dealership_name,
      report_url: @report_url,
      weekly_impact_chart: @weekly_impact_chart,
      weekly_impact_chart_cid: @weekly_impact_chart_cid
    )
  end

  def liquid_locals
    super.merge!(
      start_date: @start_date,
      end_date: @end_date,
      new_conversations: @new_conversations,
      total_messages: @total_messages,
      booking_links_sent: @booking_links_sent,
      booking_forms_completed: @booking_forms_completed,
      handoff_links_sent: @handoff_links_sent,
      handoff_forms_completed: @handoff_forms_completed,
      conversion_rate: @conversion_rate,
      estimated_value: @estimated_value,
      dealership_name: @dealership_name,
      report_url: @report_url,
      weekly_impact_chart: @weekly_impact_chart,
      weekly_impact_chart_cid: @weekly_impact_chart_cid
    )
  end
end
