class CreateRoundRobin < ActiveRecord::Migration[5.0]
  def change
    InboxMember.find_each do |im|
      round_robin_key = format(::Redis::Alfred::ROUND_ROBIN_AGENTS, inbox_id: im.inbox_id)
      Redis::Alfred.lpush(round_robin_key, im.user_id)
    end
  end
end
