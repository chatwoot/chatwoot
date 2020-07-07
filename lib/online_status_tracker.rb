module OnlineStatusTracker
  PRESENCE_DURATION = 60.seconds

  # presence : sorted set with timestamp as the score & object id as value

  # obj_type: Contact | User
  def self.update_presence(account_id, obj_type, obj_id)
    ::Redis::Alfred.zadd(presence_key(account_id, obj_type), Time.now.to_i, obj_id)
  end

  def self.get_presence(account_id, obj_type, obj_id)
    connected_time = ::Redis::Alfred.zscore(presence_key(account_id, obj_type), obj_id)
    connected_time && connected_time > (Time.zone.now - PRESENCE_DURATION).to_i
  end

  def self.presence_key(account_id, type)
    case type
    when 'Contact'
      format(::Redis::Alfred::ONLINE_PRESENCE_CONTACTS, account_id: account_id)
    else
      format(::Redis::Alfred::ONLINE_PRESENCE_USERS, account_id: account_id)
    end
  end

  # online status : online | busy | offline
  # redis hash with obj_id key && status as value

  def self.set_status(account_id, user_id, status)
    ::Redis::Alfred.hset(status_key(account_id), user_id, status)
  end

  def self.get_status(account_id, user_id)
    ::Redis::Alfred.hget(status_key(account_id), user_id)
  end

  def self.status_key(account_id)
    format(::Redis::Alfred::ONLINE_STATUS, account_id: account_id)
  end

  def self.get_available_contacts(account_id)
    contact_ids = ::Redis::Alfred.zrangebyscore(presence_key(account_id, 'Contact'), (Time.zone.now - PRESENCE_DURATION).to_i, Time.now.to_i)
    contact_ids.index_with { |_id| 'online' }
  end

  def self.get_available_users(account_id)
    user_ids = ::Redis::Alfred.zrangebyscore(presence_key(account_id, 'User'), (Time.zone.now - PRESENCE_DURATION).to_i, Time.now.to_i)
    return {} if user_ids.blank?

    user_availabilities = ::Redis::Alfred.hmget(status_key(account_id), user_ids)
    user_ids.map.with_index { |id, index| [id, (user_availabilities[index] || 'online')] }.to_h
  end
end
