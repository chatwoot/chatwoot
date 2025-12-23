# frozen_string_literal: true

# riak-client 2.2.2 patches
class Riak::Multiget
  class << self
    alias_method :get_all_without_profiling, :get_all
    def get_all(client, fetch_list)
      return get_all_without_profiling(client, fetch_list) unless SqlPatches.should_measure?

      start        = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result       = get_all_without_profiling(client, fetch_list)
      elapsed_time = SqlPatches.elapsed_time(start)
      record       = ::Rack::MiniProfiler.record_sql("get_all size=#{fetch_list.size}", elapsed_time)

      result
    end
  end
end

class Riak::Client

  alias_method :buckets_without_profiling, :buckets
  def buckets(options = {}, &blk)
    profile("buckets #{options}") { buckets_without_profiling(options, &blk) }
  end

  alias_method :client_id_without_profiling, :client_id
  def client_id
    profile("client_id") { client_id_without_profiling }
  end

  alias_method :delete_object_without_profiling, :delete_object
  def delete_object(bucket, key, options = {})
    profile("delete_object bucket=#{bucket.name} key=#{key} options=#{options}") { delete_object_without_profiling(bucket, key, options) }
  end

  alias_method :get_bucket_props_without_profiling, :get_bucket_props
  def get_bucket_props(bucket, options = {})
    profile("get_bucket_props bucket=#{bucket.name} options=#{options}") { get_bucket_props_without_profiling(bucket, options) }
  end

  alias_method :get_index_without_profiling, :get_index
  def get_index(bucket, index, query, options = {})
    profile("get_index bucket=#{bucket.name} index=#{index} query=#{query} options=#{options}") { get_index_without_profiling(bucket, index, query, options) }
  end

  alias_method :get_preflist_without_profiling, :get_preflist
  def get_preflist(bucket, key, type = nil, options = {})
    profile("get_preflist bucket=#{bucket.name} key=#{key} type=#{type} options=#{options}") { get_preflist_without_profiling(bucket, key, type, options) }
  end

  alias_method :get_object_without_profiling, :get_object
  def get_object(bucket, key, options = {})
    profile("get_object bucket=#{bucket.name} key=#{key} options=#{options}") { get_object_without_profiling(bucket, key, options) }
  end

  alias_method :list_keys_without_profiling, :list_keys
  def list_keys(bucket, options = {}, &block)
    profile("list_keys bucket=#{bucket.name} options=#{options}") { list_keys_without_profiling(bucket, options, &block) }
  end

  alias_method :mapred_without_profiling, :mapred
  def mapred(mr, &block)
    profile("mapred") { mapred_without_profiling(mr, &block) }
  end

  alias_method :ping_without_profiling, :ping
  def ping
    profile("ping") { ping_without_profiling }
  end

  alias_method :reload_object_without_profiling, :reload_object
  def reload_object(object, options = {})
    profile("reload_object bucket=#{object.bucket.name} key=#{object.key} vclock=#{object.vclock} options=#{options}") { reload_object_without_profiling(object, options) }
  end

  alias_method :set_bucket_props_without_profiling, :set_bucket_props
  def set_bucket_props(bucket, properties, type = nil)
    profile("set_bucket_props bucket=#{bucket.name} type=#{type}") { set_bucket_props_without_profiling(bucket, properties, type) }
  end

  alias_method :clear_bucket_props_without_profiling, :clear_bucket_props
  def clear_bucket_props(bucket, options = {})
    profile("clear_bucket_props bucket=#{bucket.name} options=#{options}") { clear_bucket_props_without_profiling(bucket, options) }
  end

  alias_method :store_object_without_profiling, :store_object
  def store_object(object, options = {})
    profile("store_object bucket=#{object.bucket.name} key=#{object.key} vclock=#{object.vclock} options=#{options}") { store_object_without_profiling(object, options) }
  end

  private

  def profile(request, &blk)
    return yield unless SqlPatches.should_measure?

    start        = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result       = yield
    elapsed_time = SqlPatches.elapsed_time(start)
    record       = ::Rack::MiniProfiler.record_sql(request, elapsed_time)

    result
  end

end
