class SuperAdmin::InstanceStatusesController < SuperAdmin::ApplicationController
  def show
    @metrics = {}
    chatwoot_version
    sha
    postgres_status
    redis_metrics
  end

  def chatwoot_version
    @metrics['Chatwoot version'] = Chatwoot.config[:version]
  end

  def sha
    sha = `git rev-parse HEAD`
    @metrics['Git SHA'] = sha.presence || 'n/a'
  end

  def postgres_status
    @metrics['Postgres alive'] = if ActiveRecord::Base.connection.active?
                                   'true'
                                 else
                                   'false'
                                 end
  end

  def redis_metrics
    r = Redis.new(Redis::Config.app)
    if r.ping == 'PONG'
      redis_server = r.info
      @metrics['Redis alive'] = 'true'
      @metrics['Redis version'] = redis_server['redis_version']
      @metrics['Redis number of connected clients'] = redis_server['connected_clients']
      @metrics["Redis 'maxclients' setting"] = redis_server['maxclients']
      @metrics['Redis memory used'] = redis_server['used_memory_human']
      @metrics['Redis memory peak'] = redis_server['used_memory_peak_human']
      @metrics['Redis total memory available'] = redis_server['total_system_memory_human']
      @metrics["Redis 'maxmemory' setting"] = redis_server['maxmemory']
      @metrics["Redis 'maxmemory_policy' setting"] = redis_server['maxmemory_policy']
    end
  rescue Redis::CannotConnectError
    @metrics['Redis alive'] = false
  end
end
