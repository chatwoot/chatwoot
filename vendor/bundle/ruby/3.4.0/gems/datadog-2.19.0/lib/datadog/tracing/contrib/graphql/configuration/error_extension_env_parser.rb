# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module GraphQL
        module Configuration
          # Parses the environment variable `DD_TRACE_GRAPHQL_ERROR_EXTENSIONS` for error extension names declaration.
          class ErrorExtensionEnvParser
            # Parses the environment variable `DD_TRACE_GRAPHQL_ERROR_EXTENSIONS` into an array of error extension names.
            def self.call(values)
              # Split by comma, remove leading and trailing whitespaces,
              # remove empty values, and remove repeated values.
              values.split(',').each(&:strip!).reject(&:empty?).uniq
            end
          end
        end
      end
    end
  end
end
