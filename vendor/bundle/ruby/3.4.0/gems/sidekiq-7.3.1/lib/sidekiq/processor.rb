# frozen_string_literal: true

require "sidekiq/fetch"
require "sidekiq/job_logger"
require "sidekiq/job_retry"

module Sidekiq
  ##
  # The Processor is a standalone thread which:
  #
  # 1. fetches a job from Redis
  # 2. executes the job
  #   a. instantiate the job class
  #   b. run the middleware chain
  #   c. call #perform
  #
  # A Processor can exit due to shutdown or due to
  # an error during job execution.
  #
  # If an error occurs in the job execution, the
  # Processor calls the Manager to create a new one
  # to replace itself and exits.
  #
  class Processor
    include Sidekiq::Component

    attr_reader :thread
    attr_reader :job
    attr_reader :capsule

    def initialize(capsule, &block)
      @config = @capsule = capsule
      @callback = block
      @down = false
      @done = false
      @job = nil
      @thread = nil
      @reloader = Sidekiq.default_configuration[:reloader]
      @job_logger = (capsule.config[:job_logger] || Sidekiq::JobLogger).new(capsule.config)
      @retrier = Sidekiq::JobRetry.new(capsule)
    end

    def terminate(wait = false)
      @done = true
      return unless @thread
      @thread.value if wait
    end

    def kill(wait = false)
      @done = true
      return unless @thread
      # unlike the other actors, terminate does not wait
      # for the thread to finish because we don't know how
      # long the job will take to finish.  Instead we
      # provide a `kill` method to call after the shutdown
      # timeout passes.
      @thread.raise ::Sidekiq::Shutdown
      @thread.value if wait
    end

    def stopping?
      @done
    end

    def start
      @thread ||= safe_thread("#{config.name}/processor", &method(:run))
    end

    private unless $TESTING

    def run
      # By setting this thread-local, Sidekiq.redis will access +Sidekiq::Capsule#redis_pool+
      # instead of the global pool in +Sidekiq::Config#redis_pool+.
      Thread.current[:sidekiq_capsule] = @capsule

      process_one until @done
      @callback.call(self)
    rescue Sidekiq::Shutdown
      @callback.call(self)
    rescue Exception => ex
      @callback.call(self, ex)
    end

    def process_one(&block)
      @job = fetch
      process(@job) if @job
      @job = nil
    end

    def get_one
      uow = capsule.fetcher.retrieve_work
      if @down
        logger.info { "Redis is online, #{::Process.clock_gettime(::Process::CLOCK_MONOTONIC) - @down} sec downtime" }
        @down = nil
      end
      uow
    rescue Sidekiq::Shutdown
    rescue => ex
      handle_fetch_exception(ex)
    end

    def fetch
      j = get_one
      if j && @done
        j.requeue
        nil
      else
        j
      end
    end

    def handle_fetch_exception(ex)
      unless @down
        @down = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
        logger.error("Error fetching job: #{ex}")
        handle_exception(ex)
      end
      sleep(1)
      nil
    end

    def dispatch(job_hash, queue, jobstr)
      # since middleware can mutate the job hash
      # we need to clone it to report the original
      # job structure to the Web UI
      # or to push back to redis when retrying.
      # To avoid costly and, most of the time, useless cloning here,
      # we pass original String of JSON to respected methods
      # to re-parse it there if we need access to the original, untouched job

      @job_logger.prepare(job_hash) do
        @retrier.global(jobstr, queue) do
          @job_logger.call(job_hash, queue) do
            stats(jobstr, queue) do
              # Rails 5 requires a Reloader to wrap code execution.  In order to
              # constantize the worker and instantiate an instance, we have to call
              # the Reloader.  It handles code loading, db connection management, etc.
              # Effectively this block denotes a "unit of work" to Rails.
              @reloader.call do
                klass = Object.const_get(job_hash["class"])
                inst = klass.new
                inst.jid = job_hash["jid"]
                inst._context = self
                @retrier.local(inst, jobstr, queue) do
                  yield inst
                end
              end
            end
          end
        end
      end
    end

    IGNORE_SHUTDOWN_INTERRUPTS = {Sidekiq::Shutdown => :never}
    private_constant :IGNORE_SHUTDOWN_INTERRUPTS
    ALLOW_SHUTDOWN_INTERRUPTS = {Sidekiq::Shutdown => :immediate}
    private_constant :ALLOW_SHUTDOWN_INTERRUPTS

    def process(uow)
      jobstr = uow.job
      queue = uow.queue_name

      # Treat malformed JSON as a special case: job goes straight to the morgue.
      job_hash = nil
      begin
        job_hash = Sidekiq.load_json(jobstr)
      rescue => ex
        handle_exception(ex, {context: "Invalid JSON for job", jobstr: jobstr})
        now = Time.now.to_f
        redis do |conn|
          conn.multi do |xa|
            xa.zadd("dead", now.to_s, jobstr)
            xa.zremrangebyscore("dead", "-inf", now - @capsule.config[:dead_timeout_in_seconds])
            xa.zremrangebyrank("dead", 0, - @capsule.config[:dead_max_jobs])
          end
        end
        return uow.acknowledge
      end

      ack = false
      Thread.handle_interrupt(IGNORE_SHUTDOWN_INTERRUPTS) do
        Thread.handle_interrupt(ALLOW_SHUTDOWN_INTERRUPTS) do
          dispatch(job_hash, queue, jobstr) do |inst|
            config.server_middleware.invoke(inst, job_hash, queue) do
              execute_job(inst, job_hash["args"])
            end
          end
          ack = true
        rescue Sidekiq::Shutdown
          # Had to force kill this job because it didn't finish
          # within the timeout.  Don't acknowledge the work since
          # we didn't properly finish it.
        rescue Sidekiq::JobRetry::Skip => s
          # Skip means we handled this error elsewhere. We don't
          # need to log or report the error.
          ack = true
          raise s
        rescue Sidekiq::JobRetry::Handled => h
          # this is the common case: job raised error and Sidekiq::JobRetry::Handled
          # signals that we created a retry successfully.  We can acknowledge the job.
          ack = true
          e = h.cause || h
          handle_exception(e, {context: "Job raised exception", job: job_hash})
          raise e
        rescue Exception => ex
          # Unexpected error!  This is very bad and indicates an exception that got past
          # the retry subsystem (e.g. network partition).  We won't acknowledge the job
          # so it can be rescued when using Sidekiq Pro.
          handle_exception(ex, {context: "Internal exception!", job: job_hash, jobstr: jobstr})
          raise ex
        end
      ensure
        if ack
          uow.acknowledge
        end
      end
    end

    def execute_job(inst, cloned_args)
      inst.perform(*cloned_args)
    end

    # Ruby doesn't provide atomic counters out of the box so we'll
    # implement something simple ourselves.
    # https://bugs.ruby-lang.org/issues/14706
    class Counter
      def initialize
        @value = 0
        @lock = Mutex.new
      end

      def incr(amount = 1)
        @lock.synchronize { @value += amount }
      end

      def reset
        @lock.synchronize {
          val = @value
          @value = 0
          val
        }
      end
    end

    # jruby's Hash implementation is not threadsafe, so we wrap it in a mutex here
    class SharedWorkState
      def initialize
        @work_state = {}
        @lock = Mutex.new
      end

      def set(tid, hash)
        @lock.synchronize { @work_state[tid] = hash }
      end

      def delete(tid)
        @lock.synchronize { @work_state.delete(tid) }
      end

      def dup
        @lock.synchronize { @work_state.dup }
      end

      def size
        @lock.synchronize { @work_state.size }
      end

      def clear
        @lock.synchronize { @work_state.clear }
      end
    end

    PROCESSED = Counter.new
    FAILURE = Counter.new
    WORK_STATE = SharedWorkState.new

    def stats(jobstr, queue)
      WORK_STATE.set(tid, {queue: queue, payload: jobstr, run_at: Time.now.to_i})

      begin
        yield
      rescue Exception
        FAILURE.incr
        raise
      ensure
        WORK_STATE.delete(tid)
        PROCESSED.incr
      end
    end
  end
end
