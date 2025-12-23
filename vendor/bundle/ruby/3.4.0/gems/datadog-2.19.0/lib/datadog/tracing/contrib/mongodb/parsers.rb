# frozen_string_literal: true

require_relative '../utils/quantization/hash'

module Datadog
  module Tracing
    module Contrib
      # MongoDB module includes classes and functions to instrument MongoDB clients
      module MongoDB
        EXCLUDE_KEYS = [:_id].freeze
        SHOW_KEYS = [].freeze
        DEFAULT_OPTIONS = { exclude: EXCLUDE_KEYS, show: SHOW_KEYS }.freeze

        module_function

        # skipped keys are related to command names, since they are already
        # extracted by the query_builder
        PLACEHOLDER = '?'

        # returns a formatted and normalized query
        def query_builder(command_name, database_name, command)
          # always exclude the command name
          options = Contrib::Utils::Quantization::Hash.merge_options(quantization_options, exclude: [command_name.to_s])

          # quantized statements keys are strings to avoid leaking Symbols in older Rubies
          # as Symbols are not GC'ed in Rubies prior to 2.2
          base_info = Contrib::Utils::Quantization::Hash.format(
            {
              'operation' => command_name,
              'database' => database_name,
              'collection' => command.values.first
            },
            options
          )

          base_info.merge(Contrib::Utils::Quantization::Hash.format(command, options))
        end

        def quantization_options
          Contrib::Utils::Quantization::Hash.merge_options(DEFAULT_OPTIONS, configuration[:quantize])
        end

        def configuration
          Datadog.configuration.tracing[:mongo]
        end
      end
    end
  end
end
