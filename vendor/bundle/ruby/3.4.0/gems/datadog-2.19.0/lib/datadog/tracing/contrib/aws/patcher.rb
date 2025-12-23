# frozen_string_literal: true

require_relative '../patcher'
require_relative 'ext'

module Datadog
  module Tracing
    module Contrib
      module Aws
        # Patcher enables patching of 'aws' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            require_relative 'parsed_context'
            require_relative 'instrumentation'
            require_relative 'services'

            add_plugin(Seahorse::Client::Base, *loaded_constants)

            # Special handling for S3 URL Presigning.
            # @see Datadog::Tracing::Contrib::Aws::S3Presigner
            ::Aws::S3::Presigner.prepend(S3Presigner) if defined?(::Aws::S3::Presigner)
          end

          def add_plugin(*targets)
            targets.each { |klass| klass.add_plugin(Instrumentation) }
          end

          def loaded_constants
            # Cross-check services against loaded AWS constants
            # Module#const_get can return a constant from ancestors when there's a miss.
            # If this conincidentally matches another constant, it will attempt to patch
            # the wrong constant, resulting in patch failure.
            available_services = ::Aws.constants & SERVICES.map(&:to_sym)

            available_services.each_with_object([]) do |service, constants|
              next if ::Aws.autoload?(service)

              constants << ::Aws.const_get(service, false).const_get(:Client, false) rescue next
            end
          end

          def get_option(option)
            Datadog.configuration.tracing[:aws].get_option(option)
          end
        end
      end
    end
  end
end
