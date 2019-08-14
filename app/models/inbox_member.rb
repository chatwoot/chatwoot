class InboxMember < ApplicationRecord

  validates :inbox_id, presence: true
  validates :user_id, presence: true

  belongs_to :user
  belongs_to :inbox

  after_commit :add_agent_to_round_robin, on: [:create]
  after_commit :remove_agent_from_round_robin, on: [:destroy]

  private

  def add_agent_to_round_robin
    Redis::Alfred.lpush(round_robin_key, self.user_id)
  end

  def remove_agent_from_round_robin
    Redis::Alfred.lrem(round_robin_key, self.user_id)
  end

  def round_robin_key
    Constants::RedisKeys::ROUND_ROBIN_AGENTS % { :inbox_id => self.inbox_id }
  end

end
