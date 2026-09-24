module Conversations::UnreadCounts::FilteredCountStoreKeys
  def conversation_version_key(account_id)
    account_key(Redis::Alfred::UNREAD_CONVERSATIONS_V2_CONVERSATION_VERSION, account_id)
  end

  def built_in_filter_version_key(account_id, user_id)
    user_key(Redis::Alfred::UNREAD_CONVERSATIONS_V2_BUILT_IN_FILTER_VERSION, account_id, user_id)
  end

  def built_in_filter_counts_key(account_id, user_id)
    user_key(Redis::Alfred::UNREAD_CONVERSATIONS_V2_BUILT_IN_FILTER_COUNTS, account_id, user_id)
  end

  def built_in_filter_build_lock_key(account_id, user_id)
    user_key(Redis::Alfred::UNREAD_CONVERSATIONS_V2_BUILT_IN_FILTER_BUILD_LOCK, account_id, user_id)
  end

  def built_in_filter_refresh_throttle_key(account_id, user_id)
    user_key(Redis::Alfred::UNREAD_CONVERSATIONS_V2_BUILT_IN_FILTER_REFRESH_THROTTLE, account_id, user_id)
  end

  def folder_index_version_key(account_id, user_id)
    user_key(Redis::Alfred::UNREAD_CONVERSATIONS_V2_FOLDER_INDEX_VERSION, account_id, user_id)
  end

  def folder_index_key(account_id, user_id)
    user_key(Redis::Alfred::UNREAD_CONVERSATIONS_V2_FOLDER_INDEX, account_id, user_id)
  end

  def folder_index_build_lock_key(account_id, user_id)
    user_key(Redis::Alfred::UNREAD_CONVERSATIONS_V2_FOLDER_INDEX_BUILD_LOCK, account_id, user_id)
  end

  def folder_index_refresh_throttle_key(account_id, user_id)
    user_key(Redis::Alfred::UNREAD_CONVERSATIONS_V2_FOLDER_INDEX_REFRESH_THROTTLE, account_id, user_id)
  end

  def filter_version_key(account_id, filter_id)
    filter_key(Redis::Alfred::UNREAD_CONVERSATIONS_V2_FILTER_VERSION, account_id, filter_id)
  end

  def filter_count_key(account_id, filter_id)
    filter_key(Redis::Alfred::UNREAD_CONVERSATIONS_V2_FILTER_COUNT, account_id, filter_id)
  end

  def filter_build_lock_key(account_id, filter_id)
    filter_key(Redis::Alfred::UNREAD_CONVERSATIONS_V2_FILTER_BUILD_LOCK, account_id, filter_id)
  end

  def filter_refresh_throttle_key(account_id, filter_id)
    filter_key(Redis::Alfred::UNREAD_CONVERSATIONS_V2_FILTER_REFRESH_THROTTLE, account_id, filter_id)
  end

  private

  def account_key(format_string, account_id)
    format(format_string, account_id: account_id)
  end

  def user_key(format_string, account_id, user_id)
    format(format_string, account_id: account_id, user_id: user_id)
  end

  def filter_key(format_string, account_id, filter_id)
    format(format_string, account_id: account_id, filter_id: filter_id)
  end
end
