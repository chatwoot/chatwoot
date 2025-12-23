# frozen_string_literal: true

require_relative '../resolver'

module Datadog
  module Tracing
    module Contrib
      module Configuration
        # Resolves a value to a configuration key
        module Resolvers
          # Matches Strings and Regexps against `object.to_s` objects
          # and Procs against plain objects.
          class PatternResolver < Contrib::Configuration::Resolver
            def resolve(value)
              return if configurations.empty?

              # Try to find a matching pattern
              _, config = configurations.reverse_each.find do |matcher, _|
                matcher === if matcher.is_a?(Proc)
                              value
                            else
                              value.to_s
                            end
              end

              config
            end

            protected

            def parse_matcher(matcher)
              if matcher.is_a?(Regexp) || matcher.is_a?(Proc)
                matcher
              else
                matcher.to_s
              end
            end
          end
        end
      end
    end
  end
end
