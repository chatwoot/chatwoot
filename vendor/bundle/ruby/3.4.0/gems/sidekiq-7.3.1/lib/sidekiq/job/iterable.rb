# frozen_string_literal: true

require_relative "iterable/enumerators"

module Sidekiq
  module Job
    class Interrupted < ::RuntimeError; end

    module Iterable
      include Enumerators

      # @api private
      def self.included(base)
        base.extend(ClassMethods)
      end

      # @api private
      module ClassMethods
        def method_added(method_name)
          raise "#{self} is an iterable job and must not define #perform" if method_name == :perform
          super
        end
      end

      # @api private
      def initialize
        super

        @_executions = 0
        @_cursor = nil
        @_start_time = nil
        @_runtime = 0
      end

      # A hook to override that will be called when the job starts iterating.
      #
      # It is called only once, for the first time.
      #
      def on_start
      end

      # A hook to override that will be called around each iteration.
      #
      # Can be useful for some metrics collection, performance tracking etc.
      #
      def around_iteration
        yield
      end

      # A hook to override that will be called when the job resumes iterating.
      #
      def on_resume
      end

      # A hook to override that will be called each time the job is interrupted.
      #
      # This can be due to interruption or sidekiq stopping.
      #
      def on_stop
      end

      # A hook to override that will be called when the job finished iterating.
      #
      def on_complete
      end

      # The enumerator to be iterated over.
      #
      # @return [Enumerator]
      #
      # @raise [NotImplementedError] with a message advising subclasses to
      #     implement an override for this method.
      #
      def build_enumerator(*)
        raise NotImplementedError, "#{self.class.name} must implement a '#build_enumerator' method"
      end

      # The action to be performed on each item from the enumerator.
      #
      # @return [void]
      #
      # @raise [NotImplementedError] with a message advising subclasses to
      #     implement an override for this method.
      #
      def each_iteration(*)
        raise NotImplementedError, "#{self.class.name} must implement an '#each_iteration' method"
      end

      def iteration_key
        "it-#{jid}"
      end

      # @api private
      def perform(*arguments)
        fetch_previous_iteration_state

        @_executions += 1
        @_start_time = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)

        enumerator = build_enumerator(*arguments, cursor: @_cursor)
        unless enumerator
          logger.info("'#build_enumerator' returned nil, skipping the job.")
          return
        end

        assert_enumerator!(enumerator)

        if @_executions == 1
          on_start
        else
          on_resume
        end

        completed = catch(:abort) do
          iterate_with_enumerator(enumerator, arguments)
        end

        on_stop
        completed = handle_completed(completed)

        if completed
          on_complete
          cleanup
        else
          reenqueue_iteration_job
        end
      end

      private

      def fetch_previous_iteration_state
        state = Sidekiq.redis { |conn| conn.hgetall(iteration_key) }

        unless state.empty?
          @_executions = state["ex"].to_i
          @_cursor = Sidekiq.load_json(state["c"])
          @_runtime = state["rt"].to_f
        end
      end

      STATE_FLUSH_INTERVAL = 5 # seconds
      # we need to keep the state around as long as the job
      # might be retrying
      STATE_TTL = 30 * 24 * 60 * 60 # one month

      def iterate_with_enumerator(enumerator, arguments)
        found_record = false
        state_flushed_at = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)

        enumerator.each do |object, cursor|
          found_record = true
          @_cursor = cursor

          is_interrupted = interrupted?
          if ::Process.clock_gettime(::Process::CLOCK_MONOTONIC) - state_flushed_at >= STATE_FLUSH_INTERVAL || is_interrupted
            flush_state
            state_flushed_at = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
          end

          return false if is_interrupted

          around_iteration do
            each_iteration(object, *arguments)
          end
        end

        logger.debug("Enumerator found nothing to iterate!") unless found_record
        true
      ensure
        @_runtime += (::Process.clock_gettime(::Process::CLOCK_MONOTONIC) - @_start_time)
      end

      def reenqueue_iteration_job
        flush_state
        logger.debug { "Interrupting job (cursor=#{@_cursor.inspect})" }

        raise Interrupted
      end

      def assert_enumerator!(enum)
        unless enum.is_a?(Enumerator)
          raise ArgumentError, <<~MSG
            #build_enumerator must return an Enumerator, but returned #{enum.class}.
            Example:
              def build_enumerator(params, cursor:)
                active_record_records_enumerator(
                  Shop.find(params["shop_id"]).products,
                  cursor: cursor
                )
              end
          MSG
        end
      end

      def flush_state
        key = iteration_key
        state = {
          "ex" => @_executions,
          "c" => Sidekiq.dump_json(@_cursor),
          "rt" => @_runtime
        }

        Sidekiq.redis do |conn|
          conn.multi do |pipe|
            pipe.hset(key, state)
            pipe.expire(key, STATE_TTL)
          end
        end
      end

      def cleanup
        logger.debug {
          format("Completed iteration. executions=%d runtime=%.3f", @_executions, @_runtime)
        }
        Sidekiq.redis { |conn| conn.unlink(iteration_key) }
      end

      def handle_completed(completed)
        case completed
        when nil, # someone aborted the job but wants to call the on_complete callback
             true
          true
        when false
          false
        else
          raise "Unexpected thrown value: #{completed.inspect}"
        end
      end
    end
  end
end
