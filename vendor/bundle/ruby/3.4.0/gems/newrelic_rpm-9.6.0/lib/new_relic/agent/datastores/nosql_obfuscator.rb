# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Datastores
      module NosqlObfuscator
        ALLOWLIST = [:operation].freeze

        def self.obfuscate_statement(source, allowlist = ALLOWLIST)
          if source.is_a?(Hash)
            obfuscated = {}
            source.each do |key, value|
              if allowlist.include?(key)
                obfuscated[key] = value
              else
                obfuscated[key] = obfuscate_value(value, allowlist)
              end
            end
            obfuscated
          else
            obfuscate_value(source, allowlist)
          end
        end

        QUESTION_MARK = '?'.freeze

        def self.obfuscate_value(value, allowlist = ALLOWLIST)
          if value.is_a?(Hash)
            obfuscate_statement(value, allowlist)
          elsif value.is_a?(Array)
            value.map { |v| obfuscate_value(v, allowlist) }
          else
            QUESTION_MARK
          end
        end
      end
    end
  end
end
