# frozen_string_literal: true

require 'listen/file'
require 'listen/directory'

module Listen
  # TODO: rename to Snapshot
  class Change
    # TODO: test this class for coverage
    class Config
      def initialize(queue, silencer)
        @queue = queue
        @silencer = silencer
      end

      def silenced?(path, type)
        @silencer.silenced?(Pathname(path), type)
      end

      def queue(*args)
        @queue << args
      end
    end

    attr_reader :record

    def initialize(config, record)
      @config = config
      @record = record
    end

    # Invalidate some part of the snapshot/record (dir, file, subtree, etc.)
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def invalidate(type, rel_path, options)
      watched_dir = Pathname.new(record.root)

      change = options[:change]
      cookie = options[:cookie]

      if !cookie && @config.silenced?(rel_path, type)
        Listen.logger.debug { "(silenced): #{rel_path.inspect}" }
        return
      end

      path = watched_dir + rel_path

      Listen.logger.debug do
        log_details = options[:silence] && 'recording' || change || 'unknown'
        "#{log_details}: #{type}:#{path} (#{options.inspect})"
      end

      if change
        options = cookie ? { cookie: cookie } : {}
        @config.queue(type, change, watched_dir, rel_path, options)
      elsif type == :dir
        # NOTE: POSSIBLE RECURSION
        # TODO: fix - use a queue instead
        Directory.scan(self, rel_path, options)
      elsif (change = File.change(record, rel_path)) && !options[:silence]
        @config.queue(:file, change, watched_dir, rel_path)
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
