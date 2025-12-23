module ScoutApm
  module Instruments
    class Redis
      attr_reader :context

      def initialize(context)
        @context = context
        @installed = false
      end

      def logger
        context.logger
      end

      def installed?
        @installed
      end

      def install(prepend:)
        if defined?(::Redis) && defined?(::Redis::Client) && ::Redis::Client.instance_methods(false).include?(:call)
          @installed = true

          logger.info "Instrumenting Redis. Prepend: #{prepend}"

          if prepend
            ::Redis::Client.send(:include, ScoutApm::Tracer)
            ::Redis::Client.send(:prepend, RedisClientInstrumentationPrepend)
          else
            ::Redis::Client.class_eval do
              include ScoutApm::Tracer

              def call_with_scout_instruments(*args, &block)
                command = args.first.first rescue "Unknown"

                self.class.instrument("Redis", command) do
                  call_without_scout_instruments(*args, &block)
                end
              end

              alias_method :call_without_scout_instruments, :call
              alias_method :call, :call_with_scout_instruments
            end
          end
        end
      end
    end

    module RedisClientInstrumentationPrepend
      def call(*args, &block)
        command = args.first.first rescue "Unknown"

        self.class.instrument("Redis", command) do
          super(*args, &block)
        end
      end
    end
  end
end
