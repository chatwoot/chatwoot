# frozen_string_literal: true

require_relative '../contrib'
require_relative 'extensions'

module Datadog
  module Tracing
    # Out-of-the-box instrumentation for tracing
    module Contrib
      # Auto-activate instrumentation
      def self.auto_instrument!
        require_relative '../../core/contrib/rails/utils'

        # Defer to Rails if this is a Rails application
        if Datadog::Core::Contrib::Rails::Utils.railtie_supported?
          require_relative 'rails/auto_instrument_railtie'
        else
          AutoInstrument.patch_all!
        end
      end

      # Extensions for auto instrumentation added to the base library
      # AutoInstrumentation enables all integration
      module AutoInstrument
        def self.patch_all!
          integrations = []

          Contrib::REGISTRY.each do |integration|
            # some instrumentations are automatically enabled when the `rails` instrumentation is enabled,
            # patching them on their own automatically outside of the rails integration context would
            # cause undesirable service naming, so we exclude them based their auto_instrument? setting.
            # we also don't want to mix rspec/cucumber integration in as rspec is env we run tests in.
            next unless integration.klass.auto_instrument?

            integrations << integration.name
          end

          Datadog.configure do |c|
            # Ignore any instrumentation load errors (otherwise it might spam logs)
            c.tracing.ignore_integration_load_errors = true

            # Activate instrumentation for each integration
            integrations.each do |integration_name|
              c.tracing.instrument integration_name
            end
          end
        end
      end
    end
  end
end

Datadog::Tracing::Contrib.auto_instrument!
