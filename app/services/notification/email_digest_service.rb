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
      conversation_resolved: conversation_resolved_count
    }
    AccountNotifications::DigestMailer.send_email_digest(account, user, data).deliver_now
  end

  private

  # default last_two_weeks
  def conversation_created_count
    account.conversations.where(
      'created_at >= ? AND created_at < ?',
      2.weeks.ago, Time.zone.now
    ).count
  end

  # default last_two_weeks
  def conversation_resolved_count
    account.conversations.resolved.where(
      'last_activity_at >= ? AND last_activity_at < ?',
      2.weeks.ago, Time.zone.now
    ).count
  end
end
