# frozen_string_literal: true

require_relative '../core/remote/dispatcher'
require_relative 'configuration/dynamic'

module Datadog
  module Tracing
    # Remote configuration declaration
    module Remote
      class ReadError < StandardError; end

      class << self
        PRODUCT = 'APM_TRACING'

        CAPABILITIES = [
          1 << 12, # APM_TRACING_SAMPLE_RATE: Dynamic trace sampling rate configuration
          1 << 13, # APM_TRACING_LOGS_INJECTION: Dynamic trace logs injection configuration
          1 << 14, # APM_TRACING_HTTP_HEADER_TAGS: Dynamic trace HTTP header tags configuration
          1 << 29, # APM_TRACING_SAMPLE_RULES: Dynamic trace sampling rules configuration
        ].freeze

        def products
          [PRODUCT]
        end

        def capabilities
          CAPABILITIES
        end

        def process_config(config, content)
          lib_config = config['lib_config']

          env_vars = Datadog::Tracing::Configuration::Dynamic::OPTIONS.map do |name, env_var, option|
            value = lib_config[name]

            # Guard for RBS/Steep
            raise "option is a #{option.class}, expected Option" unless option.is_a?(Configuration::Dynamic::Option)

            option.call(value)

            [env_var, value]
          end

          content.applied

          Datadog.send(:components).telemetry.client_configuration_change!(env_vars)
        rescue => e
          content.errored("#{e.class.name} #{e.message}: #{Array(e.backtrace).join("\n")}")
        end

        def receivers(_telemetry)
          receiver do |repository, _changes|
            # DEV: Filter our by product. Given it will be very common
            # DEV: we can filter this out before we receive the data in this method.
            # DEV: Apply this refactor to AppSec as well if implemented.
            repository.contents.map do |content|
              case content.path.product
              when PRODUCT
                config = parse_content(content)
                process_config(config, content)
              end
            end
          end
        end

        def receiver(products = [PRODUCT], &block)
          matcher = Core::Remote::Dispatcher::Matcher::Product.new(products)
          [Core::Remote::Dispatcher::Receiver.new(matcher, &block)]
        end

        private

        def parse_content(content)
          data = content.data.read

          content.data.rewind

          raise ReadError, 'EOF reached' if data.nil?

          JSON.parse(data)
        end
      end
    end
  end
end
