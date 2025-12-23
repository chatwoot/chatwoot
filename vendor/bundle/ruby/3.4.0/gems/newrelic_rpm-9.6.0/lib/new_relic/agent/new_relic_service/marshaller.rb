# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    class NewRelicService
      class Marshaller
        def prepare(data, options = {})
          encoder = options[:encoder] || default_encoder
          if data.respond_to?(:to_collector_array)
            data.to_collector_array(encoder)
          elsif data.kind_of?(Array)
            data.map { |element| prepare(element, options) }
          else
            data
          end
        end

        def default_encoder
          Encoders::Identity
        end

        def self.human_readable?
          false
        end

        protected

        def return_value(data)
          if data.respond_to?(:has_key?) && data.has_key?('return_value')
            data['return_value']
          else
            ::NewRelic::Agent.logger.debug("Unexpected response from collector: #{data}")
            nil
          end
        end
      end
    end
  end
end
