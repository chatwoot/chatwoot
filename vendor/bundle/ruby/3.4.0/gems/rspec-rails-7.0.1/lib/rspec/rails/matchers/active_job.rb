require "active_job/base"
require "active_job/arguments"

module RSpec
  module Rails
    module Matchers
      # Namespace for various implementations of ActiveJob features
      #
      # @api private
      module ActiveJob
        # rubocop: disable Metrics/ClassLength
        # @private
        class Base < RSpec::Rails::Matchers::BaseMatcher
          def initialize
            @args = []
            @queue = nil
            @priority = nil
            @at = nil
            @block = proc { }
            set_expected_number(:exactly, 1)
          end

          def with(*args, &block)
            @args = args
            @block = block if block.present?
            self
          end

          def on_queue(queue)
            @queue = queue.to_s
            self
          end

          def at_priority(priority)
            @priority = priority.to_i
            self
          end

          def at(time_or_date)
            case time_or_date
            when Time then @at = Time.at(time_or_date.to_f)
            else
              @at = time_or_date
            end
            self
          end

          def exactly(count)
            set_expected_number(:exactly, count)
            self
          end

          def at_least(count)
            set_expected_number(:at_least, count)
            self
          end

          def at_most(count)
            set_expected_number(:at_most, count)
            self
          end

          def times
            self
          end

          def once
            exactly(:once)
          end

          def twice
            exactly(:twice)
          end

          def thrice
            exactly(:thrice)
          end

          def failure_message
            return @failure_message if defined?(@failure_message)

            "expected to #{self.class::FAILURE_MESSAGE_EXPECTATION_ACTION} #{base_message}".tap do |msg|
              if @unmatching_jobs.any?
                msg << "\nQueued jobs:"
                @unmatching_jobs.each do |job|
                  msg << "\n  #{base_job_message(job)}"
                end
              end
            end
          end

          def failure_message_when_negated
            "expected not to #{self.class::FAILURE_MESSAGE_EXPECTATION_ACTION} #{base_message}"
          end

          def message_expectation_modifier
            case @expectation_type
            when :exactly then "exactly"
            when :at_most then "at most"
            when :at_least then "at least"
            end
          end

          def supports_block_expectations?
            true
          end

        private

          def check(jobs)
            @matching_jobs, @unmatching_jobs = jobs.partition do |job|
              if matches_constraints?(job)
                args = deserialize_arguments(job)
                @block.call(*args)
                true
              else
                false
              end
            end

            if (signature_mismatch = detect_args_signature_mismatch(@matching_jobs))
              @failure_message = signature_mismatch
              return false
            end

            @matching_jobs_count = @matching_jobs.size

            case @expectation_type
            when :exactly then @expected_number == @matching_jobs_count
            when :at_most then @expected_number >= @matching_jobs_count
            when :at_least then @expected_number <= @matching_jobs_count
            end
          end

          def base_message
            "#{message_expectation_modifier} #{@expected_number} jobs,".tap do |msg|
              msg << " with #{@args}," if @args.any?
              msg << " on queue #{@queue}," if @queue
              msg << " at #{@at.inspect}," if @at
              msg << " with priority #{@priority}," if @priority
              msg << " but #{self.class::MESSAGE_EXPECTATION_ACTION} #{@matching_jobs_count}"
            end
          end

          def base_job_message(job)
            msg_parts = []
            msg_parts << "with #{deserialize_arguments(job)}" if job[:args].any?
            msg_parts << "on queue #{job[:queue]}" if job[:queue]
            msg_parts << "at #{Time.at(job[:at])}" if job[:at]
            msg_parts <<
              if job[:priority]
                "with priority #{job[:priority]}"
              else
                "with no priority specified"
              end

            "#{job[:job].name} job".tap do |msg|
              msg << " #{msg_parts.join(', ')}" if msg_parts.any?
            end
          end

          def matches_constraints?(job)
            job_matches?(job) && arguments_match?(job) && queue_match?(job) && at_match?(job) && priority_match?(job)
          end

          def job_matches?(job)
            @job ? @job == job[:job] : true
          end

          def arguments_match?(job)
            if @args.any?
              args = serialize_and_deserialize_arguments(@args)
              deserialized_args = deserialize_arguments(job)
              RSpec::Mocks::ArgumentListMatcher.new(*args).args_match?(*deserialized_args)
            else
              true
            end
          end

          def detect_args_signature_mismatch(jobs)
            jobs.each do |job|
              args = deserialize_arguments(job)

              if (signature_mismatch = check_args_signature_mismatch(job.fetch(:job), :perform, args))
                return signature_mismatch
              end
            end

            nil
          end

          def check_args_signature_mismatch(job_class, job_method, args)
            signature = Support::MethodSignature.new(job_class.public_instance_method(job_method))
            verifier = Support::StrictSignatureVerifier.new(signature, args)

            unless verifier.valid?
              "Incorrect arguments passed to #{job_class.name}: #{verifier.error_message}"
            end
          end

          def queue_match?(job)
            return true unless @queue

            @queue == job[:queue]
          end

          def priority_match?(job)
            return true unless @priority

            @priority == job[:priority]
          end

          def at_match?(job)
            return true unless @at
            return job[:at].nil? if @at == :no_wait
            return false unless job[:at]

            scheduled_at = Time.at(job[:at])
            values_match?(@at, scheduled_at) || check_for_inprecise_value(scheduled_at)
          end

          def check_for_inprecise_value(scheduled_at)
            return unless Time === @at && values_match?(@at.change(usec: 0), scheduled_at)

            RSpec.warn_with((<<-WARNING).gsub(/^\s+\|/, '').chomp)
            |[WARNING] Your expected `at(...)` value does not match the job scheduled_at value
            |unless microseconds are removed. This precision error often occurs when checking
            |values against `Time.current` / `Time.now` which have usec precision, but Rails
            |uses `n.seconds.from_now` internally which has a usec count of `0`.
            |
            |Use `change(usec: 0)` to correct these values. For example:
            |
            |`Time.current.change(usec: 0)`
            |
            |Note: RSpec cannot do this for you because jobs can be scheduled with usec
            |precision and we do not know whether it is on purpose or not.
            |
            |
            WARNING
            false
          end

          def set_expected_number(relativity, count)
            @expectation_type = relativity
            @expected_number = case count
                               when :once then 1
                               when :twice then 2
                               when :thrice then 3
                               else Integer(count)
                               end
          end

          def serialize_and_deserialize_arguments(args)
            serialized = ::ActiveJob::Arguments.serialize(args)
            ::ActiveJob::Arguments.deserialize(serialized)
          rescue ::ActiveJob::SerializationError
            args
          end

          def deserialize_arguments(job)
            ::ActiveJob::Arguments.deserialize(job[:args])
          rescue ::ActiveJob::DeserializationError
            job[:args]
          end

          def queue_adapter
            ::ActiveJob::Base.queue_adapter
          end
        end
        # rubocop: enable Metrics/ClassLength

        # @private
        class HaveEnqueuedJob < Base
          FAILURE_MESSAGE_EXPECTATION_ACTION = 'enqueue'.freeze
          MESSAGE_EXPECTATION_ACTION = 'enqueued'.freeze

          def initialize(job)
            super()
            @job = job
          end

          def matches?(proc)
            raise ArgumentError, "have_enqueued_job and enqueue_job only support block expectations" unless Proc === proc

            original_enqueued_jobs = Set.new(queue_adapter.enqueued_jobs)
            proc.call
            enqueued_jobs = Set.new(queue_adapter.enqueued_jobs)

            check(enqueued_jobs - original_enqueued_jobs)
          end

          def does_not_match?(proc)
            set_expected_number(:at_least, 1)

            !matches?(proc)
          end
        end

        # @private
        class HaveBeenEnqueued < Base
          FAILURE_MESSAGE_EXPECTATION_ACTION = 'enqueue'.freeze
          MESSAGE_EXPECTATION_ACTION = 'enqueued'.freeze

          def matches?(job)
            @job = job
            check(queue_adapter.enqueued_jobs)
          end

          def does_not_match?(proc)
            set_expected_number(:at_least, 1)

            !matches?(proc)
          end
        end

        # @private
        class HavePerformedJob < Base
          FAILURE_MESSAGE_EXPECTATION_ACTION = 'perform'.freeze
          MESSAGE_EXPECTATION_ACTION = 'performed'.freeze

          def initialize(job)
            super()
            @job = job
          end

          def matches?(proc)
            raise ArgumentError, "have_performed_job only supports block expectations" unless Proc === proc

            original_performed_jobs_count = queue_adapter.performed_jobs.count
            proc.call
            in_block_jobs = queue_adapter.performed_jobs.drop(original_performed_jobs_count)

            check(in_block_jobs)
          end
        end

        # @private
        class HaveBeenPerformed < Base
          FAILURE_MESSAGE_EXPECTATION_ACTION = 'perform'.freeze
          MESSAGE_EXPECTATION_ACTION = 'performed'.freeze

          def matches?(job)
            @job = job
            check(queue_adapter.performed_jobs)
          end
        end
      end

      # @api public
      # Passes if a job has been enqueued inside block. May chain at_least, at_most or exactly to specify a number of times.
      #
      # @example
      #     expect {
      #       HeavyLiftingJob.perform_later
      #     }.to have_enqueued_job
      #
      #     # Using alias
      #     expect {
      #       HeavyLiftingJob.perform_later
      #     }.to enqueue_job
      #
      #     expect {
      #       HelloJob.perform_later
      #       HeavyLiftingJob.perform_later
      #     }.to have_enqueued_job(HelloJob).exactly(:once)
      #
      #     expect {
      #       3.times { HelloJob.perform_later }
      #     }.to have_enqueued_job(HelloJob).at_least(2).times
      #
      #     expect {
      #       HelloJob.perform_later
      #     }.to have_enqueued_job(HelloJob).at_most(:twice)
      #
      #     expect {
      #       HelloJob.perform_later
      #       HeavyLiftingJob.perform_later
      #     }.to have_enqueued_job(HelloJob).and have_enqueued_job(HeavyLiftingJob)
      #
      #     expect {
      #       HelloJob.set(wait_until: Date.tomorrow.noon, queue: "low").perform_later(42)
      #     }.to have_enqueued_job.with(42).on_queue("low").at(Date.tomorrow.noon)
      #
      #     expect {
      #       HelloJob.set(queue: "low").perform_later(42)
      #     }.to have_enqueued_job.with(42).on_queue("low").at(:no_wait)
      #
      #     expect {
      #       HelloJob.perform_later('rspec_rails', 'rails', 42)
      #     }.to have_enqueued_job.with { |from, to, times|
      #       # Perform more complex argument matching using dynamic arguments
      #       expect(from).to include "_#{to}"
      #     }
      def have_enqueued_job(job = nil)
        check_active_job_adapter
        ActiveJob::HaveEnqueuedJob.new(job)
      end
      alias_method :enqueue_job, :have_enqueued_job

      # @api public
      # Passes if a job has been enqueued. May chain at_least, at_most or exactly to specify a number of times.
      #
      # @example
      #     before { ActiveJob::Base.queue_adapter.enqueued_jobs.clear }
      #
      #     HeavyLiftingJob.perform_later
      #     expect(HeavyLiftingJob).to have_been_enqueued
      #
      #     HelloJob.perform_later
      #     HeavyLiftingJob.perform_later
      #     expect(HeavyLiftingJob).to have_been_enqueued.exactly(:once)
      #
      #     3.times { HelloJob.perform_later }
      #     expect(HelloJob).to have_been_enqueued.at_least(2).times
      #
      #     HelloJob.perform_later
      #     expect(HelloJob).to enqueue_job(HelloJob).at_most(:twice)
      #
      #     HelloJob.perform_later
      #     HeavyLiftingJob.perform_later
      #     expect(HelloJob).to have_been_enqueued
      #     expect(HeavyLiftingJob).to have_been_enqueued
      #
      #     HelloJob.set(wait_until: Date.tomorrow.noon, queue: "low").perform_later(42)
      #     expect(HelloJob).to have_been_enqueued.with(42).on_queue("low").at(Date.tomorrow.noon)
      #
      #     HelloJob.set(queue: "low").perform_later(42)
      #     expect(HelloJob).to have_been_enqueued.with(42).on_queue("low").at(:no_wait)
      def have_been_enqueued
        check_active_job_adapter
        ActiveJob::HaveBeenEnqueued.new
      end

      # @api public
      # Passes if a job has been performed inside block. May chain at_least, at_most or exactly to specify a number of times.
      #
      # @example
      #     expect {
      #       perform_enqueued_jobs { HeavyLiftingJob.perform_later }
      #     }.to have_performed_job
      #
      #     expect {
      #       perform_enqueued_jobs {
      #         HelloJob.perform_later
      #         HeavyLiftingJob.perform_later
      #       }
      #     }.to have_performed_job(HelloJob).exactly(:once)
      #
      #     expect {
      #       perform_enqueued_jobs { 3.times { HelloJob.perform_later } }
      #     }.to have_performed_job(HelloJob).at_least(2).times
      #
      #     expect {
      #       perform_enqueued_jobs { HelloJob.perform_later }
      #     }.to have_performed_job(HelloJob).at_most(:twice)
      #
      #     expect {
      #       perform_enqueued_jobs {
      #         HelloJob.perform_later
      #         HeavyLiftingJob.perform_later
      #       }
      #     }.to have_performed_job(HelloJob).and have_performed_job(HeavyLiftingJob)
      #
      #     expect {
      #       perform_enqueued_jobs {
      #         HelloJob.set(wait_until: Date.tomorrow.noon, queue: "low").perform_later(42)
      #       }
      #     }.to have_performed_job.with(42).on_queue("low").at(Date.tomorrow.noon)
      def have_performed_job(job = nil)
        check_active_job_adapter
        ActiveJob::HavePerformedJob.new(job)
      end
      alias_method :perform_job, :have_performed_job

      # @api public
      # Passes if a job has been performed. May chain at_least, at_most or exactly to specify a number of times.
      #
      # @example
      #     before do
      #       ActiveJob::Base.queue_adapter.performed_jobs.clear
      #       ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
      #       ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true
      #     end
      #
      #     HeavyLiftingJob.perform_later
      #     expect(HeavyLiftingJob).to have_been_performed
      #
      #     HelloJob.perform_later
      #     HeavyLiftingJob.perform_later
      #     expect(HeavyLiftingJob).to have_been_performed.exactly(:once)
      #
      #     3.times { HelloJob.perform_later }
      #     expect(HelloJob).to have_been_performed.at_least(2).times
      #
      #     HelloJob.perform_later
      #     HeavyLiftingJob.perform_later
      #     expect(HelloJob).to have_been_performed
      #     expect(HeavyLiftingJob).to have_been_performed
      #
      #     HelloJob.set(wait_until: Date.tomorrow.noon, queue: "low").perform_later(42)
      #     expect(HelloJob).to have_been_performed.with(42).on_queue("low").at(Date.tomorrow.noon)
      def have_been_performed
        check_active_job_adapter
        ActiveJob::HaveBeenPerformed.new
      end

    private

      # @private
      def check_active_job_adapter
        return if ::ActiveJob::QueueAdapters::TestAdapter === ::ActiveJob::Base.queue_adapter

        raise StandardError, "To use ActiveJob matchers set `ActiveJob::Base.queue_adapter = :test`"
      end
    end
  end
end
