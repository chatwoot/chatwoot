class V2::Reports::AgentDailyMatrixBuilder
  include DateRangeHelper
  include TimezoneHelper

  attr_reader :account, :params

  def initialize(account:, params:)
    @account = account
    @params = params
  end

  def build
    return { agents: [], days: [], matrix: [] } if range.nil?

    rows = account.account_users.includes(:user).map do |account_user|
      values = days.map { |day| grouped_counts[[account_user.user_id, day]] || 0 }
      {
        agent: { id: account_user.user_id, name: account_user.user.name, total: values.sum },
        values: values
      }
    end
    rows.sort_by! { |row| [-row[:agent][:total], row[:agent][:name]] }

    {
      agents: rows.map { |row| row[:agent] },
      days: days.map { |day| day.strftime('%Y-%m-%d') },
      matrix: rows.map { |row| row[:values] }
    }
  end

  private

  def days
    @days ||= begin
      first_day = range.begin.in_time_zone(timezone).to_date
      last_day = (range.end - 1.second).in_time_zone(timezone).to_date
      (first_day..last_day).to_a
    end
  end

  def grouped_counts
    @grouped_counts ||= account.reporting_events
                               .where(name: 'conversation_resolved', created_at: range)
                               .group(:user_id)
                               .group_by_period(:day, :created_at, time_zone: timezone)
                               .count
  end

  def timezone
    @timezone ||= timezone_name_from_offset(params[:timezone_offset])
  end
end
