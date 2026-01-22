# app/builders/v2/reports/overview_summary_builder.rb
class V2::Reports::OverviewSummaryBuilder
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def build
    {
      conversation_metrics: conversation_metrics,
      agent_status: agent_status,
      summary: summary,
      date_range: date_range
    }
  end

  private

  def conversation_metrics
    V2::ReportBuilder
      .new(account, type: :account)
      .conversation_metrics
  end

  def agent_status
    account.account_users
           .filter_map(&:availability_status)
           .tally
  end

  def summary
    V2::Reports::Conversations::MetricBuilder
      .new(account, summary_params)
      .summary
  end

  def summary_params
    {
      type: :account,
      since: since_7_days,
      until: until_now,
      business_hours: false
    }
  end

  def date_range
    {
      since: Time.zone.at(since_7_days.to_i),
      until: Time.zone.at(until_now.to_i)
    }
  end

  def since_7_days
    7.days.ago.beginning_of_day.to_i.to_s
  end

  def until_now
    Time.zone.now.end_of_day.to_i.to_s
  end
end
