require 'sass-listen/adapter/base'
require 'sass-listen/adapter/bsd'
require 'sass-listen/adapter/darwin'
require 'sass-listen/adapter/linux'
require 'sass-listen/adapter/polling'
require 'sass-listen/adapter/windows'

module SassListen
  module Adapter
    OPTIMIZED_ADAPTERS = [Darwin, Linux, BSD, Windows]
    POLLING_FALLBACK_MESSAGE = 'SassListen will be polling for changes.'\
      'Learn more at https://github.com/guard/listen#listen-adapters.'

    def self.select(options = {})
      _log :debug, 'Adapter: considering polling ...'
      return Polling if options[:force_polling]
      _log :debug, 'Adapter: considering optimized backend...'
      return _usable_adapter_class if _usable_adapter_class
      _log :debug, 'Adapter: falling back to polling...'
      _warn_polling_fallback(options)
      Polling
    rescue
      _log :warn, format('Adapter: failed: %s:%s', $ERROR_POSITION.inspect,
                         $ERROR_POSITION * "\n")
      raise
    end

    private

    def self._usable_adapter_class
      OPTIMIZED_ADAPTERS.detect(&:usable?)
    end

    def self._warn_polling_fallback(options)
      msg = options.fetch(:polling_fallback_message, POLLING_FALLBACK_MESSAGE)
      Kernel.warn "[SassListen warning]:\n  #{msg}" if msg
    end

    def self._log(type, message)
      SassListen::Logger.send(type, message)
    end
  end
end
