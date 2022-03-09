class Notification::EmailDigestService
  attr_accessor :user, :account

  def initialize(user, account)
    @user = user
    @account = account
  end

  # build the data for the account: default last_two_weeks
  # conversation created
  # conversation resolved

  def perform
    # return unless user_subscribed_to_email_digest?

    data = {
      conversation_created: conversation_created.count,
      conversation_resolved: conversation_resolved.count,
      total_conversation_created: total_conversations.count,
      total_conversation_resolved: total_resolved_conversations.count,
      conversation_assigned_to_agent: conversation_assigned_to_agent.count,
      conversation_resolved_by_agent: conversation_resolved_by_agent.count
    }
    prepare_chart_resolution_data
    AccountNotifications::DigestMailer.send_email_digest(account, user, data, @chart_data).deliver_now
  end

  private

  # default last_two_weeks
  def conversation_created
    total_conversations.where(
      'created_at >= ? AND created_at < ?',
      2.weeks.ago, Time.zone.now
    )
  end

  # default last_two_weeks
  def conversation_resolved
    total_resolved_conversations.where(
      'last_activity_at >= ? AND last_activity_at < ?',
      2.weeks.ago, Time.zone.now
    )
  end

  def total_conversations
    account.conversations
  end

  def total_resolved_conversations
    total_conversations.resolved
  end

  def prepare_chart_resolution_data
    total_last_month_resolution
    @chart_data = {
      last_week: last_week,
      second_last_week: second_last_week,
      third_last_week: third_last_week,
      fourth_last_week: fourth_last_week,
      last_week_count: @last_week,
      second_last_week_count: @second_last_week,
      third_last_week_count: @third_last_week,
      fourth_last_week_count: @fourth_last_week
    }
  end

  def conversation_assigned_to_agent
    conversation_created.where(assignee_id: @user.id)
  end

  def conversation_resolved_by_agent
    conversation_resolved.where(assignee_id: @user.id)
  end

  def last_week
    @last_week = total_resolved_conversations.where(
      'last_activity_at >= ? AND last_activity_at < ?',
      1.week.ago, Time.zone.now
    ).count

    (@last_week * 100) / @total_last_month_resolution
  end

  def second_last_week
    @second_last_week = total_resolved_conversations.where(
      'last_activity_at >= ? AND last_activity_at < ?',
      2.weeks.ago, 1.week.ago
    ).count

    (@second_last_week * 100) / @total_last_month_resolution
  end

  def third_last_week
    @third_last_week = total_resolved_conversations.where(
      'last_activity_at >= ? AND last_activity_at < ?',
      3.weeks.ago, 2.weeks.ago
    ).count

    (@third_last_week * 100) / @total_last_month_resolution
  end

  def fourth_last_week
    @fourth_last_week = total_resolved_conversations.where(
      'last_activity_at >= ? AND last_activity_at < ?',
      4.weeks.ago, 3.weeks.ago
    ).count

    (@fourth_last_week * 100) / @total_last_month_resolution
  end

  def total_last_month_resolution
    total = total_resolved_conversations.where(
      'last_activity_at >= ? AND last_activity_at < ?',
      4.weeks.ago, Time.zone.now
    ).count
    @total_last_month_resolution = total
    @total_last_month_resolution = 1 if total.zero?
  end
end
