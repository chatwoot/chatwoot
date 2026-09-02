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

    rows = sorted_rows
    {
      agents: rows.pluck(:agent),
      days: days.map { |day| day.strftime('%Y-%m-%d') },
      matrix: rows.pluck(:values)
    }
  end

  private

  # The whole roster is listed, so an agent with no resolutions still gets a row.
  def sorted_rows
    rows = account.account_users.includes(:user).map { |account_user| row_for(account_user) }
    rows.sort_by { |row| [-row[:agent][:total], row[:agent][:name]] }
  end

  def row_for(account_user)
    values = days.map { |day| grouped_counts[[account_user.user_id, day]] || 0 }

    {
      agent: { id: account_user.user_id, name: account_user.user.name, total: values.sum },
      values: values
    }
  end

  def days
    @days ||= begin
      first_day = range.begin.in_time_zone(timezone).to_date
      last_day = (range.end - 1.second).in_time_zone(timezone).to_date
      (first_day..last_day).to_a
    end
  end

  # Grouping this way keys each count as [user_id, date]; the builder spec asserts that shape.
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
