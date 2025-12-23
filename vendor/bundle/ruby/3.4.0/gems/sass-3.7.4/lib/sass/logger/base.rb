require 'sass/logger/log_level'

class Sass::Logger::Base
  include Sass::Logger::LogLevel

  attr_accessor :log_level
  attr_accessor :disabled
  attr_accessor :io

  log_level :trace
  log_level :debug
  log_level :info
  log_level :warn
  log_level :error

  def initialize(log_level = :debug, io = nil)
    self.log_level = log_level
    self.io = io
  end

  def logging_level?(level)
    !disabled && self.class.log_level?(level, log_level)
  end

  # Captures all logger messages emitted during a block and returns them as a
  # string.
  def capture
    old_io = io
    self.io = StringIO.new
    yield
    io.string
  ensure
    self.io = old_io
  end

  def log(level, message)
    _log(level, message) if logging_level?(level)
  end

  def _log(level, message)
    if io
      io.puts(message)
    else
      Kernel.warn(message)
    end
  end
end
