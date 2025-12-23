# frozen_string_literal: true

module Datadog
  module Tracing
    module Sampling
      # Checks if a trace conforms to a matching criteria.
      # @abstract
      class Matcher
        # Pattern that matches any string
        MATCH_ALL_PATTERN = '*'

        # Returns `true` if the trace should conforms to this rule, `false` otherwise
        #
        # @param [TraceOperation] trace
        # @return [Boolean]
        def match?(trace)
          raise NotImplementedError
        end

        # Converts a glob pattern String to a case-insensitive String matcher object.
        # The match object will only return `true` if it matches the complete String.
        #
        # The following special characters are supported:
        # - `?` matches any single character
        # - `*` matches any substring
        #
        # @param glob [String]
        # @return [#match?(String)]
        def self.glob_to_regex(glob)
          # Optimization for match-all case
          return MATCH_ALL if /\A\*+\z/.match?(glob)

          # Ensure no undesired characters are treated as regex.
          glob = Regexp.quote(glob)

          # Our valid special characters, `?` and `*`, were just escaped
          # by `Regexp.quote` above. We need to unescape them:
          glob.gsub!('\?', '.') # Any single character
          glob.gsub!('\*', '.*') # Any substring

          # Patterns have to match the whole input string
          glob = "\\A#{glob}\\z"

          Regexp.new(glob, Regexp::IGNORECASE)
        end

        # Returns `true` for any input
        MATCH_ALL = Class.new do
          def match?(_other)
            true
          end

          def inspect
            "MATCH_ALL:Matcher('*')"
          end
        end.new
      end

      # A {Datadog::Sampling::Matcher} that supports matching a trace by
      # trace name and/or service name.
      class SimpleMatcher < Matcher
        attr_reader :name, :service, :resource, :tags

        # @param name [String,Regexp,Proc] Matcher for case equality (===) with the trace name,
        #             defaults to always match
        # @param service [String,Regexp,Proc] Matcher for case equality (===) with the service name,
        #                defaults to always match
        # @param resource [String,Regexp,Proc] Matcher for case equality (===) with the resource name,
        #                defaults to always match
        def initialize(
          name: MATCH_ALL_PATTERN,
          service: MATCH_ALL_PATTERN,
          resource: MATCH_ALL_PATTERN,
          tags: {}
        )
          super()

          name = Matcher.glob_to_regex(name)
          service = Matcher.glob_to_regex(service)
          resource = Matcher.glob_to_regex(resource)
          tags = tags.transform_values { |matcher| Matcher.glob_to_regex(matcher) }

          @name = name || Datadog::Tracing::Sampling::Matcher::MATCH_ALL
          @service = service || Datadog::Tracing::Sampling::Matcher::MATCH_ALL
          @resource = resource || Datadog::Tracing::Sampling::Matcher::MATCH_ALL
          @tags = tags
        end

        def match?(trace)
          @name.match?(trace.name) &&
            @service.match?(trace.service) &&
            @resource.match?(trace.resource) &&
            tags_match?(trace)
        end

        private

        # Match against the trace tags and metrics.
        def tags_match?(trace)
          @tags.all? do |name, matcher|
            tag = trace.get_tag(name)

            # Floats: Matching floating point values with a non-zero decimal part is not supported.
            # For floating point values with a non-zero decimal part, any all * pattern always returns true.
            # Other patterns always return false.
            return false if tag.is_a?(Float) && tag.truncate != tag && matcher != MATCH_ALL

            # Format metrics as strings, to allow for partial number matching (/4.*/ matching '400', '404', etc.).
            # Because metrics are floats, we use the '%g' format specifier to avoid trailing zeros, which
            # can affect exact string matching (e.g. '400' matching '400.0').
            tag = format('%g', tag) if tag.is_a?(Numeric)

            matcher.match?(tag)
          end
        end
      end
    end
  end
end
