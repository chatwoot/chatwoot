module Conversations::UnreadCounts::UserFilterStore
  def filters_ready?(account_id, user_id)
    Redis::Alfred.exists?(filters_ready_key(account_id, user_id))
  end

  def mark_filters_ready!(account_id, user_id)
    Redis::Alfred.set(filters_ready_key(account_id, user_id), Time.current.to_i, ex: Conversations::UnreadCounts::READY_TTL)
  end

  def clear_filter_caches!(account_id)
    delete_matching("#{account_prefix(account_id)}::USER::*")
  end

  def clear_user_filters!(account_id, user_id)
    delete_matching("#{user_filter_prefix(account_id, user_id)}::*")
  end

  def add_filter_memberships(account_id:, user_id:, filters:, folders:)
    memberships = {
      user_mentions_key(account_id, user_id) => filters[:mentions],
      user_participating_key(account_id, user_id) => filters[:participating],
      user_unattended_key(account_id, user_id) => filters[:unattended]
    }
    folders.each do |custom_filter_id, conversation_ids|
      memberships[user_folder_key(account_id, user_id, custom_filter_id)] = conversation_ids
    end

    write_membership_sets(memberships)
  end

  private

  def filters_ready_key(account_id, user_id)
    format(Redis::Alfred::UNREAD_CONVERSATIONS_USER_FILTERS_READY, account_id: account_id, user_id: user_id)
  end

  def user_filter_prefix(account_id, user_id)
    "#{account_prefix(account_id)}::USER::#{user_id}"
  end

  def write_membership_sets(memberships)
    memberships = memberships.transform_values { |conversation_ids| Array(conversation_ids).compact_blank }
    memberships = memberships.select { |_key, conversation_ids| conversation_ids.present? }
    return if memberships.blank?

    Redis::Alfred.pipelined do |pipeline|
      memberships.each do |key, conversation_ids|
        conversation_ids.each { |conversation_id| pipeline.sadd(key, conversation_id) }
        pipeline.expire(key, Conversations::UnreadCounts::SET_TTL)
      end
    end
  end
end
