class Onboarding::HelpCenterGenerationCounter
  TTL = 7.days.to_i

  class Missing < StandardError; end

  class << self
    def create!(generation_id, total:)
      Redis::Alfred.with do |conn|
        conn.hset(key(generation_id), 'total', total.to_i)
        conn.hset(key(generation_id), 'finished', 0)
        conn.expire(key(generation_id), TTL)
      end
    end

    def record_finished!(generation_id)
      Redis::Alfred.with do |conn|
        total = conn.hget(key(generation_id), 'total')
        raise Missing, "missing help center generation counter #{generation_id}" if total.blank?

        finished = conn.hincrby(key(generation_id), 'finished', 1)
        conn.expire(key(generation_id), TTL)

        { finished: finished, completed: finished == total.to_i }
      end
    end

    def key(generation_id)
      format(Redis::Alfred::HELP_CENTER_GENERATION_COUNT, id: generation_id)
    end
  end
end
