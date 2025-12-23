# frozen_string_literal: true

require_relative 'resources/cors_misconfiguration_error'

module Rack
  class Cors
    class Resources
      attr_reader :resources

      def initialize
        @origins = []
        @resources = []
        @public_resources = false
      end

      def origins(*args, &blk)
        @origins = args.flatten.reject { |s| s == '' }.map do |n|
          case n
          when Proc, Regexp, %r{^[a-z][a-z0-9.+-]*://}
            n
          when '*'
            @public_resources = true
            n
          else
            Regexp.compile("^[a-z][a-z0-9.+-]*:\\\/\\\/#{Regexp.quote(n)}$")
          end
        end.flatten
        @origins.push(blk) if blk
      end

      def resource(path, opts = {})
        @resources << Resource.new(public_resources?, path, opts)
      end

      def public_resources?
        @public_resources
      end

      def allow_origin?(source, env = {})
        return true if public_resources?

        !!@origins.detect do |origin|
          if origin.is_a?(Proc)
            origin.call(source, env)
          elsif origin.is_a?(Regexp)
            source =~ origin
          else
            source == origin
          end
        end
      end

      def match_resource(path, env)
        @resources.detect { |r| r.match?(path, env) }
      end

      def resource_for_path(path)
        @resources.detect { |r| r.matches_path?(path) }
      end
    end
  end
end
