class WeeklyReports::SendWeeklyReportJob < ApplicationJob
    queue_as :default
  
    def perform(account_id, start_date, end_date)
      account = Account.find_by(id: account_id)
      return if account.nil?
  
      metrics = WeeklyReports::GenerateMetricsService.new(account, start_date, end_date).perform
  
      AgentNotifications::WeeklyImpactReportMailer.weekly_report(
        account: account,
        start_date: start_date,
        end_date: end_date,
        metrics: metrics
      ).deliver_later
    end
  end
