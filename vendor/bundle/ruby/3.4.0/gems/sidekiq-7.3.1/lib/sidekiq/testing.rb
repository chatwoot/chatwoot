# frozen_string_literal: true

require "securerandom"
require "sidekiq"

module Sidekiq
  class Testing
    class TestModeAlreadySetError < RuntimeError; end
    class << self
      attr_accessor :__global_test_mode

      # Calling without a block sets the global test mode, affecting
      # all threads. Calling with a block only affects the current Thread.
      def __set_test_mode(mode)
        if block_given?
          # Reentrant testing modes will lead to a rat's nest of code which is
          # hard to reason about. You can set the testing mode once globally and
          # you can override that global setting once per-thread.
          raise TestModeAlreadySetError, "Nesting test modes is not supported" if __local_test_mode

          self.__local_test_mode = mode
          begin
            yield
          ensure
            self.__local_test_mode = nil
          end
        else
          self.__global_test_mode = mode
        end
      end

      def __test_mode
        __local_test_mode || __global_test_mode
      end

      def __local_test_mode
        Thread.current[:__sidekiq_test_mode]
      end

      def __local_test_mode=(value)
        Thread.current[:__sidekiq_test_mode] = value
      end

      def disable!(&block)
        __set_test_mode(:disable, &block)
      end

      def fake!(&block)
        __set_test_mode(:fake, &block)
      end

      def inline!(&block)
        __set_test_mode(:inline, &block)
      end

      def enabled?
        __test_mode != :disable
      end

      def disabled?
        __test_mode == :disable
      end

      def fake?
        __test_mode == :fake
      end

      def inline?
        __test_mode == :inline
      end

      def server_middleware
        @server_chain ||= Middleware::Chain.new(Sidekiq.default_configuration)
        yield @server_chain if block_given?
        @server_chain
      end
    end
  end

  # Default to fake testing to keep old behavior
  Sidekiq::Testing.fake!

  class EmptyQueueError < RuntimeError; end

  module TestingClient
    def atomic_push(conn, payloads)
      if Sidekiq::Testing.fake?
        payloads.each do |job|
          job = Sidekiq.load_json(Sidekiq.dump_json(job))
          job["enqueued_at"] = Time.now.to_f unless job["at"]
          Queues.push(job["queue"], job["class"], job)
        end
        true
      elsif Sidekiq::Testing.inline?
        payloads.each do |job|
          klass = Object.const_get(job["class"])
          job["id"] ||= SecureRandom.hex(12)
          job_hash = Sidekiq.load_json(Sidekiq.dump_json(job))
          klass.process_job(job_hash)
        end
        true
      else
        super
      end
    end
  end

  Sidekiq::Client.prepend TestingClient

  module Queues
    ##
    # The Queues class is only for testing the fake queue implementation.
    # There are 2 data structures involved in tandem. This is due to the
    # Rspec syntax of change(HardJob.jobs, :size). It keeps a reference
    # to the array. Because the array was derived from a filter of the total
    # jobs enqueued, it appeared as though the array didn't change.
    #
    # To solve this, we'll keep 2 hashes containing the jobs. One with keys based
    # on the queue, and another with keys of the job type, so the array for
    # HardJob.jobs is a straight reference to a real array.
    #
    # Queue-based hash:
    #
    # {
    #   "default"=>[
    #     {
    #       "class"=>"TestTesting::HardJob",
    #       "args"=>[1, 2],
    #       "retry"=>true,
    #       "queue"=>"default",
    #       "jid"=>"abc5b065c5c4b27fc1102833",
    #       "created_at"=>1447445554.419934
    #     }
    #   ]
    # }
    #
    # Job-based hash:
    #
    # {
    #   "TestTesting::HardJob"=>[
    #     {
    #       "class"=>"TestTesting::HardJob",
    #       "args"=>[1, 2],
    #       "retry"=>true,
    #       "queue"=>"default",
    #       "jid"=>"abc5b065c5c4b27fc1102833",
    #       "created_at"=>1447445554.419934
    #     }
    #   ]
    # }
    #
    # Example:
    #
    #   require 'sidekiq/testing'
    #
    #   assert_equal 0, Sidekiq::Queues["default"].size
    #   HardJob.perform_async(:something)
    #   assert_equal 1, Sidekiq::Queues["default"].size
    #   assert_equal :something, Sidekiq::Queues["default"].first['args'][0]
    #
    # You can also clear all jobs:
    #
    #   assert_equal 0, Sidekiq::Queues["default"].size
    #   HardJob.perform_async(:something)
    #   Sidekiq::Queues.clear_all
    #   assert_equal 0, Sidekiq::Queues["default"].size
    #
    # This can be useful to make sure jobs don't linger between tests:
    #
    #   RSpec.configure do |config|
    #     config.before(:each) do
    #       Sidekiq::Queues.clear_all
    #     end
    #   end
    #
    class << self
      def [](queue)
        jobs_by_queue[queue]
      end

      def push(queue, klass, job)
        jobs_by_queue[queue] << job
        jobs_by_class[klass] << job
      end

      def jobs_by_queue
        @jobs_by_queue ||= Hash.new { |hash, key| hash[key] = [] }
      end

      def jobs_by_class
        @jobs_by_class ||= Hash.new { |hash, key| hash[key] = [] }
      end
      alias_method :jobs_by_worker, :jobs_by_class

      def delete_for(jid, queue, klass)
        jobs_by_queue[queue.to_s].delete_if { |job| job["jid"] == jid }
        jobs_by_class[klass].delete_if { |job| job["jid"] == jid }
      end

      def clear_for(queue, klass)
        jobs_by_queue[queue.to_s].clear
        jobs_by_class[klass].clear
      end

      def clear_all
        jobs_by_queue.clear
        jobs_by_class.clear
      end
    end
  end

  module Job
    ##
    # The Sidekiq testing infrastructure overrides perform_async
    # so that it does not actually touch the network.  Instead it
    # stores the asynchronous jobs in a per-class array so that
    # their presence/absence can be asserted by your tests.
    #
    # This is similar to ActionMailer's :test delivery_method and its
    # ActionMailer::Base.deliveries array.
    #
    # Example:
    #
    #   require 'sidekiq/testing'
    #
    #   assert_equal 0, HardJob.jobs.size
    #   HardJob.perform_async(:something)
    #   assert_equal 1, HardJob.jobs.size
    #   assert_equal :something, HardJob.jobs[0]['args'][0]
    #
    # You can also clear and drain all job types:
    #
    #   Sidekiq::Job.clear_all # or .drain_all
    #
    # This can be useful to make sure jobs don't linger between tests:
    #
    #   RSpec.configure do |config|
    #     config.before(:each) do
    #       Sidekiq::Job.clear_all
    #     end
    #   end
    #
    # or for acceptance testing, i.e. with cucumber:
    #
    #   AfterStep do
    #     Sidekiq::Job.drain_all
    #   end
    #
    #   When I sign up as "foo@example.com"
    #   Then I should receive a welcome email to "foo@example.com"
    #
    module ClassMethods
      # Queue for this worker
      def queue
        get_sidekiq_options["queue"]
      end

      # Jobs queued for this worker
      def jobs
        Queues.jobs_by_class[to_s]
      end

      # Clear all jobs for this worker
      def clear
        Queues.clear_for(queue, to_s)
      end

      # Drain and run all jobs for this worker
      def drain
        while jobs.any?
          next_job = jobs.first
          Queues.delete_for(next_job["jid"], next_job["queue"], to_s)
          process_job(next_job)
        end
      end

      # Pop out a single job and perform it
      def perform_one
        raise(EmptyQueueError, "perform_one called with empty job queue") if jobs.empty?
        next_job = jobs.first
        Queues.delete_for(next_job["jid"], next_job["queue"], to_s)
        process_job(next_job)
      end

      def process_job(job)
        inst = new
        inst.jid = job["jid"]
        inst.bid = job["bid"] if inst.respond_to?(:bid=)
        Sidekiq::Testing.server_middleware.invoke(inst, job, job["queue"]) do
          execute_job(inst, job["args"])
        end
      end

      def execute_job(worker, args)
        worker.perform(*args)
      end
    end

    class << self
      def jobs # :nodoc:
        Queues.jobs_by_queue.values.flatten
      end

      # Clear all queued jobs
      def clear_all
        Queues.clear_all
      end

      # Drain (execute) all queued jobs
      def drain_all
        while jobs.any?
          job_classes = jobs.map { |job| job["class"] }.uniq

          job_classes.each do |job_class|
            Object.const_get(job_class).drain
          end
        end
      end
    end
  end

  module TestingExtensions
    def jobs_for(klass)
      jobs.select do |job|
        marshalled = job["args"][0]
        marshalled.index(klass.to_s) && YAML.safe_load(marshalled)[0] == klass
      end
    end
  end
end

if defined?(::Rails) && Rails.respond_to?(:env) && !Rails.env.test? && !$TESTING
  warn("⛔️ WARNING: Sidekiq testing API enabled, but this is not the test environment.  Your jobs will not go to Redis.", uplevel: 1)
end
