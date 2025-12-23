module ScoutApm
  module Instruments
    # instrumentation for Rails 3 and Rails 4 is the same.
    class ActionControllerRails3Rails4
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

      def installed!
        @installed = true
      end

      def install(prepend:)
        if !defined?(::ActiveSupport)
          return
        end

        # The block below runs with `self` equal to the ActionController::Base or ::API module, not this class we're in now. By saving an instance of ourselves into the `this` variable, we can continue accessing what we need.
        this = self

        ActiveSupport.on_load(:action_controller) do
          if this.installed?
            this.logger.info("Skipping ActionController - Already Ran")
            next
          else
            this.logger.info("Instrumenting ActionController (on_load)")
            this.installed!
          end

          # We previously instrumented ActionController::Metal, which missed
          # before and after filter timing. Instrumenting Base includes those
          # filters, at the expense of missing out on controllers that don't use
          # the full Rails stack.
          if defined?(::ActionController::Base)
            this.logger.info "Instrumenting ActionController::Base"
            ::ActionController::Base.class_eval do
              include ScoutApm::Instruments::ActionControllerBaseInstruments
            end
          end

          if defined?(::ActionController::Metal)
            this.logger.info "Instrumenting ActionController::Metal"
            ::ActionController::Metal.class_eval do
              include ScoutApm::Instruments::ActionControllerMetalInstruments
            end
          end

          if defined?(::ActionController::API)
            this.logger.info "Instrumenting ActionController::Api"
            ::ActionController::API.class_eval do
              include ScoutApm::Instruments::ActionControllerAPIInstruments
            end
          end
        end

        ScoutApm::Agent.instance.context.logger.info("Instrumenting ActionController (hook installed)")
      end

      # Returns a new anonymous module each time it is called. So
      # we can insert this multiple times into the ancestors
      # stack. Otherwise it only exists the first time you include it
      # (under Metal, instead of under API) and we miss instrumenting
      # before_action callbacks
      def self.build_instrument_module
        Module.new do
          # Determine the URI of this request to capture. Overridable by users in their controller.
          def scout_transaction_uri(config=ScoutApm::Agent.instance.context.config)
            case config.value("uri_reporting")
            when 'path'
              request.path # strips off the query string for more security
            else # default handles filtered params
              request.filtered_path
            end
          end

          def process_action(*args)
            req = ScoutApm::RequestManager.lookup
            current_layer = req.current_layer
            agent_context = ScoutApm::Agent.instance.context

            # Check if this this request is to be reported instantly
            if instant_key = request.cookies['scoutapminstant']
              agent_context.logger.info "Instant trace request with key=#{instant_key} for path=#{path}"
              req.instant_key = instant_key
            end

            # Don't start a new layer if ActionController::API or
            # ActionController::Base handled it already. Needs to account for
            # any layers started during a around_action (most likely
            # AutoInstrument, but could be another custom instrument)
            if current_layer && (current_layer.type == "Controller" || current_layer.type == "AutoInstrument" || req.web?)
              super
            else
              begin
                uri = scout_transaction_uri
                req.annotate_request(:uri => uri)
              rescue
              end

              # IP Spoofing Protection can throw an exception, just move on w/o remote ip
              if agent_context.config.value('collect_remote_ip')
                req.context.add_user(:ip => request.remote_ip) rescue nil
              end
              req.set_headers(request.headers)

              resolved_name = scout_action_name(*args)
              req.start_layer( ScoutApm::Layer.new("Controller", "#{controller_path}/#{resolved_name}") )
              begin
                super
              rescue
                req.error!
                raise
              ensure
                req.stop_layer
              end
            end
          end
        end
      end

    end

    module ActionControllerMetalInstruments
      include ScoutApm::Instruments::ActionControllerRails3Rails4.build_instrument_module

      def scout_action_name(*args)
        action_name = args[0]
      end
    end

    # Empty, noop module to provide compatibility w/ previous manual instrumentation
    module ActionControllerRails3Rails4Instruments
    end

    module ActionControllerBaseInstruments
      include ScoutApm::Instruments::ActionControllerRails3Rails4.build_instrument_module

      def scout_action_name(*args)
        action_name
      end
    end

    module ActionControllerAPIInstruments
      include ScoutApm::Instruments::ActionControllerRails3Rails4.build_instrument_module

      def scout_action_name(*args)
        action_name
      end
    end
  end
end

