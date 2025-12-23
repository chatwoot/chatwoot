# frozen_string_literal: true

require "test_prof/utils/rspec"

module TestProf
  module RubyProf
    # Reporter for RSpec to profile specific examples with RubyProf
    class Listener # :nodoc:
      class << self
        attr_accessor :report_name_generator
      end

      self.report_name_generator = Utils::RSpec.method(:example_to_filename)

      NOTIFICATIONS = %i[
        example_started
        example_finished
      ].freeze

      def example_started(notification)
        return unless profile?(notification.example)
        notification.example.metadata[:rprof_report] =
          TestProf::RubyProf.profile
      end

      def example_finished(notification)
        return unless profile?(notification.example)
        notification.example.metadata[:rprof_report]&.dump(
          self.class.report_name_generator.call(notification.example)
        )
      end

      private

      def profile?(example)
        example.metadata.key?(:rprof)
      end
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    listener = TestProf::RubyProf::Listener.new

    config.reporter.register_listener(
      listener, *TestProf::RubyProf::Listener::NOTIFICATIONS
    )
  end
end
