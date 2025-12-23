# frozen_string_literal: true

require "sidekiq/processor"
require "set"

module Sidekiq
  ##
  # The Manager is the central coordination point in Sidekiq, controlling
  # the lifecycle of the Processors.
  #
  # Tasks:
  #
  # 1. start: Spin up Processors.
  # 3. processor_died: Handle job failure, throw away Processor, create new one.
  # 4. quiet: shutdown idle Processors.
  # 5. stop: hard stop the Processors by deadline.
  #
  # Note that only the last task requires its own Thread since it has to monitor
  # the shutdown process.  The other tasks are performed by other threads.
  #
  class Manager
    include Sidekiq::Component

    attr_reader :workers
    attr_reader :capsule

    def initialize(capsule)
      @config = @capsule = capsule
      @count = capsule.concurrency
      raise ArgumentError, "Concurrency of #{@count} is not supported" if @count < 1

      @done = false
      @workers = Set.new
      @plock = Mutex.new
      @count.times do
        @workers << Processor.new(@config, &method(:processor_result))
      end
    end

    def start
      @workers.each(&:start)
    end

    def quiet
      return if @done
      @done = true

      logger.info { "Terminating quiet threads for #{capsule.name} capsule" }
      @workers.each(&:terminate)
    end

    def stop(deadline)
      quiet

      # some of the shutdown events can be async,
      # we don't have any way to know when they're done but
      # give them a little time to take effect
      sleep PAUSE_TIME
      return if @workers.empty?

      logger.info { "Pausing to allow jobs to finish..." }
      wait_for(deadline) { @workers.empty? }
      return if @workers.empty?

      hard_shutdown
    ensure
      capsule.stop
    end

    def processor_result(processor, reason = nil)
      @plock.synchronize do
        @workers.delete(processor)
        unless @done
          p = Processor.new(@config, &method(:processor_result))
          @workers << p
          p.start
        end
      end
    end

    def stopped?
      @done
    end

    private

    def hard_shutdown
      # We've reached the timeout and we still have busy threads.
      # They must die but their jobs shall live on.
      cleanup = nil
      @plock.synchronize do
        cleanup = @workers.dup
      end

      if cleanup.size > 0
        jobs = cleanup.map { |p| p.job }.compact

        logger.warn { "Terminating #{cleanup.size} busy threads" }
        logger.debug { "Jobs still in progress #{jobs.inspect}" }

        # Re-enqueue unfinished jobs
        # NOTE: You may notice that we may push a job back to redis before
        # the thread is terminated. This is ok because Sidekiq's
        # contract says that jobs are run AT LEAST once. Process termination
        # is delayed until we're certain the jobs are back in Redis because
        # it is worse to lose a job than to run it twice.
        capsule.fetcher.bulk_requeue(jobs)
      end

      cleanup.each do |processor|
        processor.kill
      end

      # when this method returns, we immediately call `exit` which may not give
      # the remaining threads time to run `ensure` blocks, etc. We pause here up
      # to 3 seconds to give threads a minimal amount of time to run `ensure` blocks.
      deadline = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC) + 3
      wait_for(deadline) { @workers.empty? }
    end

    # hack for quicker development / testing environment #2774
    PAUSE_TIME = $stdout.tty? ? 0.1 : 0.5

    # Wait for the orblock to be true or the deadline passed.
    def wait_for(deadline, &condblock)
      remaining = deadline - ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
      while remaining > PAUSE_TIME
        return if condblock.call
        sleep PAUSE_TIME
        remaining = deadline - ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
      end
    end
  end
end
