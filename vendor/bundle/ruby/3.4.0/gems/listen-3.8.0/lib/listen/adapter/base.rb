# frozen_string_literal: true

require 'listen/options'
require 'listen/record'
require 'listen/change'
require 'listen/thread'

module Listen
  module Adapter
    class Base
      attr_reader :options, :config

      # TODO: only used by tests
      DEFAULTS = {}.freeze

      def initialize(config)
        @started = false
        @config = config

        @configured = nil

        fail 'No directories to watch!' if config.directories.empty?

        defaults = self.class.const_get('DEFAULTS')
        @options = Listen::Options.new(config.adapter_options, defaults)
      rescue
        _log_exception 'adapter config failed: %s:%s called from: %s', caller
        raise
      end

      # TODO: it's a separate method as a temporary workaround for tests
      # rubocop:disable Metrics/MethodLength
      def configure
        if @configured
          Listen.logger.warn('Adapter already configured!')
          return
        end

        @configured = true

        @callbacks ||= {}
        config.directories.each do |dir|
          callback = @callbacks[dir] || lambda do |event|
            _process_event(dir, event)
          end
          @callbacks[dir] = callback
          _configure(dir, &callback)
        end

        @snapshots ||= {}
        # TODO: separate config per directory (some day maybe)
        change_config = Change::Config.new(config.queue, config.silencer)
        config.directories.each do |dir|
          record = Record.new(dir, config.silencer)
          snapshot = Change.new(change_config, record)
          @snapshots[dir] = snapshot
        end
      end
      # rubocop:enable Metrics/MethodLength

      def started?
        @started
      end

      def start
        configure

        if started?
          Listen.logger.warn('Adapter already started!')
          return
        end

        @started = true

        @run_thread = Listen::Thread.new("run_thread") do
          @snapshots.each_value do |snapshot|
            _timed('Record.build()') { snapshot.record.build }
          end
          _run
        end
      end

      def stop
        _stop
        config.queue.close # this causes queue.pop to return `nil` to the front-end
      end

      private

      def _stop
        @run_thread&.kill
        @run_thread = nil
      end

      def _timed(title)
        start = MonotonicTime.now
        yield
        diff = MonotonicTime.now - start
        Listen.logger.info format('%s: %.05f seconds', title, diff)
      rescue
        Listen.logger.warn "#{title} crashed: #{$ERROR_INFO.inspect}"
        raise
      end

      # TODO: allow backend adapters to pass specific invalidation objects
      # e.g. Darwin -> DirRescan, INotify -> MoveScan, etc.
      def _queue_change(type, dir, rel_path, options)
        @snapshots[dir].invalidate(type, rel_path, options)
      end

      def _log_exception(msg, caller_stack)
        formatted = format(
          msg,
          $ERROR_INFO,
          $ERROR_POSITION * "\n",
          caller_stack * "\n"
        )

        Listen.logger.error(formatted)
      end

      class << self
        def usable?
          const_get('OS_REGEXP') =~ RbConfig::CONFIG['target_os']
        end
      end
    end
  end
end
