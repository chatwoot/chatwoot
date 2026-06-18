class Conversations::UnreadCounts::UserFilterNotifier
  include Events::Types

  attr_reader :account, :user

  def initialize(account:, user:)
    @account = account
    @user = user
  end

  def perform
    return false if account.blank? || user.blank?
    return false unless account.feature_enabled?('conversation_unread_counts')

    ::Conversations::UnreadCounts::Store.clear_user_filters!(account.id, user.id)
    Rails.configuration.dispatcher.dispatch(CONVERSATION_UNREAD_COUNT_CHANGED, Time.zone.now, account: account, user: user)
    true
  end
end
