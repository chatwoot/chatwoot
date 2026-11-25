class Onboarding::HelpCenterGenerationState
  # TODO: Reduce TTL to 48 hours once the full rollout is done
  TTL = 7.days.to_i

  class Missing < StandardError; end

  class << self
    def start(id, total:)
      Redis::Alfred.with do |conn|
        conn.hset(key(id), 'status', 'generating', 'total', total.to_i, 'finished', 0)
        conn.expire(key(id), TTL)
      end
    end

    def record_article_finished(id)
      Redis::Alfred.with do |conn|
        total = conn.hget(key(id), 'total')
        raise Missing, "missing state for generation #{id}" if total.blank?

        finished = conn.hincrby(key(id), 'finished', 1)
        completed = finished >= total.to_i
        conn.hset(key(id), 'status', 'completed') if completed
        conn.expire(key(id), TTL)
        { finished: finished, completed: completed }
      end
    end

    def skip(id, reason:)
      Redis::Alfred.with do |conn|
        conn.hset(key(id), 'status', 'skipped', 'skip_reason', reason.to_s)
        conn.expire(key(id), TTL)
      end
    end

    def current(id)
      Redis::Alfred.with do |conn|
        conn.hgetall(key(id)).presence
      end
    end

    def key(id)
      format(Redis::Alfred::HELP_CENTER_GENERATION, id: id)
    end
  end
end
