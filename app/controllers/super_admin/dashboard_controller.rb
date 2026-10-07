class SuperAdmin::DashboardController < SuperAdmin::ApplicationController
  include ActionView::Helpers::NumberHelper

  def index
    respond_to do |format|
      format.html
      format.json { render json: dashboard_stats }
    end
  end

  private

  def dashboard_stats
    Rails.cache.fetch('super_admin:dashboard_stats', expires_in: 30.minutes) do
      {
        chartData: Conversation.unscoped.group_by_day(:created_at, range: 30.days.ago..2.seconds.ago).count.to_a,
        accountsCount: number_with_delimiter(Account.count),
        usersCount: number_with_delimiter(User.count),
        inboxesCount: number_with_delimiter(Inbox.count),
        conversationsCount: number_with_delimiter(conversations_count_estimate)
      }
    end
  end

  # Exact COUNT(*) scans the whole table; the planner estimate is instant
  # and close enough for dashboard display.
  def conversations_count_estimate
    estimate = ActiveRecord::Base.connection.select_value(
      "SELECT reltuples::bigint FROM pg_class WHERE relname = 'conversations'"
    ).to_i
    # reltuples is -1 until the table is first vacuumed/analyzed
    estimate.negative? ? Conversation.count : estimate
  end
end
