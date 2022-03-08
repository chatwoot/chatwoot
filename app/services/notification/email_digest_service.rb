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
      conversation_created: conversation_created_count,
      conversation_resolved: conversation_resolved_count,
      total_conversation_created: total_conversations.count,
      total_conversation_resolved:  total_resolved_conversations.count
    }
    AccountNotifications::DigestMailer.send_email_digest(account, user, data).deliver_now
  end

  private

  # default last_two_weeks
  def conversation_created_count
    total_conversations.where(
      'created_at >= ? AND created_at < ?',
      2.weeks.ago, Time.zone.now
    ).count
  end

  # default last_two_weeks
  def conversation_resolved_count
    total_resolved_conversations.where(
      'last_activity_at >= ? AND last_activity_at < ?',
      2.weeks.ago, Time.zone.now
    ).count
  end

  def total_conversations
    account.conversations
  end

  def total_resolved_conversations
    total_conversations.resolved
  end
end
