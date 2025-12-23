# frozen_string_literal: true

require "zlib"
require "sidekiq/component"

module Sidekiq
  ##
  # Automatically retry jobs that fail in Sidekiq.
  # Sidekiq's retry support assumes a typical development lifecycle:
  #
  #   0. Push some code changes with a bug in it.
  #   1. Bug causes job processing to fail, Sidekiq's middleware captures
  #      the job and pushes it onto a retry queue.
  #   2. Sidekiq retries jobs in the retry queue multiple times with
  #      an exponential delay, the job continues to fail.
  #   3. After a few days, a developer deploys a fix. The job is
  #      reprocessed successfully.
  #   4. Once retries are exhausted, Sidekiq will give up and move the
  #      job to the Dead Job Queue (aka morgue) where it must be dealt with
  #      manually in the Web UI.
  #   5. After 6 months on the DJQ, Sidekiq will discard the job.
  #
  # A job looks like:
  #
  #     { 'class' => 'HardJob', 'args' => [1, 2, 'foo'], 'retry' => true }
  #
  # The 'retry' option also accepts a number (in place of 'true'):
  #
  #     { 'class' => 'HardJob', 'args' => [1, 2, 'foo'], 'retry' => 5 }
  #
  # The job will be retried this number of times before giving up. (If simply
  # 'true', Sidekiq retries 25 times)
  #
  # Relevant options for job retries:
  #
  #  * 'queue' - the queue for the initial job
  #  * 'retry_queue' - if job retries should be pushed to a different (e.g. lower priority) queue
  #  * 'retry_count' - number of times we've retried so far.
  #  * 'error_message' - the message from the exception
  #  * 'error_class' - the exception class
  #  * 'failed_at' - the first time it failed
  #  * 'retried_at' - the last time it was retried
  #  * 'backtrace' - the number of lines of error backtrace to store
  #
  # We don't store the backtrace by default as that can add a lot of overhead
  # to the job and everyone is using an error service, right?
  #
  # The default number of retries is 25 which works out to about 3 weeks
  # You can change the default maximum number of retries in your initializer:
  #
  #   Sidekiq.default_configuration[:max_retries] = 7
  #
  # or limit the number of retries for a particular job and send retries to
  # a low priority queue with:
  #
  #    class MyJob
  #      include Sidekiq::Job
  #      sidekiq_options retry: 10, retry_queue: 'low'
  #    end
  #
  class JobRetry
    # Handled means the job failed but has been dealt with
    # (by creating a retry, rescheduling it, etc). It still
    # needs to be logged and dispatched to error_handlers.
    class Handled < ::RuntimeError; end

    # Skip means the job failed but Sidekiq does not need to
    # create a retry, log it or send to error_handlers.
    class Skip < Handled; end

    include Sidekiq::Component

    DEFAULT_MAX_RETRY_ATTEMPTS = 25

    def initialize(capsule)
      @config = @capsule = capsule
      @max_retries = Sidekiq.default_configuration[:max_retries] || DEFAULT_MAX_RETRY_ATTEMPTS
      @backtrace_cleaner = Sidekiq.default_configuration[:backtrace_cleaner]
    end

    # The global retry handler requires only the barest of data.
    # We want to be able to retry as much as possible so we don't
    # require the job to be instantiated.
    def global(jobstr, queue)
      yield
    rescue Handled => ex
      raise ex
    rescue Sidekiq::Shutdown => ey
      # ignore, will be pushed back onto queue during hard_shutdown
      raise ey
    rescue Exception => e
      # ignore, will be pushed back onto queue during hard_shutdown
      raise Sidekiq::Shutdown if exception_caused_by_shutdown?(e)

      msg = Sidekiq.load_json(jobstr)
      if msg["retry"]
        process_retry(nil, msg, queue, e)
      else
        @capsule.config.death_handlers.each do |handler|
          handler.call(msg, e)
        rescue => handler_ex
          handle_exception(handler_ex, {context: "Error calling death handler", job: msg})
        end
      end

      raise Handled
    end

    # The local retry support means that any errors that occur within
    # this block can be associated with the given job instance.
    # This is required to support the `sidekiq_retries_exhausted` block.
    #
    # Note that any exception from the block is wrapped in the Skip
    # exception so the global block does not reprocess the error.  The
    # Skip exception is unwrapped within Sidekiq::Processor#process before
    # calling the handle_exception handlers.
    def local(jobinst, jobstr, queue)
      yield
    rescue Handled => ex
      raise ex
    rescue Sidekiq::Shutdown => ey
      # ignore, will be pushed back onto queue during hard_shutdown
      raise ey
    rescue Exception => e
      # ignore, will be pushed back onto queue during hard_shutdown
      raise Sidekiq::Shutdown if exception_caused_by_shutdown?(e)

      msg = Sidekiq.load_json(jobstr)
      if msg["retry"].nil?
        msg["retry"] = jobinst.class.get_sidekiq_options["retry"]
      end

      raise e unless msg["retry"]
      process_retry(jobinst, msg, queue, e)
      # We've handled this error associated with this job, don't
      # need to handle it at the global level
      raise Handled
    end

    private

    # Note that +jobinst+ can be nil here if an error is raised before we can
    # instantiate the job instance.  All access must be guarded and
    # best effort.
    def process_retry(jobinst, msg, queue, exception)
      max_retry_attempts = retry_attempts_from(msg["retry"], @max_retries)

      msg["queue"] = (msg["retry_queue"] || queue)

      m = exception_message(exception)
      if m.respond_to?(:scrub!)
        m.force_encoding("utf-8")
        m.scrub!
      end

      msg["error_message"] = m
      msg["error_class"] = exception.class.name
      count = if msg["retry_count"]
        msg["retried_at"] = Time.now.to_f
        msg["retry_count"] += 1
      else
        msg["failed_at"] = Time.now.to_f
        msg["retry_count"] = 0
      end

      if msg["backtrace"]
        backtrace = @backtrace_cleaner.call(exception.backtrace)
        lines = if msg["backtrace"] == true
          backtrace
        else
          backtrace[0...msg["backtrace"].to_i]
        end

        msg["error_backtrace"] = compress_backtrace(lines)
      end

      return retries_exhausted(jobinst, msg, exception) if count >= max_retry_attempts

      rf = msg["retry_for"]
      return retries_exhausted(jobinst, msg, exception) if rf && ((msg["failed_at"] + rf) < Time.now.to_f)

      strategy, delay = delay_for(jobinst, count, exception, msg)
      case strategy
      when :discard
        return # poof!
      when :kill
        return retries_exhausted(jobinst, msg, exception)
      end

      # Logging here can break retries if the logging device raises ENOSPC #3979
      # logger.debug { "Failure! Retry #{count} in #{delay} seconds" }
      jitter = rand(10) * (count + 1)
      retry_at = Time.now.to_f + delay + jitter
      payload = Sidekiq.dump_json(msg)
      redis do |conn|
        conn.zadd("retry", retry_at.to_s, payload)
      end
    end

    # returns (strategy, seconds)
    def delay_for(jobinst, count, exception, msg)
      rv = begin
        # sidekiq_retry_in can return two different things:
        # 1. When to retry next, as an integer of seconds
        # 2. A symbol which re-routes the job elsewhere, e.g. :discard, :kill, :default
        block = jobinst&.sidekiq_retry_in_block

        # the sidekiq_retry_in_block can be defined in a wrapped class (ActiveJob for instance)
        unless msg["wrapped"].nil?
          wrapped = Object.const_get(msg["wrapped"])
          block = wrapped.respond_to?(:sidekiq_retry_in_block) ? wrapped.sidekiq_retry_in_block : nil
        end
        block&.call(count, exception, msg)
      rescue Exception => e
        handle_exception(e, {context: "Failure scheduling retry using the defined `sidekiq_retry_in` in #{jobinst.class.name}, falling back to default"})
        nil
      end

      rv = rv.to_i if rv.respond_to?(:to_i)
      delay = (count**4) + 15
      if Integer === rv && rv > 0
        delay = rv
      elsif rv == :discard
        return [:discard, nil] # do nothing, job goes poof
      elsif rv == :kill
        return [:kill, nil]
      end

      [:default, delay]
    end

    def retries_exhausted(jobinst, msg, exception)
      rv = begin
        block = jobinst&.sidekiq_retries_exhausted_block

        # the sidekiq_retries_exhausted_block can be defined in a wrapped class (ActiveJob for instance)
        unless msg["wrapped"].nil?
          wrapped = Object.const_get(msg["wrapped"])
          block = wrapped.respond_to?(:sidekiq_retries_exhausted_block) ? wrapped.sidekiq_retries_exhausted_block : nil
        end
        block&.call(msg, exception)
      rescue => e
        handle_exception(e, {context: "Error calling retries_exhausted", job: msg})
      end

      return if rv == :discard # poof!
      send_to_morgue(msg) unless msg["dead"] == false

      @capsule.config.death_handlers.each do |handler|
        handler.call(msg, exception)
      rescue => e
        handle_exception(e, {context: "Error calling death handler", job: msg})
      end
    end

    def send_to_morgue(msg)
      logger.info { "Adding dead #{msg["class"]} job #{msg["jid"]}" }
      payload = Sidekiq.dump_json(msg)
      now = Time.now.to_f

      redis do |conn|
        conn.multi do |xa|
          xa.zadd("dead", now.to_s, payload)
          xa.zremrangebyscore("dead", "-inf", now - @capsule.config[:dead_timeout_in_seconds])
          xa.zremrangebyrank("dead", 0, - @capsule.config[:dead_max_jobs])
        end
      end
    end

    def retry_attempts_from(msg_retry, default)
      if msg_retry.is_a?(Integer)
        msg_retry
      else
        default
      end
    end

    def exception_caused_by_shutdown?(e, checked_causes = [])
      return false unless e.cause

      # Handle circular causes
      checked_causes << e.object_id
      return false if checked_causes.include?(e.cause.object_id)

      e.cause.instance_of?(Sidekiq::Shutdown) ||
        exception_caused_by_shutdown?(e.cause, checked_causes)
    end

    # Extract message from exception.
    # Set a default if the message raises an error
    def exception_message(exception)
      # App code can stuff all sorts of crazy binary data into the error message
      # that won't convert to JSON.
      exception.message.to_s[0, 10_000]
    rescue
      +"!!! ERROR MESSAGE THREW AN ERROR !!!"
    end

    def compress_backtrace(backtrace)
      serialized = Sidekiq.dump_json(backtrace)
      compressed = Zlib::Deflate.deflate(serialized)
      [compressed].pack("m0") # Base64.strict_encode64
    end
  end
end
