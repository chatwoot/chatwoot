# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      # Parsing status range from environment variable
      class StatusRangeEnvParser
        class << self
          def call(value)
            [].tap do |array|
              value.split(',').each do |e|
                next unless e

                v = e.split('-')

                case v.length
                when 0 then next
                when 1 then array << Integer(v.first)
                when 2 then array << (Integer(v.first)..Integer(v.last))
                else
                  Datadog.logger.debug(
                    "Invalid error_status_codes configuration: Unable to parse #{value}, containing #{v}."
                  )
                  next
                end
              end
            end
          end
        end
      end
    end
  end
end
