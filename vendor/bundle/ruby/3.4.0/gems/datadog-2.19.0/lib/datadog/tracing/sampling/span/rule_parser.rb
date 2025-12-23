# frozen_string_literal: true

require 'json'

require_relative 'ext'
require_relative 'matcher'
require_relative 'rule'

module Datadog
  module Tracing
    module Sampling
      module Span
        # Converts user configuration into {Datadog::Tracing::Sampling::Span::Rule} objects,
        # handling any parsing errors.
        module RuleParser
          class << self
            # Parses the provided JSON string containing the Single Span
            # Sampling configuration list.
            # In case of parsing errors, `nil` is returned.
            #
            # @param rules [String] the JSON configuration rules to be parsed
            # @return [Array<Datadog::Tracing::Sampling::Span::Rule>] a list of parsed rules
            # @return [nil] if parsing failed
            def parse_json(rules)
              return nil unless rules

              begin
                list = JSON.parse(rules)
              rescue => e
                Datadog.logger.warn(
                  "Error parsing Span Sampling Rules `#{rules.inspect}`: "\
                  "#{e.class.name} #{e.message} at #{Array(e.backtrace).first}"
                )
                return nil
              end

              parse_list(list)
            end

            # Parses a list of Hashes containing the parsed JSON information
            # for Single Span Sampling configuration.
            # In case of parsing errors, `nil` is returned.
            #
            # @param rules [Array<String] the JSON configuration rules to be parsed
            # @return [Array<Datadog::Tracing::Sampling::Span::Rule>] a list of parsed rules
            # @return [nil] if parsing failed
            def parse_list(rules)
              unless rules.is_a?(Array)
                Datadog.logger.warn("Span Sampling Rules are not an array: #{rules.inspect}")
                return nil
              end

              parsed = rules.map do |hash|
                unless hash.is_a?(Hash)
                  Datadog.logger.warn("Span Sampling Rule is not a key-value object: #{hash.inspect}")
                  return nil
                end

                begin
                  parse_rule(hash)
                rescue => e
                  Datadog.logger.warn(
                    "Cannot parse Span Sampling Rule #{hash.inspect}: " \
                    "#{e.class.name} #{e} at #{Array(e.backtrace).first}"
                  )
                  return nil
                end
              end

              parsed.compact!
              parsed
            end

            private

            def parse_rule(hash)
              matcher_options = {}
              if (name_pattern = hash['name'])
                matcher_options[:name_pattern] = name_pattern
              end

              if (service_pattern = hash['service'])
                matcher_options[:service_pattern] = service_pattern
              end

              matcher = Matcher.new(**matcher_options)

              rule_options = {}
              if (sample_rate = hash['sample_rate'])
                rule_options[:sample_rate] = sample_rate
              end

              if (max_per_second = hash['max_per_second'])
                rule_options[:rate_limit] = max_per_second
              end

              Rule.new(matcher, **rule_options)
            end
          end
        end
      end
    end
  end
end
