module ScoutApm
  module Instruments
    class ActionControllerRails2
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
        if defined?(::ActionController) && defined?(::ActionController::Base)
          @installed = true

          ::ActionController::Base.class_eval do
            include ScoutApm::Tracer
            include ::ScoutApm::Instruments::ActionControllerRails2Instruments
          end

          logger.info "Instrumenting ActionView::Template"
          ::ActionView::Template.class_eval do
            include ::ScoutApm::Tracer
            instrument_method :render, :type => "View", :name => '#{path[%r{^(/.*/)?(.*)$},2]}/Rendering', :scope => true
          end
        end

      end
    end

    module ActionControllerRails2Instruments
      def self.included(instrumented_class)
        # XXX: Don't lookup context by global
        ScoutApm::Agent.instance.context.logger.info "Instrumenting #{instrumented_class.inspect}"
        instrumented_class.class_eval do
          unless instrumented_class.method_defined?(:perform_action_without_scout_instruments)
            alias_method :perform_action_without_scout_instruments, :perform_action
            alias_method :perform_action, :perform_action_with_scout_instruments
            private :perform_action
          end
        end
      end

      # In addition to instrumenting actions, this also sets the scope to the controller action name. The scope is later
      # applied to metrics recorded during this transaction. This lets us associate ActiveRecord calls with
      # specific controller actions.
      def perform_action_with_scout_instruments(*args, &block)
        req = ScoutApm::RequestManager.lookup
        req.annotate_request(:uri => request.path) # for security by-default, we don't use request.fullpath which could reveal filtered params.
        if ScoutApm::Agent.instance.context.config.value('collect_remote_ip')
          req.context.add_user(:ip => request.remote_ip)
        end
        req.set_headers(request.headers)
        req.start_layer( ScoutApm::Layer.new("Controller", "#{controller_path}/#{action_name}") )

        begin
          perform_action_without_scout_instruments(*args, &block)
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

