# frozen_string_literal: true

module Datadog
  module Core
    module Utils
      # Helper methods for parsing string values into Numeric
      module Duration
        def self.call(value, base: :s)
          cast = if value.include?('.')
            method(:Float)
          else
            method(:Integer)
          end

          scale = case base
          when :s
            1_000_000_000
          when :ms
            1_000_000
          when :us
            1000
          when :ns
            1
          else
            raise ArgumentError, "invalid base: #{base.inspect}"
          end

          result = case value
          when /^(\d+(?:\.\d+)?)h$/
            cast.call(Regexp.last_match(1)) * 1_000_000_000 * 60 * 60 / scale
          when /^(\d+(?:\.\d+)?)m$/
            cast.call(Regexp.last_match(1)) * 1_000_000_000 * 60 / scale
          when /^(\d+(?:\.\d+)?)s$/
            cast.call(Regexp.last_match(1)) * 1_000_000_000 / scale
          when /^(\d+(?:\.\d+)?)ms$/
            cast.call(Regexp.last_match(1)) * 1_000_000 / scale
          when /^(\d+(?:\.\d+)?)us$/
            cast.call(Regexp.last_match(1)) * 1_000 / scale
          when /^(\d+(?:\.\d+)?)ns$/
            cast.call(Regexp.last_match(1)) / scale
          when /^(\d+(?:\.\d+)?)$/
            cast.call(Regexp.last_match(1))
          else
            raise ArgumentError, "invalid duration: #{value.inspect}"
          end
          # @type var result: Numeric
          result.round
        end
      end
    end
  end
end
