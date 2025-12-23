# frozen_string_literal: true

require "test_prof/utils/rspec"

module TestProf
  module StackProf
    # Reporter for RSpec to profile specific examples with StackProf
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
        notification.example.metadata[:sprof_report] = TestProf::StackProf.profile
      end

      def example_finished(notification)
        return unless profile?(notification.example)
        return unless notification.example.metadata[:sprof_report] == false

        TestProf::StackProf.dump(
          self.class.report_name_generator.call(notification.example)
        )
      end

      private

      def profile?(example)
        example.metadata.key?(:sprof)
      end
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    listener = TestProf::StackProf::Listener.new

    config.reporter.register_listener(
      listener, *TestProf::StackProf::Listener::NOTIFICATIONS
    )
  end
end

# Handle boot profiling
RSpec.configure do |config|
  config.append_before(:suite) do
    TestProf::StackProf.dump("boot") if TestProf::StackProf.config.boot?
  end
end
