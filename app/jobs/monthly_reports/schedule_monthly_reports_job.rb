class MonthlyReports::ScheduleMonthlyReportsJob < ApplicationJob
  queue_as :default

  def perform
    end_date = Date.today
    start_date = end_date - 29.days

    Account.joins(:inboxes).distinct.find_each do |account|
      return unless account.inboxes.exists?
      MonthlyReports::SendMonthlyReportJob.perform_later(account.id, start_date, end_date)
    end
  end
end
