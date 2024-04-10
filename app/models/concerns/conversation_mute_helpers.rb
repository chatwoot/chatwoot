module ConversationMuteHelpers
  extend ActiveSupport::Concern

  def mute!
    resolved!
    Redis::Alfred.setex(mute_key, 1, mute_period)
    create_muted_message
  end

  def unmute!
    Redis::Alfred.delete(mute_key)
    create_unmuted_message
  end

  def muted?
    Redis::Alfred.get(mute_key).present?
  end

  private

  def mute_key
    format(Redis::RedisKeys::CONVERSATION_MUTE_KEY, id: id)
  end

  def mute_period
    6.hours
  end
end
