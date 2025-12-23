# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      # Instrument Sinatra.
      module Sinatra
        # Sinatra framework code, used to essentially:
        # - handle configuration entries which are specific to Datadog tracing
        # - instrument parts of the framework when needed
        module Framework
          # Configure Rack from Sinatra, but only if Rack has not been configured manually beforehand
          def self.setup
            Datadog.configure do |datadog_config|
              sinatra_config = config_with_defaults(datadog_config)
              activate_rack!(datadog_config, sinatra_config)
            end
          end

          def self.config_with_defaults(datadog_config)
            datadog_config.tracing[:sinatra]
          end

          # Apply relevant configuration from Sinatra to Rack
          def self.activate_rack!(datadog_config, sinatra_config)
            datadog_config.tracing.instrument(
              :rack,
              service_name: sinatra_config[:service_name],
              distributed_tracing: sinatra_config[:distributed_tracing],
            )
          end

          # Add Rack middleware at the top of the stack
          def self.add_middleware(middleware, builder, *args, &block)
            insert_middleware(builder, middleware, args, block) do |proc_, use|
              use.insert(0, proc_)
            end
          end

          class << self
            alias_method :unshift_middleare, :add_middleware
          end

          # Add Rack middleware at the top of the stack
          def self.append_middleware(middleware, builder, *args, &block)
            insert_middleware(builder, middleware, args, block) do |proc_, use|
              use.append(proc_)
            end
          end

          # Add Rack middleware before another in the stack
          def self.add_middleware_before(before, middleware, builder, *args, &block)
            index = middlewares(builder).index(before)

            raise "middleware #{before} not found" unless index

            insert_middleware(builder, middleware, args, block) do |proc_, use|
              use.insert(index, proc_)
            end
          end

          # Add Rack middleware after another in the the stack
          def self.add_middleware_after(after, middleware, builder, *args, &block)
            index = middlewares(builder).index(after)

            raise "middleware #{after} not found" unless index

            insert_middleware(builder, middleware, args, block) do |proc_, use|
              use.insert(index + 1, proc_)
            end
          end

          # Wrap the middleware class instantiation in a proc, like Sinatra does internally
          # The `middleware` local variable name in the proc is important for introspection
          # (see Framework#middlewares)
          def self.wrap_middleware(middleware, *args, &block)
            proc { |app| middleware.new(app, *args, &block) }
          end

          # Insert a middleware class in the builder as it expects it internally.
          # The block gets passed prepared arguments for the caller to decide
          # how to insert.
          def self.insert_middleware(builder, middleware, args, block)
            use = builder.instance_variable_get('@use')
            wrapped = wrap_middleware(middleware, *args, &block)

            # Makes the insert idempotent
            # The block can also throw :skip with its own logic
            catch(:skip) do
              throw(:skip) if middlewares(builder).include?(middleware)

              yield(wrapped, use)
            end
          end

          def self.include_middleware?(middleware, builder)
            middlewares(builder).include?(middleware)
          end

          # Introspect middlewares from a builder
          def self.middlewares(builder)
            builder.instance_variable_get(:@use).map do |proc_|
              next :unknown unless proc_.respond_to?(:binding) && proc_.binding.local_variable_defined?(:middleware)

              proc_.binding.local_variable_get(:middleware)
            end
          end

          def self.inspect_middlewares(builder)
            Datadog.logger.debug { +'Sinatra middlewares: ' << middlewares(builder).map(&:inspect).inspect }
          end
        end
      end
    end
  end
end
