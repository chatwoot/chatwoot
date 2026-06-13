module Conversations::UnreadCounts::FilterCounter
  private

  def unread_filter_counts
    keys = user_filter_keys
    counts_by_key = store.counts_for_keys(keys.values + folder_keys.values)

    {
      mentions_count: counts_by_key[keys[:mentions]].to_i,
      participating_count: counts_by_key[keys[:participating]].to_i,
      unattended_count: counts_by_key[keys[:unattended]].to_i,
      folders: folder_counts(counts_by_key)
    }
  end

  def user_filter_keys
    {
      mentions: store.user_mentions_key(account.id, user.id),
      participating: store.user_participating_key(account.id, user.id),
      unattended: store.user_unattended_key(account.id, user.id)
    }
  end

  def conversation_folder_ids
    @conversation_folder_ids ||= account.custom_filters.where(user: user, filter_type: :conversation).pluck(:id)
  end

  def folder_keys
    @folder_keys ||= conversation_folder_ids.index_with do |custom_filter_id|
      store.user_folder_key(account.id, user.id, custom_filter_id)
    end
  end

  def folder_counts(counts_by_key)
    folder_keys.each_with_object({}) do |(custom_filter_id, key), result|
      count = counts_by_key[key].to_i
      result[custom_filter_id.to_s] = count if count.positive?
    end
  end
end
