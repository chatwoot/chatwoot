# frozen_string_literal: true

module Aws
  module Plugins
    # @api private
    class EndpointDiscovery < Seahorse::Client::Plugin

      option(:endpoint_discovery,
        doc_default: Proc.new { |options| options[:require_endpoint_discovery] },
        doc_type: 'Boolean',
        docstring: <<-DOCS) do |cfg|
When set to `true`, endpoint discovery will be enabled for operations when available.
        DOCS
        resolve_endpoint_discovery(cfg)
      end

      option(:endpoint_cache_max_entries,
        default: 1000,
        doc_type: Integer,
        docstring: <<-DOCS
Used for the maximum size limit of the LRU cache storing endpoints data
for endpoint discovery enabled operations. Defaults to 1000.
        DOCS
      )

      option(:endpoint_cache_max_threads,
        default: 10,
        doc_type: Integer,
        docstring: <<-DOCS
Used for the maximum threads in use for polling endpoints to be cached, defaults to 10.
        DOCS
      )

      option(:endpoint_cache_poll_interval,
        default: 60,
        doc_type: Integer,
        docstring: <<-DOCS
When :endpoint_discovery and :active_endpoint_cache is enabled,
Use this option to config the time interval in seconds for making
requests fetching endpoints information. Defaults to 60 sec.
        DOCS
      )

      option(:endpoint_cache) do |cfg|
        Aws::EndpointCache.new(
          max_entries: cfg.endpoint_cache_max_entries,
          max_threads: cfg.endpoint_cache_max_threads
        )
      end

      option(:active_endpoint_cache,
        default: false,
        doc_type: 'Boolean',
        docstring: <<-DOCS
When set to `true`, a thread polling for endpoints will be running in
the background every 60 secs (default). Defaults to `false`.
        DOCS
      )

      def add_handlers(handlers, config)
        handlers.add(Handler, priority: 90) if config.regional_endpoint
      end

      class Handler < Seahorse::Client::Handler

        def call(context)
          if context.operation.endpoint_operation
            context.http_request.headers['x-amz-api-version'] = context.config.api.version
            _apply_endpoint_discovery_user_agent(context)
          elsif discovery_cfg = context.operation.endpoint_discovery
            endpoint = _discover_endpoint(
              context,
              Aws::Util.str_2_bool(discovery_cfg["required"])
            )
            if endpoint
              context.http_request.endpoint = _valid_uri(endpoint.address)
              # Skips dynamic endpoint usage, use this endpoint instead
              context[:discovered_endpoint] = true
            end
            if endpoint || context.config.endpoint_discovery
              _apply_endpoint_discovery_user_agent(context)
            end
          end
          @handler.call(context)
        end

        private

        def _valid_uri(address)
          # returned address can be missing scheme
          if address.start_with?('http')
            URI.parse(address)
          else
            URI.parse("https://" + address)
          end
        end

        def _apply_endpoint_discovery_user_agent(ctx)
          if ctx.config.user_agent_suffix.nil?
            ctx.config.user_agent_suffix = "endpoint-discovery"
          elsif !ctx.config.user_agent_suffix.include? "endpoint-discovery"
            ctx.config.user_agent_suffix += "endpoint-discovery"
          end
        end

        def _discover_endpoint(ctx, required)
          cache = ctx.config.endpoint_cache
          key = cache.extract_key(ctx)

          if required
            unless ctx.config.endpoint_discovery
              raise ArgumentError, "Operation #{ctx.operation.name} requires "\
                'endpoint_discovery to be enabled.'
            end
            # required for the operation
            unless cache.key?(key)
              cache.update(key, ctx)
            end
            endpoint = cache[key]
            # hard fail if endpoint is not discovered
            raise Aws::Errors::EndpointDiscoveryError.new unless endpoint
            endpoint
          elsif ctx.config.endpoint_discovery
            # not required for the operation
            # but enabled
            if cache.key?(key)
              cache[key]
            elsif ctx.config.active_endpoint_cache
              # enabled active cache pull
              interval = ctx.config.endpoint_cache_poll_interval
              if key.include?('_')
                # identifier related, kill the previous polling thread by key
                # because endpoint req params might be changed
                cache.delete_polling_thread(key)
              end

              # start a thread for polling endpoints when non-exist
              unless cache.threads_key?(key)
                thread = Thread.new do
                  while !cache.key?(key) do
                    cache.update(key, ctx)
                    sleep(interval)
                  end
                end
                cache.update_polling_pool(key, thread)
              end

              cache[key]
            else
              # disabled active cache pull
              # attempt, buit fail soft
              cache.update(key, ctx)
              cache[key]
            end
          end
        end

      end

      private

      def self.resolve_endpoint_discovery(cfg)
        env = ENV['AWS_ENABLE_ENDPOINT_DISCOVERY']
        default = cfg.api.require_endpoint_discovery
        shared_cfg = Aws.shared_config.endpoint_discovery_enabled(profile: cfg.profile)
        resolved = Aws::Util.str_2_bool(env) || Aws::Util.str_2_bool(shared_cfg)
        env.nil? && shared_cfg.nil? ? default : !!resolved
      end

    end
  end
end
