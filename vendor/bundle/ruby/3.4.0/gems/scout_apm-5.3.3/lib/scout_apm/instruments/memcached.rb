module ScoutApm
  module Instruments
    class Memcached
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
        if defined?(::Dalli) && defined?(::Dalli::Client)
          @installed = true

          logger.info "Instrumenting Memcached. Prepend: #{prepend}"

          if prepend
            ::Dalli::Client.send(:include, ScoutApm::Tracer)
            ::Dalli::Client.send(:prepend, MemcachedInstrumentationPrepend)
          else
            ::Dalli::Client.class_eval do
              include ScoutApm::Tracer

              def perform_with_scout_instruments(*args, &block)
                command = args.first rescue "Unknown"

                self.class.instrument("Memcached", command) do
                  perform_without_scout_instruments(*args, &block)
                end
              end

              alias_method :perform_without_scout_instruments, :perform
              alias_method :perform, :perform_with_scout_instruments
            end
          end
        end
      end
    end

    module MemcachedInstrumentationPrepend
      def perform(*args, &block)
        command = args.first rescue "Unknown"

        self.class.instrument("Memcached", command) do
          super(*args, &block)
        end
      end
    end
  end
end
