# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative '../nosql_obfuscator'

module NewRelic
  module Agent
    module Datastores
      module Mongo
        module EventFormatter
          # Keys that will get their values replaced with '?'.
          OBFUSCATE_KEYS = %w[filter query pipeline].freeze

          # Keys that will get completely removed from the statement.
          DENYLISTED_KEYS = %w[deletes documents updates].freeze

          def self.format(command_name, database_name, command)
            return nil unless NewRelic::Agent.config[:'mongo.capture_queries']

            result = {
              :operation => command_name,
              :database => database_name,
              :collection => command.values.first
            }

            command.each do |key, value|
              next if DENYLISTED_KEYS.include?(key)

              if OBFUSCATE_KEYS.include?(key)
                obfuscated = obfuscate(value)
                result[key] = obfuscated if obfuscated
              else
                result[key] = value
              end
            end
            result
          end

          def self.obfuscate(statement)
            if NewRelic::Agent.config[:'mongo.obfuscate_queries']
              statement = NewRelic::Agent::Datastores::NosqlObfuscator.obfuscate_statement(statement)
            end
            statement
          end
        end
      end
    end
  end
end
