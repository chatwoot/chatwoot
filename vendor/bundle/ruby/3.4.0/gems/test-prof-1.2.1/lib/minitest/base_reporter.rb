# frozen_string_literal: true

require "minitest"
require "test_prof/logging"

module Minitest
  module TestProf
    class BaseReporter < AbstractReporter # :nodoc:
      include ::TestProf::Logging

      attr_accessor :io

      def initialize(io = $stdout, _options = {})
        @io = io
        inject_to_minitest_reporters if defined? Minitest::Reporters
      end

      def start
      end

      def prerecord(group, example)
      end

      def before_test(test)
      end

      def record(*)
      end

      def after_test(test)
      end

      def report
      end

      private

      def location(group, example = nil)
        # Minitest::Result (>= 5.11) has `source_location` method
        return group.source_location if group.respond_to?(:source_location)
        if group.is_a? Class
          suite = group.public_instance_methods.select { |mtd| mtd.to_s.match(/^test_/) }
          name = suite.find { |mtd| mtd.to_s == example }
          group.instance_method(name).source_location
        else
          suite = group.methods.select { |mtd| mtd.to_s.match(/^test_/) }
          name = suite.find { |mtd| mtd.to_s == group.name }
          group.method(name).source_location
        end
      end

      def location_with_line_number(group, example = nil)
        File.expand_path(location(group, example).join(":")).gsub(Dir.getwd, ".")
      end

      def location_without_line_number(group, example = nil)
        File.expand_path(location(group, example).first).gsub(Dir.getwd, ".")
      end

      def inject_to_minitest_reporters
        Minitest::Reporters.reporters << self if Minitest::Reporters.reporters
      end
    end
  end
end
