class SuperAdmin::DashboardController < SuperAdmin::ApplicationController
  include ActionView::Helpers::NumberHelper

  ALLOWED_CHART_DAYS = [7, 30].freeze

  def index
    @chart_days = parse_chart_days
    @data = conversations_by_day
    @accounts_count = format_count(Account.count)
    @users_count = format_count(User.count)
    @inboxes_count = format_count(Inbox.count)
    @conversations_count = format_count(recent_conversations.count)
  end

  private

  def parse_chart_days
    days = params[:chart_period].to_i
    ALLOWED_CHART_DAYS.include?(days) ? days : 7
  end

  def chart_date_range
    (@chart_days - 1).days.ago.beginning_of_day..Time.current
  end

  def last_30_days
    29.days.ago.beginning_of_day..Time.current
  end

  def recent_conversations
    Conversation.unscoped.where(created_at: last_30_days)
  end

  def conversations_by_day
    Conversation.unscoped.group_by_day(:created_at, range: chart_date_range, default_value: 0).count.to_a
  end

  def format_count(count)
    number_with_delimiter(count)
  end
end
