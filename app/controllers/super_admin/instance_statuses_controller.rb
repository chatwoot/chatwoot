class SuperAdmin::InstanceStatusesController < SuperAdmin::ApplicationController
  def show
    @metrics = {}
    get_chatwoot_version
    get_sha
    get_postgres_status
    get_redis_metrics
  end

  def get_chatwoot_version
    @metrics["Chatwoot version"] = Chatwoot.config[:version]
  end

  def get_sha
    sha = `git rev-parse HEAD`
    if sha.blank?
      @metrics["Git SHA"] = "n/a"
    else
      @metrics["Git SHA"] = sha
    end
  end

  def get_postgres_status
    if ActiveRecord::Base.connection.active?
      @metrics["Postgres alive"] = "true"
    else
      @metrics["Postgres alive"] = "false"
    end
  end

  def get_redis_status
    r = Redis.new(Redis::Config.app)
    if r.ping == "PONG"
      @metrics["Redis alive"] = "false"
    else
      @metrics["Redis alive"] = "false"
    end
  end

  def get_redis_metrics
    r = Redis.new(Redis::Config.app)
    if r.ping == "PONG"
      redis_server = r.info()
      @metrics["Redis alive"] = "false"
      @metrics["Redis version"] = redis_server["redis_version"]
      @metrics["Redis number of connected clients"] = redis_server["connected_clients"]
      @metrics["Redis 'maxclients' setting"] = redis_server["maxclients"]
      @metrics["Redis memory used"] = redis_server["used_memory_human"]
      @metrics["Redis memory peak"] =  redis_server["used_memory_peak_human"]
      @metrics["Redis total memory available"] = redis_server["total_system_memory_human"]
      @metrics["Redis 'maxmemory' setting"] = redis_server["maxmemory"]
      @metrics["Redis 'maxmemory_policy' setting"] = redis_server["maxmemory_policy"]
    else
      @metrics["Redis alive"] = "false"
    end
  end


end
