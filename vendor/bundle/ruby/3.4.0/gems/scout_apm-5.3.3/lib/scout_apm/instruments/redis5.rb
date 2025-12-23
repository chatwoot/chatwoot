module ScoutApm
    module Instruments
      class Redis5
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
          if defined?(::Redis) && defined?(::Redis::Client) && ::Redis::Client.instance_methods(false).include?(:call_v)
            @installed = true
  
            logger.info "Instrumenting Redis5. Prepend: #{prepend}"
  
            if prepend
              ::Redis::Client.send(:include, ScoutApm::Tracer)
              ::Redis::Client.send(:prepend, Redis5ClientInstrumentationPrepend)
            else
              ::Redis::Client.class_eval do
                include ScoutApm::Tracer
  
                def call_with_scout_instruments(args, &block)
                  command = args.first rescue "Unknown"
  
                  self.class.instrument("Redis", command) do
                    call_without_scout_instruments(args, &block)
                  end
                end
  
                alias_method :call_without_scout_instruments, :call_v
                alias_method :call_v, :call_with_scout_instruments
              end
            end
          end
        end
      end
  
      module Redis5ClientInstrumentationPrepend
        def call(args, &block)
          command = args.first rescue "Unknown"
  
          self.class.instrument("Redis", command) do
            super(args, &block)
          end
        end
      end
    end
  end
  