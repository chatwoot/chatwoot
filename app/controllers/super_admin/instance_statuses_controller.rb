class SuperAdmin::InstanceStatusesController < SuperAdmin::ApplicationController
  def show
    @instance_version = get_version
    @instance_sha =  get_sha
    @instance_postgres = get_postgres_status
    @instance_redis = get_redis_status
    @redis_metrics = {}
    get_redis_metrics
  end

  def get_version
    Chatwoot.config[:version]
  end

  def get_sha
    sha = `git rev-parse HEAD`
    if sha.blank?
      return "undefined"
    else
      return zsha
    end
  end

  def get_postgres_status
    if ActiveRecord::Base.connection.active?
      return true
    else
      return false
    end
  end

  def get_redis_status
    r = Redis.new(Redis::Config.app)
    if r.ping == "PONG"
      return true
    else
      return false
    end
  end

  def get_redis_metrics
    r = Redis.new(Redis::Config.app)
    if r.ping == "PONG"
      redis_server = r.info()
      @redis_metrics["Redis version"] = redis_server["redis_version"]
      @redis_metrics["Redis number of connected clients"] = redis_server["connected_clients"]
      @redis_metrics["Redis 'maxclients' setting"] = redis_server["maxclients"]
      @redis_metrics["Redis memory used"] = redis_server["used_memory_human"]
      @redis_metrics["Redis memory peak"] =  redis_server["used_memory_peak_human"]
      @redis_metrics["Redis total memory available"] = redis_server["total_system_memory_human"]
      @redis_metrics["Redis 'maxmemory' setting"] = redis_server["maxmemory"]
      @redis_metrics["Redis 'maxmemory_policy' setting"] = redis_server["maxmemory_policy"]
    end
  end


end
