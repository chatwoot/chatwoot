# frozen_string_literal: true

require_relative '../../../core/utils/only_once'
require_relative '../rack/middlewares'
require_relative 'framework'
require_relative 'log_injection'
require_relative 'middlewares'
require_relative 'runner'
require_relative '../../../core/contrib/rails/utils'
require_relative '../semantic_logger/patcher'

module Datadog
  module Tracing
    module Contrib
      module Rails
        # Patcher enables patching of 'rails' module.
        module Patcher
          include Contrib::Patcher

          BEFORE_INITIALIZE_ONLY_ONCE_PER_APP = Hash.new { |h, key| h[key] = Core::Utils::OnlyOnce.new }
          AFTER_INITIALIZE_ONLY_ONCE_PER_APP = Hash.new { |h, key| h[key] = Core::Utils::OnlyOnce.new }

          module_function

          def target_version
            Integration.version
          end

          def patch
            patch_before_initialize
            patch_after_initialize
            patch_rails_runner
          end

          def patch_before_initialize
            ::ActiveSupport.on_load(:before_initialize) do
              Contrib::Rails::Patcher.before_initialize(self)
            end
          end

          def before_initialize(app)
            BEFORE_INITIALIZE_ONLY_ONCE_PER_APP[app].run do
              # Middleware must be added before the application is initialized.
              # Otherwise the middleware stack will be frozen.
              add_middleware(app) if Datadog.configuration.tracing[:rails][:middleware]

              Rails::LogInjection.configure_log_tags(app.config)
            end
          end

          def add_middleware(app)
            # Add trace middleware at the top of the middleware stack,
            # to ensure we capture the complete execution time.
            app.middleware.insert_before(0, Contrib::Rack::TraceMiddleware)

            # Some Rails middleware can swallow an application error, preventing
            # the error propagation to the encompassing Rack span.
            #
            # We insert our own middleware right before these Rails middleware
            # have a chance to swallow the error.
            #
            # Note: because the middleware stack is push/pop, "before" and "after" are reversed
            # for our use case: we insert ourselves with "after" a middleware to ensure we are
            # able to pop the request "before" it.
            app.middleware.insert_after(::ActionDispatch::DebugExceptions, Contrib::Rails::ExceptionMiddleware)
          end

          def patch_after_initialize
            ::ActiveSupport.on_load(:after_initialize) do
              Contrib::Rails::Patcher.after_initialize(self)
            end
          end

          def after_initialize(app)
            AFTER_INITIALIZE_ONLY_ONCE_PER_APP[app].run do
              # Finish configuring the tracer after the application is initialized.
              # We need to wait for some things, like application name, middleware stack, etc.
              setup_tracer
            end
          end

          # Configure Rails tracing with settings
          def setup_tracer
            Contrib::Rails::Framework.setup
          end

          # Instruments the `bin/rails runner` command.
          def patch_rails_runner
            # The `RunnerCommand` class is only available in Rails 5.1 and later.
            if defined?(::Rails::Command::RunnerCommand) && Integration.version >= Gem::Version.new('5.1')
              ::Rails::Command::RunnerCommand.prepend(Runner)
            end
          end
        end
      end
    end
  end
end
