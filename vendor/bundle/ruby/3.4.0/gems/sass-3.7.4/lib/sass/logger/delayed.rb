require 'sass/logger/log_level'

# A logger that delays messages until they're explicitly flushed to an inner
# logger.
#
# This can be installed around the current logger by calling \{#install!}, and
# the original logger can be replaced by calling \{#uninstall!}. The log
# messages can be flushed by calling \{#flush}.
class Sass::Logger::Delayed < Sass::Logger::Base
  # Installs a new delayed logger as the current Sass logger, wrapping the
  # original logger.
  #
  # This can be undone by calling \{#uninstall!}.
  #
  # @return [Sass::Logger::Delayed] The newly-created logger.
  def self.install!
    logger = Sass::Logger::Delayed.new(Sass.logger)
    Sass.logger = logger
    logger
  end

  # Creates a delayed logger wrapping `inner`.
  #
  # @param inner [Sass::Logger::Base] The wrapped logger.
  def initialize(inner)
    self.log_level = inner.log_level
    @inner = inner
    @messages = []
  end

  # Flushes all queued logs to the wrapped logger.
  def flush
    @messages.each {|(l, m)| @inner.log(l, m)}
  end

  # Uninstalls this logger from \{Sass.logger\}. This should only be called if
  # the logger was installed using \{#install!}
  def uninstall!
    if Sass.logger != self
      throw Exception.new("Can't uninstall a logger that's not currently installed.")
    end

    @inner.log_level = log_level
    Sass.logger = @inner
  end

  def _log(level, message)
    @messages << [level, message]
  end
end
