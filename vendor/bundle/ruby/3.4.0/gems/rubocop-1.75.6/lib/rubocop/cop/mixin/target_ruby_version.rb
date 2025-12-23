# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking target ruby version.
    module TargetRubyVersion
      def required_minimum_ruby_version
        @minimum_target_ruby_version
      end

      def required_maximum_ruby_version
        @maximum_target_ruby_version
      end

      def minimum_target_ruby_version(version)
        @minimum_target_ruby_version = version
      end

      def maximum_target_ruby_version(version)
        @maximum_target_ruby_version = version
      end

      def support_target_ruby_version?(version)
        # By default, no minimum or maximum versions of ruby are required
        # to run any cop. In order to do a simple numerical comparison of
        # the requested version against any requirements, we use 0 and
        # Infinity as the default values to indicate no minimum (0) and no
        # maximum (Infinity).
        min = required_minimum_ruby_version || 0
        max = required_maximum_ruby_version || Float::INFINITY

        version.between?(min, max)
      end
    end
  end
end
