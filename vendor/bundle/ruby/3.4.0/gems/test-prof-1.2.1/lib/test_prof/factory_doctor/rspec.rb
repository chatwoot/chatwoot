# frozen_string_literal: true

require "test_prof/ext/float_duration"

module TestProf
  module FactoryDoctor
    class RSpecListener # :nodoc:
      include Logging
      using FloatDuration

      SUCCESS_MESSAGE = 'FactoryDoctor says: "Looks good to me!"'

      NOTIFICATIONS = %i[
        example_started
        example_finished
      ].freeze

      def initialize
        @count = 0
        @time = 0.0
        @example_groups = Hash.new { |h, k| h[k] = [] }
      end

      def example_started(_notification)
        FactoryDoctor.start
      end

      def example_finished(notification)
        FactoryDoctor.stop
        return if notification.example.pending?

        result = FactoryDoctor.result

        return unless result.bad?

        group = notification.example.example_group.parent_groups.last
        notification.example.metadata.merge!(
          factories: result.count,
          time: result.time
        )
        @example_groups[group] << notification.example
        @count += 1
        @time += result.time
      end

      def print
        return log(:info, SUCCESS_MESSAGE) if @example_groups.empty?

        msgs = []

        msgs <<
          <<~MSG
            FactoryDoctor report

            Total (potentially) bad examples: #{@count}
            Total wasted time: #{@time.duration}

          MSG

        @example_groups.each do |group, examples|
          group_time = examples.sum { |ex| ex.metadata[:time] }
          group_count = examples.sum { |ex| ex.metadata[:factories] }

          msgs << "#{group.description} (#{group.metadata[:location]}) " \
                  "(#{pluralize_records(group_count)} created, " \
                  "#{group_time.duration})\n"

          examples.each do |ex|
            msgs << "  #{ex.description} (#{ex.metadata[:location]}) " \
                    "– #{pluralize_records(ex.metadata[:factories])} created, " \
                    "#{ex.metadata[:time].duration}\n"
          end
          msgs << "\n"
        end

        log :info, msgs.join

        stamp! if FactoryDoctor.stamp?
      end

      def stamp!
        stamper = RSpecStamp::Stamper.new

        examples = Hash.new { |h, k| h[k] = [] }

        @example_groups.each_value do |bad_examples|
          bad_examples.each do |example|
            file, line = example.metadata[:location].split(":")
            examples[file] << line.to_i
          end
        end

        examples.each do |file, lines|
          stamper.stamp_file(file, lines.uniq)
        end

        msgs = []

        msgs <<
          <<~MSG
            RSpec Stamp results

            Total patches: #{stamper.total}
            Total files: #{examples.keys.size}

            Failed patches: #{stamper.failed}
            Ignored files: #{stamper.ignored}
          MSG

        log :info, msgs.join
      end

      private

      def pluralize_records(count)
        return "1 record" if count == 1
        "#{count} records"
      end
    end
  end
end

# Register FactoryDoctor listener
TestProf.activate("FDOC") do
  TestProf::FactoryDoctor.init

  RSpec.configure do |config|
    listener = nil

    config.before(:suite) do
      listener = TestProf::FactoryDoctor::RSpecListener.new
      config.reporter.register_listener(
        listener, *TestProf::FactoryDoctor::RSpecListener::NOTIFICATIONS
      )
    end

    config.after(:suite) { listener&.print }
  end

  RSpec.shared_context "factory_doctor:ignore" do
    around(:each) { |ex| TestProf::FactoryDoctor.ignore(&ex) }
  end

  RSpec.configure do |config|
    config.include_context "factory_doctor:ignore", fd_ignore: true
  end
end
