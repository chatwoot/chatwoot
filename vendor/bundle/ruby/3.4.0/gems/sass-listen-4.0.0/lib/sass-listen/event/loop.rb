require 'thread'

require 'timeout'
require 'sass-listen/event/processor'

module SassListen
  module Event
    class Loop
      class Error < RuntimeError
        class NotStarted < Error
        end
      end

      def initialize(config)
        @config = config
        @wait_thread = nil
        @state = :paused
        @reasons = ::Queue.new
      end

      def wakeup_on_event
        return if stopped?
        return unless processing?
        return unless wait_thread.alive?
        _wakeup(:event)
      end

      def paused?
        wait_thread && state == :paused
      end

      def processing?
        return false if stopped?
        return false if paused?
        state == :processing
      end

      def setup
        # TODO: use a Fiber instead?
        q = ::Queue.new
        @wait_thread = Internals::ThreadPool.add do
          _wait_for_changes(q, config)
        end

        SassListen::Logger.debug('Waiting for processing to start...')
        Timeout.timeout(5) { q.pop }
      end

      def resume
        fail Error::NotStarted if stopped?
        return unless wait_thread
        _wakeup(:resume)
      end

      def pause
        # TODO: works?
        # fail NotImplementedError
      end

      def teardown
        return unless wait_thread
        if wait_thread.alive?
          _wakeup(:teardown)
          wait_thread.join
        end
        @wait_thread = nil
      end

      def stopped?
        !wait_thread
      end

      private

      attr_reader :config
      attr_reader :wait_thread

      attr_accessor :state

      def _wait_for_changes(ready_queue, config)
        processor = Event::Processor.new(config, @reasons)

        _wait_until_resumed(ready_queue)
        processor.loop_for(config.min_delay_between_events)
      rescue StandardError => ex
        _nice_error(ex)
      end

      def _sleep(*args)
        Kernel.sleep(*args)
      end

      def _wait_until_resumed(ready_queue)
        self.state = :paused
        ready_queue << :ready
        sleep
        self.state = :processing
      end

      def _nice_error(ex)
        indent = "\n -- "
        msg = format(
          'exception while processing events: %s Backtrace:%s%s',
          ex,
          indent,
          ex.backtrace * indent
        )
        SassListen::Logger.error(msg)
      end

      def _wakeup(reason)
        @reasons << reason
        wait_thread.wakeup
      end
    end
  end
end
