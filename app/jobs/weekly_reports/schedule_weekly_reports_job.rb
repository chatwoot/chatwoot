class WeeklyReports::ScheduleWeeklyReportsJob < ApplicationJob
  queue_as :default

  def perform
    end_date = Date.today
    start_date = end_date - 6.days

    Account.find_each do |account|
      WeeklyReports::SendWeeklyReportJob.perform_later(account.id, start_date, end_date)
    end
  end
end
