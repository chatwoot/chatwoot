class SuperAdmin::InstanceStatusesController < SuperAdmin::ApplicationController
  def show
    @metrics = {}
    # CommMate: Add CommMate-specific version info
    if defined?(COMMMATE_VERSION)
      commmate_version
      chatwoot_base_version
    else
      chatwoot_version
    end
    sha
    postgres_status
    redis_metrics
    chatwoot_edition
    instance_meta
  end

  def chatwoot_edition
    @metrics['Chatwoot edition'] = if ChatwootApp.enterprise?
                                     'Enterprise'
                                   elsif ChatwootApp.custom?
                                     'Custom'
                                   else
                                     'Community'
                                   end
  end

  def instance_meta
    @metrics['Database Migrations'] = ActiveRecord::Base.connection.migration_context.needs_migration? ? 'pending' : 'completed'
  end

  def chatwoot_version
    @metrics['Chatwoot version'] = Chatwoot.config[:version]
  end

  # CommMate: Enhanced SHA method to show both CommMate and Chatwoot git SHAs
  def sha
    if defined?(COMMMATE_VERSION)
      @metrics['CommMate Git SHA'] = GIT_HASH
      @metrics['Chatwoot Base Git SHA'] = CHATWOOT_GIT_HASH if defined?(CHATWOOT_GIT_HASH) && CHATWOOT_GIT_HASH != GIT_HASH
    else
      @metrics['Git SHA'] = GIT_HASH
    end
  end

  # CommMate: Additional version methods
  def commmate_version
    @metrics['CommMate version'] = COMMMATE_VERSION
  end

  def chatwoot_base_version
    @metrics['Base Chatwoot version'] = COMMMATE_BASE_VERSION
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
