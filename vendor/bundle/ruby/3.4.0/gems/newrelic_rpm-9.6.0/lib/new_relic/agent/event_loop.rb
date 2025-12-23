# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'thread'

module NewRelic
  module Agent
    class EventLoop
      class Timer
        attr_reader :next_fire_time, :event, :interval, :last_fired_at

        def initialize(interval, event, repeat = false)
          @interval = interval
          @event = event
          @repeat = repeat
          @started_at = Process.clock_gettime(Process::CLOCK_REALTIME)
          @last_fired_at = nil
          reschedule
        end

        def reschedule
          @next_fire_time = calculate_next_fire_time
        end

        def advance(amount)
          @next_fire_time -= amount
        end

        def last_interval_start
          @last_fired_at || @started_at
        end

        def calculate_next_fire_time
          now = Process.clock_gettime(Process::CLOCK_REALTIME)
          return now if @interval == 0

          fire_time = @last_fired_at || now
          while fire_time <= now
            fire_time += @interval
          end
          fire_time
        end

        def set_fired_time
          @last_fired_at = Process.clock_gettime(Process::CLOCK_REALTIME)
        end

        def due?(now = Process.clock_gettime(Process::CLOCK_REALTIME))
          now >= @next_fire_time
        end

        def finished?
          !@repeat && @last_fired_at
        end
      end

      def initialize
        @self_pipe_rd, @self_pipe_wr = IO.pipe
        @event_queue = Queue.new
        @stopped = false
        @timers = {}

        @subscriptions = Hash.new { |h, k| h[k] = [] }
        @subscriptions[:__add_timer] << proc { |t| set_timer(t) }
        @subscriptions[:__add_event] << proc { |e, blk| @subscriptions[e] << blk }
      end

      def set_timer(timer)
        existing_timer = @timers[timer.event]

        if existing_timer
          elapsed_interval = Process.clock_gettime(Process::CLOCK_REALTIME) - existing_timer.last_interval_start
          timer.advance(elapsed_interval)
        end

        @timers[timer.event] = timer

        fire_timer(timer)
      end

      def next_timeout
        return nil if @timers.empty?

        timeout = @timers.values.map(&:next_fire_time).min - Process.clock_gettime(Process::CLOCK_REALTIME)
        [timeout, 0].max
      end

      def stopped?
        @stopped
      end

      def stop
        @stopped = true
        wakeup
      end

      def run
        ::NewRelic::Agent.logger.debug('Running event loop')
        while !stopped?
          run_once
        end
      end

      def run_once(nonblock = false)
        wait_to_run(nonblock)

        prune_timers
        fire_timers

        until @event_queue.empty?
          evt, args = @event_queue.pop
          dispatch_event(evt, args)
          reschedule_timer_for_event(evt)
        end
      end

      def wait_to_run(nonblock)
        timeout = nonblock ? 0 : next_timeout
        ready = IO.select([@self_pipe_rd], nil, nil, timeout)

        if ready && ready[0] && ready[0][0] && ready[0][0] == @self_pipe_rd
          @self_pipe_rd.read(1)
        end
      end

      def fire_timers
        @timers.each do |event, timer|
          fire_timer(timer)
        end
      end

      def fire_timer(timer)
        if timer.due?
          @event_queue << [timer.event]
          timer.set_fired_time
        end
      end

      def prune_timers
        @timers.delete_if { |e, t| t.finished? }
      end

      def dispatch_event(event, args)
        NewRelic::Agent.logger.debug("EventLoop: Dispatching event '#{event}' with #{@subscriptions[event].size} callback(s).")

        errors = []
        @subscriptions[event].each do |s|
          begin
            s.call(*args)
          rescue NewRelic::Agent::ForceRestartException, NewRelic::Agent::ForceDisconnectException
            raise
          rescue => e
            errors << e
          end
        end

        if !errors.empty?
          ::NewRelic::Agent.logger.error("#{errors.size} error(s) running task for event '#{event}' in Agent Event Loop:", *errors)
        end
      end

      def reschedule_timer_for_event(e)
        @timers[e]&.reschedule
      end

      def on(event, &blk)
        fire(:__add_event, event, blk)
      end

      def fire(event, *args)
        @event_queue << [event, args]
        wakeup
      end

      def fire_every(interval, event)
        ::NewRelic::Agent.logger.debug("Firing event #{event} every #{interval} seconds.")
        fire(:__add_timer, Timer.new(interval, event, true))
      end

      def fire_after(interval, event)
        ::NewRelic::Agent.logger.debug("Firing event #{event} after #{interval} seconds.")
        fire(:__add_timer, Timer.new(interval, event, false))
      end

      def wakeup
        begin
          @self_pipe_wr.write_nonblock('.')
        rescue Errno::EAGAIN
          ::NewRelic::Agent.logger.debug('Failed to wakeup event loop')
        end
      end
    end
  end
end
