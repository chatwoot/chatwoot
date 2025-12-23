module SassListen
  module Adapter
    # Adapter implementation for Windows `wdm`.
    #
    class Windows < Base
      OS_REGEXP = /mswin|mingw|cygwin/i

      BUNDLER_DECLARE_GEM = <<-EOS.gsub(/^ {6}/, '')
        Please add the following to your Gemfile to avoid polling for changes:
          gem 'wdm', '>= 0.1.0' if Gem.win_platform?
      EOS

      def self.usable?
        return false unless super
        require 'wdm'
        true
      rescue LoadError
        _log :debug, format('wdm - load failed: %s:%s', $ERROR_INFO,
                            $ERROR_POSITION * "\n")

        Kernel.warn BUNDLER_DECLARE_GEM
        false
      end

      private

      def _configure(dir, &callback)
        require 'wdm'
        _log :debug, 'wdm - starting...'
        @worker ||= WDM::Monitor.new
        @worker.watch_recursively(dir.to_s, :files) do |change|
          callback.call([:file, change])
        end

        @worker.watch_recursively(dir.to_s, :directories) do |change|
          callback.call([:dir, change])
        end

        events = [:attributes, :last_write]
        @worker.watch_recursively(dir.to_s, *events) do |change|
          callback.call([:attr, change])
        end
      end

      def _run
        @worker.run!
      end

      def _process_event(dir, event)
        _log :debug, "wdm - callback: #{event.inspect}"

        type, change = event

        full_path = Pathname(change.path)

        rel_path = full_path.relative_path_from(dir).to_s

        options = { change: _change(change.type) }

        case type
        when :file
          _queue_change(:file, dir, rel_path, options)
        when :attr
          unless full_path.directory?
            _queue_change(:file, dir, rel_path, options)
          end
        when :dir
          if change.type == :removed
            # TODO: check if watched dir?
            _queue_change(:dir, dir, Pathname(rel_path).dirname.to_s, {})
          elsif change.type == :added
            _queue_change(:dir, dir, rel_path, {})
          else
            # do nothing - changed directory means either:
            #   - removed subdirs (handled above)
            #   - added subdirs (handled above)
            #   - removed files (handled by _file_callback)
            #   - added files (handled by _file_callback)
            # so what's left?
          end
        end
      rescue
        details = event.inspect
        _log :error, format('wdm - callback (%): %s:%s', details, $ERROR_INFO,
                            $ERROR_POSITION * "\n")
        raise
      end

      def _change(type)
        { modified: [:modified, :attrib], # TODO: is attrib really passed?
          added:    [:added, :renamed_new_file],
          removed:  [:removed, :renamed_old_file] }.each do |change, types|
          return change if types.include?(type)
        end
        nil
      end
    end
  end
end
