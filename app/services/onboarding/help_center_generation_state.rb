class Onboarding::HelpCenterGenerationState
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

        # Automatically increment finished count and check if completed
        # https://redis.io/docs/latest/commands/hincrby/
        finished = conn.hincrby(key(id), 'finished', 1)
        completed = finished == total.to_i
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

    def mark_active(id, account_id:)
      Redis::Alfred.with { |conn| conn.set(account_pointer_key(account_id), id, ex: TTL) }
    end

    def superseded?(id, account_id:)
      active = Redis::Alfred.with { |conn| conn.get(account_pointer_key(account_id)) }
      active.present? && active != id
    end

    def key(id)
      format(Redis::Alfred::HELP_CENTER_GENERATION, id: id)
    end

    def account_pointer_key(account_id)
      format(Redis::Alfred::HELP_CENTER_GENERATION_CURRENT, account_id: account_id)
    end
  end
end
