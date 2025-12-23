# frozen_string_literal: true

require_relative '../patcher'
require_relative 'ext'
require_relative 'instrumentation'

module Datadog
  module Tracing
    module Contrib
      module Rake
        # Patcher enables patching of 'rake' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            # Add instrumentation patch to Rake task
            ::Rake::Task.include(Instrumentation)
          end

          def get_option(option)
            Datadog.configuration.tracing[:rake].get_option(option)
          end
        end
      end
    end
  end
end
