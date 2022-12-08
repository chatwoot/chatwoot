class SuperAdmin::InstanceStatusesController < SuperAdmin::ApplicationController
  def show
    @instance_version = get_version
    @instance_sha =  get_sha
    @instance_postgres = get_postgres_status
    @instance_redis = get_redis_status
  end

  def get_version
    Chatwoot.config[:version]
  end

  def get_sha
    sha = `git rev-parse HEAD`
    if sha.blank?
      return "undefined"
    else
      return sha
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

end
