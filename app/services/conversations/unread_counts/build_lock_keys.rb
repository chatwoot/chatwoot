module Conversations::UnreadCounts::BuildLockKeys
  private

  def base_build_lock_key
    format(Redis::Alfred::UNREAD_CONVERSATIONS_BASE_BUILD_LOCK, account_id: account.id)
  end

  def assignment_build_lock_key
    format(Redis::Alfred::UNREAD_CONVERSATIONS_ASSIGNMENT_BUILD_LOCK, account_id: account.id)
  end

  def filters_build_lock_key
    format(Redis::Alfred::UNREAD_CONVERSATIONS_USER_FILTERS_BUILD_LOCK, account_id: account.id, user_id: user.id)
  end
end
