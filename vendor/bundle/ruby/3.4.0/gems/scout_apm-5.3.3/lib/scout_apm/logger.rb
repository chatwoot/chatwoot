# Pass in the "root" of the application you're using.
#   - Rails.root
#   - `Dir.pwd`
#
# Currently Valid opts:
# :force => Boolean                        - used to reinitialize logger.
# :log_file_path => String                 - explicitly set what file to send the log to
# :stdout => true                          - explicitly force the log to write to stdout (if set, ignore log_file_path)
# :stderr => true                          - explicitly force the log to write to stderr (if set, ignore log_file_path)
# :logger_class => Class or String         - a class to use as the underlying logger. Defaults to Ruby's Logger. See notes
# :log_level => symbol, string, or integer - defaults to INFO level
#
# The :logger_class option
#   - allows any class to be used as the underlying logger. Currently requires to respond to:
#     - debug, info, warn, error, fatal in both string and block form.
#     - debug?, info?, warn?, error?, fatal?
#     - #level= with a number (0 = debug, 1 = info, 2= warn, 3=error, 4=fatal)
#     - #formatter= that takes a Ruby Logger::Formatter class. This method must be here, but the value may be ignored
#
#config.value('log_level').downcase
#
module ScoutApm
  class Logger
    attr_reader :log_destination

    def initialize(environment_root, opts={})
      @opts = opts
      @environment_root = environment_root

      @log_destination = determine_log_destination
      @logger = build_logger
      self.log_level = log_level_from_opts
      @logger.formatter = build_formatter
    end

    # Delegate calls to the underlying logger
    def debug(*args, &block); @logger.debug(*args, &block); end
    def info(*args, &block); @logger.info(*args, &block); end
    def warn(*args, &block); @logger.warn(*args, &block); end
    def error(*args, &block); @logger.error(*args, &block); end
    def fatal(*args, &block); @logger.fatal(*args, &block); end

    def debug?; @logger.debug?; end
    def info?; @logger.info?; end
    def warn?; @logger.warn?; end
    def error?; @logger.error?; end
    def fatal?; @logger.fatal?; end

    def log_level=(level)
      @logger.level = log_level_from_opts(level)
    end

    def log_level
      @logger.level
    end

    def log_file_path
      @opts.fetch(:log_file_path, "#{@environment_root}/log") || "#{@environment_root}/log"
    end

    def stdout?
      @opts[:stdout] || (@opts[:log_file_path] || "").upcase == "STDOUT"
    end

    def stderr?
      @opts[:stderr] || (@opts[:log_file_path] || "").upcase == "STDERR"
    end

    private

    def build_logger
      logger_class.new(@log_destination)
    rescue => e
      logger = ::Logger.new(STDERR)
      logger.error("Error while building ScoutApm logger: #{e.message}. Falling back to STDERR")
      logger
    end

    def logger_class
      klass = @opts.fetch(:logger_class, ::Logger)
      case klass
      when String
        result = Utils::KlassHelper.lookup(klass)
        if result == :missing_class
          ::Logger
        else
          result
        end
      when Class
        klass
      else
        ::Logger
      end
    end

    def build_formatter
      if stdout? || stderr?
        TaggedFormatter.new
      else
        DefaultFormatter.new
      end
    end

    def log_level_from_opts(explicit=nil)
      candidate = explicit || (@opts[:log_level] || "").downcase

      case candidate
      when "debug" then ::Logger::DEBUG
      when "info" then ::Logger::INFO
      when "warn" then ::Logger::WARN
      when "error" then ::Logger::ERROR
      when "fatal" then ::Logger::FATAL
      when ::Logger::DEBUG, ::Logger::INFO, ::Logger::WARN, ::Logger::ERROR, ::Logger::FATAL then candidate
      else ::Logger::INFO
      end
    end

    def determine_log_destination
      case true
      when stdout?
        STDOUT
      when stderr?
        STDERR
      when validate_path(@opts[:log_file])
        @opts[:log_file]
      when validate_path("#{log_file_path}/scout_apm.log")
        "#{log_file_path}/scout_apm.log"
      else
        # Safe fallback
        STDOUT
      end
    end

    # Check if this path is ok for a log file.
    # Does it exist?
    # Is it writable?
    def validate_path(candidate)
      return false if candidate.nil?

      directory = File.dirname(candidate)
      File.writable?(directory)
    end

    class DefaultFormatter < ::Logger::Formatter
      def call(severity, time, progname, msg)
        # since STDOUT isn't exclusive like the scout_apm.log file, apply a prefix.
        # XXX: Pass in context to the formatter
        "[#{Utils::Time.to_s(time)} #{ScoutApm::Agent.instance.context.environment.hostname} (#{$$})] #{severity} : #{msg}\n"
      end
    end

    # since STDOUT & STDERR isn't only used for ScoutApm logging, apply a
    # prefix to make it easily greppable
    class TaggedFormatter < DefaultFormatter
      TAG = "[Scout] "

      def call(severity, time, progname, msg)
        TAG + super
      end
    end
  end
end
