require 'childprocess/version'
require 'childprocess/errors'
require 'childprocess/abstract_process'
require 'childprocess/abstract_io'
require 'childprocess/process_spawn_process'
require "fcntl"
require 'logger'

module ChildProcess

  @posix_spawn = false

  class << self
    attr_writer :logger

    def new(*args)
      case os
      when :macosx, :linux, :solaris, :bsd, :cygwin, :aix
        Unix::Process.new(*args)
      when :windows
        Windows::Process.new(*args)
      else
        raise Error, "unsupported platform #{platform_name.inspect}"
      end
    end
    alias_method :build, :new

    def logger
      return @logger if defined?(@logger) and @logger

      @logger = Logger.new($stderr)
      @logger.level = $DEBUG ? Logger::DEBUG : Logger::INFO

      @logger
    end

    def platform
      os
    end

    def platform_name
      @platform_name ||= "#{arch}-#{os}"
    end

    def unix?
      !windows?
    end

    def linux?
      os == :linux
    end

    def jruby?
      RUBY_ENGINE == 'jruby'
    end

    def windows?
      os == :windows
    end

    def posix_spawn_chosen_explicitly?
      @posix_spawn || %w[1 true].include?(ENV['CHILDPROCESS_POSIX_SPAWN'])
    end

    def posix_spawn?
      false
    end

    #
    # Set this to true to enable experimental use of posix_spawn.
    #

    def posix_spawn=(bool)
      @posix_spawn = bool
    end

    def os
      return :windows if ENV['FAKE_WINDOWS'] == 'true'

      @os ||= (
        require "rbconfig"
        host_os = RbConfig::CONFIG['host_os'].downcase

        case host_os
        when /linux/
          :linux
        when /darwin|mac os/
          :macosx
        when /mswin|msys|mingw32/
          :windows
        when /cygwin/
          :cygwin
        when /solaris|sunos/
          :solaris
        when /bsd|dragonfly/
          :bsd
        when /aix/
          :aix
        else
          raise Error, "unknown os: #{host_os.inspect}"
        end
      )
    end

    def arch
      @arch ||= (
        host_cpu = RbConfig::CONFIG['host_cpu'].downcase
        case host_cpu
        when /i[3456]86/
          if workaround_older_macosx_misreported_cpu?
            # Workaround case: older 64-bit Darwin Rubies misreported as i686
            "x86_64"
          else
            "i386"
          end
        when /amd64|x86_64/
          "x86_64"
        when /ppc|powerpc/
          "powerpc"
        else
          host_cpu
        end
      )
    end

    #
    # By default, a child process will inherit open file descriptors from the
    # parent process. This helper provides a cross-platform way of making sure
    # that doesn't happen for the given file/io.
    #

    def close_on_exec(file)
      if file.respond_to?(:close_on_exec=)
        file.close_on_exec = true
      else
        raise Error, "not sure how to set close-on-exec for #{file.inspect} on #{platform_name.inspect}"
      end
    end

    private

    def warn_once(msg)
      @warnings ||= {}

      unless @warnings[msg]
        @warnings[msg] = true
        logger.warn msg
      end
    end

    # Workaround: detect the situation that an older Darwin Ruby is actually
    # 64-bit, but is misreporting cpu as i686, which would imply 32-bit.
    #
    # @return [Boolean] `true` if:
    #   (a) on Mac OS X
    #   (b) actually running in 64-bit mode
    def workaround_older_macosx_misreported_cpu?
      os == :macosx && is_64_bit?
    end

    # @return [Boolean] `true` if this Ruby represents `1` in 64 bits (8 bytes).
    def is_64_bit?
      1.size == 8
    end

  end # class << self
end # ChildProcess

if ChildProcess.windows?
  require 'childprocess/windows'
else
  require 'childprocess/unix'
end
