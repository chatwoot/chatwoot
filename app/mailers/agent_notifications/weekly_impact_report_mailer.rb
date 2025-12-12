class AgentNotifications::WeeklyImpactReportMailer < ApplicationMailer
  def weekly_report(account:, start_date:, end_date:, metrics:)
    return unless smtp_config_set_or_development?
    return if account.users.blank?

    @account = account
    ensure_current_account(@account)

    @start_date = start_date
    @end_date = end_date

    # Metrics
    @dealership_name          = account.name
    @new_conversations        = metrics[:new_conversations]
    @booking_links_sent       = metrics[:booking_links_sent]
    @booking_forms_completed  = metrics[:booking_forms_completed]
    @conversion_rate          = metrics[:conversion_rate]
    @estimated_value          = metrics[:estimated_value]

    base_url = ENV.fetch('FRONTEND_URL')
    @report_url = "#{base_url}/app/accounts/#{account.id}/reports/overview"

    subject = "Cruise Control Impact Weekly Report - #{@start_date.strftime('%m/%d')} - #{@end_date.strftime('%m/%d')}"

    send_mail_with_liquid(
      to: agent_emails,
      subject: subject
    )
  end

  private

  def agent_emails
    @account.users.pluck(:email)
  end

  def liquid_droppables
    super.merge!(
      account: @account,
      start_date: @start_date,
      end_date: @end_date,
      new_conversations: @new_conversations,
      booking_links_sent: @booking_links_sent,
      booking_forms_completed: @booking_forms_completed,
      conversion_rate: @conversion_rate,
      estimated_value: @estimated_value,
      dealership_name: @dealership_name,
      report_url: @report_url
    )
  end

  def liquid_locals
    super.merge!(
      start_date: @start_date,
      end_date: @end_date,
      new_conversations: @new_conversations,
      booking_links_sent: @booking_links_sent,
      booking_forms_completed: @booking_forms_completed,
      conversion_rate: @conversion_rate,
      estimated_value: @estimated_value,
      dealership_name: @dealership_name,
      report_url: @report_url
    )
  end
end
