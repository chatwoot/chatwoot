module OnlineStatusTracker
  def self.add_subscription(channel_id)
    count = subscription_count(channel_id)
    ::Redis::Alfred.setex(channel_id, count + 1)
  end

  def self.remove_subscription(channel_id)
    count = subscription_count(channel_id)
    if count == 1
      ::Redis::Alfred.delete(channel_id)
    elsif count != 0
      ::Redis::Alfred.setex(channel_id, count - 1)
    end
  end

  def self.subscription_count(channel_id)
    ::Redis::Alfred.get(channel_id).to_i
  end
end
