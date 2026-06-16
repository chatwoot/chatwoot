module Conversations::UnreadCounts::UserFilterStore
  USER_FILTER_KEY_SUFFIXES = [
    'READY::FILTERS',
    'MENTIONS',
    'PARTICIPATING',
    'UNATTENDED',
    'FOLDER::*'
  ].freeze

  def filters_ready?(account_id, user_id)
    Redis::Alfred.exists?(filters_ready_key(account_id, user_id))
  end

  def mark_filters_ready!(account_id, user_id, expires_in: Conversations::UnreadCounts::READY_TTL)
    Redis::Alfred.set(filters_ready_key(account_id, user_id), Time.current.to_i, ex: expires_in)
  end

  def mark_filters_ready_if_current!(account_id, user_id, version_snapshot:, expires_in: Conversations::UnreadCounts::READY_TTL)
    return false unless filter_version_snapshot(account_id, user_id) == version_snapshot

    mark_filters_ready!(account_id, user_id, expires_in: expires_in)
  end

  def filter_version_snapshot(account_id, user_id)
    {
      account: filter_version(account_filter_version_key(account_id)),
      user: filter_version(user_filter_version_key(account_id, user_id))
    }
  end

  def clear_filter_caches!(account_id)
    bump_filter_version(account_filter_version_key(account_id))
    delete_user_filter_patterns("#{account_prefix(account_id)}::USER::*")
  end

  def clear_user_filters!(account_id, user_id)
    bump_filter_version(user_filter_version_key(account_id, user_id))
    delete_user_filter_patterns(user_filter_prefix(account_id, user_id))
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

  def account_filter_version_key(account_id)
    format(Redis::Alfred::UNREAD_CONVERSATIONS_FILTERS_VERSION, account_id: account_id)
  end

  def user_filter_version_key(account_id, user_id)
    format(Redis::Alfred::UNREAD_CONVERSATIONS_USER_FILTERS_VERSION, account_id: account_id, user_id: user_id)
  end

  def user_filter_prefix(account_id, user_id)
    "#{account_prefix(account_id)}::USER::#{user_id}"
  end

  def filter_version(key)
    Redis::Alfred.get(key).to_i
  end

  def bump_filter_version(key)
    Redis::Alfred.incr(key).tap { Redis::Alfred.expire(key, Conversations::UnreadCounts::SET_TTL) }
  end

  def delete_user_filter_patterns(prefix)
    deleted = false
    USER_FILTER_KEY_SUFFIXES.each do |suffix|
      deleted = delete_matching("#{prefix}::#{suffix}") || deleted
    end
    deleted
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
