# frozen_string_literal: true

module Datadog
  module Core
    module Remote
      # Worker executes a block every interval on a separate Thread
      class Worker
        def initialize(interval:, logger:, &block)
          @mutex = Mutex.new
          @thr = nil

          @starting = false
          @started = false
          @stopped = false

          @interval = interval
          @logger = logger
          raise ArgumentError, 'can not initialize a worker without a block' unless block

          @block = block
        end

        attr_reader :logger

        def start
          logger.debug { 'remote worker starting' }

          acquire_lock

          if @stopped
            logger.debug('remote worker: refusing to restart after previous stop')
            return
          end

          return if @starting || @started

          @starting = true

          thread = Thread.new { poll(@interval) }
          thread.name = self.class.name
          thread.thread_variable_set(:fork_safe, true)
          @thr = thread

          @started = true
          @starting = false

          logger.debug { 'remote worker started' }
        ensure
          release_lock
        end

        def stop
          logger.debug { 'remote worker stopping' }

          acquire_lock

          thread = @thr

          if thread
            thread.kill
            thread.join
          end

          @started = false
          @thr = nil
          @stopped = true

          logger.debug { 'remote worker stopped' }
        ensure
          release_lock
        end

        def started?
          @started
        end

        private

        def acquire_lock
          @mutex.lock
        end

        def release_lock
          @mutex.unlock
        end

        def poll(interval)
          loop do
            break unless @mutex.synchronize { @starting || @started }

            call

            sleep(interval)
          end
        end

        def call
          logger.debug { 'remote worker perform' }

          @block.call
        end
      end
    end
  end
end
