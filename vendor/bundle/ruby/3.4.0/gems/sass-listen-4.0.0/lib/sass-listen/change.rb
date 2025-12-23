require 'sass-listen/file'
require 'sass-listen/directory'

module SassListen
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
    def invalidate(type, rel_path, options)
      watched_dir = Pathname.new(record.root)

      change = options[:change]
      cookie = options[:cookie]

      if !cookie && config.silenced?(rel_path, type)
        SassListen::Logger.debug {  "(silenced): #{rel_path.inspect}" }
        return
      end

      path = watched_dir + rel_path

      SassListen::Logger.debug do
        log_details = options[:silence] && 'recording' || change || 'unknown'
        "#{log_details}: #{type}:#{path} (#{options.inspect})"
      end

      if change
        options = cookie ? { cookie: cookie } : {}
        config.queue(type, change, watched_dir, rel_path, options)
      else
        if type == :dir
          # NOTE: POSSIBLE RECURSION
          # TODO: fix - use a queue instead
          Directory.scan(self, rel_path, options)
        else
          change = File.change(record, rel_path)
          return if !change || options[:silence]
          config.queue(:file, change, watched_dir, rel_path)
        end
      end
    rescue RuntimeError => ex
      msg = format(
        '%s#%s crashed %s:%s',
        self.class,
        __method__,
        exinspect,
        ex.backtrace * "\n")
      SassListen::Logger.error(msg)
      raise
    end

    private

    attr_reader :config
  end
end
