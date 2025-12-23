# frozen_string_literal: true

module Listen
  module Adapter
    # Adapter implementation for Windows `wdm`.
    #
    class Windows < Base
      OS_REGEXP = /mswin|mingw|cygwin/i.freeze

      BUNDLER_DECLARE_GEM = <<-EOS.gsub(/^ {6}/, '')
        Please add the following to your Gemfile to avoid polling for changes:
          gem 'wdm', '>= 0.1.0' if Gem.win_platform?
      EOS

      def self.usable?
        return false unless super
        require 'wdm'
        true
      rescue LoadError
        Listen.logger.debug format('wdm - load failed: %s:%s', $ERROR_INFO,
                                   $ERROR_POSITION * "\n")

        Kernel.warn BUNDLER_DECLARE_GEM
        false
      end

      private

      def _configure(dir)
        require 'wdm'
        Listen.logger.debug 'wdm - starting...'
        @worker ||= WDM::Monitor.new
        @worker.watch_recursively(dir.to_s, :files) do |change|
          yield([:file, change])
        end

        @worker.watch_recursively(dir.to_s, :directories) do |change|
          yield([:dir, change])
        end

        @worker.watch_recursively(dir.to_s, :attributes, :last_write) do |change|
          yield([:attr, change])
        end
      end

      def _run
        @worker.run!
      end

      # rubocop:disable Metrics/MethodLength
      def _process_event(dir, event)
        Listen.logger.debug "wdm - callback: #{event.inspect}"

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
          case change.type
          when :removed
            # TODO: check if watched dir?
            _queue_change(:dir, dir, Pathname(rel_path).dirname.to_s, {})
          when :added
            _queue_change(:dir, dir, rel_path, {})
            # do nothing - changed directory means either:
            #   - removed subdirs (handled above)
            #   - added subdirs (handled above)
            #   - removed files (handled by _file_callback)
            #   - added files (handled by _file_callback)
            # so what's left?
          end
        end
      end
      # rubocop:enable Metrics/MethodLength

      def _change(type)
        { modified: [:modified, :attrib], # TODO: is attrib really passed?
          added:    [:added, :renamed_new_file],
          removed:  [:removed, :renamed_old_file] }.find do |change, types|
          types.include?(type) and break change
        end
      end
    end
  end
end
