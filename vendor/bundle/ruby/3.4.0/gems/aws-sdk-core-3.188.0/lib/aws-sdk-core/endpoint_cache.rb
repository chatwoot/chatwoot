# frozen_string_literal: true

module Aws
  # @api private
  # a LRU cache caching endpoints data
  class EndpointCache

    # default cache entries limit
    MAX_ENTRIES = 1000

    # default max threads pool size
    MAX_THREADS = 10

    def initialize(options = {})
      @max_entries = options[:max_entries] || MAX_ENTRIES
      @entries = {} # store endpoints
      @max_threads = options[:max_threads] || MAX_THREADS
      @pool = {} # store polling threads
      @mutex = Mutex.new
      @require_identifier = nil # whether endpoint operation support identifier
    end

    # @return [Integer] Max size limit of cache
    attr_reader :max_entries

    # @return [Integer] Max count of polling threads
    attr_reader :max_threads

    # return [Hash] Polling threads pool
    attr_reader :pool

    # @param [String] key
    # @return [Endpoint]
    def [](key)
      @mutex.synchronize do
        # fetching an existing endpoint delete it and then append it
        endpoint = @entries[key]
        if endpoint
          @entries.delete(key)
          @entries[key] = endpoint
        end
        endpoint
      end
    end

    # @param [String] key
    # @param [Hash] value
    def []=(key, value)
      @mutex.synchronize do
        # delete the least recent used endpoint when cache is full
        unless @entries.size < @max_entries
          old_key, = @entries.shift
          delete_polling_thread(old_key)
        end
        # delete old value if exists
        @entries.delete(key)
        @entries[key] = Endpoint.new(value.to_hash)
      end
    end

    # checking whether an unexpired endpoint key exists in cache
    # @param [String] key
    # @return [Boolean]
    def key?(key)
      @mutex.synchronize do
        if @entries.key?(key) && (@entries[key].nil? || @entries[key].expired?)
          @entries.delete(key)
        end
        @entries.key?(key)
      end
    end

    # checking whether an polling thread exist for the key
    # @param [String] key
    # @return [Boolean]
    def threads_key?(key)
      @pool.key?(key)
    end

    # remove entry only
    # @param [String] key
    def delete(key)
      @mutex.synchronize do
        @entries.delete(key)
      end
    end

    # kill the old polling thread and remove it from pool
    # @param [String] key
    def delete_polling_thread(key)
      Thread.kill(@pool[key]) if threads_key?(key)
      @pool.delete(key)
    end

    # update cache with requests (using service endpoint operation)
    # to fetch endpoint list (with identifiers when available)
    # @param [String] key
    # @param [RequestContext] ctx
    def update(key, ctx)
      resp = _request_endpoint(ctx)
      if resp && resp.endpoints
        resp.endpoints.each { |e| self[key] = e }
      end
    end

    # extract the key to be used in the cache from request context
    # @param [RequestContext] ctx
    # @return [String]
    def extract_key(ctx)
      parts = []
      # fetching from cred provider directly gives warnings
      parts << ctx.config.credentials.credentials.access_key_id
      if _endpoint_operation_identifier(ctx)
        parts << ctx.operation_name
        ctx.operation.input.shape.members.inject(parts) do |p, (name, ref)|
          p << ctx.params[name] if ref['endpointdiscoveryid']
          p
        end
      end
      parts.join('_')
    end

    # update polling threads pool
    # param [String] key
    # param [Thread] thread
    def update_polling_pool(key, thread)
      unless @pool.size < @max_threads
        _, thread = @pool.shift
        Thread.kill(thread)
      end
      @pool[key] = thread
    end

    # kill all polling threads
    def stop_polling!
      @pool.each { |_, t| Thread.kill(t) }
      @pool = {}
    end

    private

    def _request_endpoint(ctx)
      params = {}
      if _endpoint_operation_identifier(ctx)
        # build identifier params when available
        params[:operation] = ctx.operation.name
        ctx.operation.input.shape.members.inject(params) do |p, (name, ref)|
          if ref['endpointdiscoveryid']
            p[:identifiers] ||= {}
            p[:identifiers][ref.location_name] = ctx.params[name]
          end
          p
        end
      end

      begin
        endpoint_operation_name = ctx.config.api.endpoint_operation
        ctx.client.send(endpoint_operation_name, params)
      rescue Aws::Errors::ServiceError
        nil
      end
    end

    def _endpoint_operation_identifier(ctx)
      return @require_identifier unless @require_identifier.nil?

      operation_name = ctx.config.api.endpoint_operation
      operation = ctx.config.api.operation(operation_name)
      @require_identifier = operation.input.shape.members.any?
    end

    class Endpoint

      # default endpoint cache time, 1 minute
      CACHE_PERIOD = 1

      def initialize(options)
        @address = options.fetch(:address)
        @cache_period = options[:cache_period_in_minutes] || CACHE_PERIOD
        @created_time = Time.now
      end

      # [String] valid URI address (with path)
      attr_reader :address

      def expired?
        Time.now - @created_time > @cache_period * 60
      end

    end

  end
end
