# frozen_string_literal: true

require "bundler"

using Bullet::Ext::Object

module Bullet
  module StackTraceFilter
    VENDOR_PATH = '/vendor'

    # @param bullet_key[String] - use this to get stored call stack from call_stacks object.
    def caller_in_project(bullet_key = nil)
      vendor_root = Bullet.app_root + VENDOR_PATH
      bundler_path = Bundler.bundle_path.to_s
      select_caller_locations(bullet_key) do |location|
        caller_path = location_as_path(location)
        caller_path.include?(Bullet.app_root) && !caller_path.include?(vendor_root) &&
          !caller_path.include?(bundler_path) || Bullet.stacktrace_includes.any? { |include_pattern|
                                                   pattern_matches?(location, include_pattern)
                                                 }
      end
    end

    def excluded_stacktrace_path?
      Bullet.stacktrace_excludes.any? do |exclude_pattern|
        caller_in_project.any? { |location| pattern_matches?(location, exclude_pattern) }
      end
    end

    private

    def pattern_matches?(location, pattern)
      path = location_as_path(location)
      case pattern
      when Array
        pattern_path = pattern.first
        filter = pattern.last
        return false unless pattern_matches?(location, pattern_path)

        case filter
        when Range
          filter.include?(location.lineno)
        when Integer
          filter == location.lineno
        when String
          filter == location.base_label
        end
      when String
        path.include?(pattern)
      when Regexp
        path =~ pattern
      end
    end

    def location_as_path(location)
      return location if location.is_a?(String)

      location.absolute_path.to_s
    end

    def select_caller_locations(bullet_key = nil)
      call_stack = bullet_key ? call_stacks[bullet_key] : caller_locations

      call_stack.select { |location| yield location }
    end
  end
end
