module OnlineStatusTracker
  PRESENCE_EXPIRATION = 90.seconds

  # presence : set expiring keys on every heartbeat request

  def self.update_presence(pubsub_token)
    ::Redis::Alfred.setx(presence_key(pubsub_token), PRESENCE_EXPIRATION, true)
  end

  def self.remove_presence(pubsub_token)
    ::Redis::Alfred.delete(presence_key(pubsub_token))
  end

  def self.get_presence(pubsub_token)
    ::Redis::Alfred.get(presence_key(pubsub_token))
  end

  def self.presence_key(pubsub_token)
    Redis::Alfred::ONLINE_PRESENCE % pubsub_token
  end

  # online status : online | busy | offline

  def self.set_status(pubsub_token, status)
    ::Redis::Alfred.set(status_key(pubsub_token), status)
  end

  def self.get_status(pubsub_token)
    ::Redis::Alfred.get(status_key(pubsub_token))
  end

  def self.status_key(pubsub_token)
    Redis::Alfred::ONLINE_STATUS % pubsub_token
  end
end
