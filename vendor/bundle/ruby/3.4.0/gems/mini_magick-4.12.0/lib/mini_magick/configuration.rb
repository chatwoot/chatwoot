require 'mini_magick/utilities'
require 'logger'

module MiniMagick
  module Configuration

    ##
    # If you don't have the CLI tools in your PATH, you can set the path to the
    # executables.
    #
    attr_writer :cli_path
    # @private (for backwards compatibility)
    attr_accessor :processor_path

    ##
    # Adds a prefix to the CLI command.
    # For example, you could use `firejail` to run all commands in a sandbox.
    # Can be a string, or an array of strings.
    # e.g. 'firejail', or ['firejail', '--force']
    #
    # @return [String]
    # @return [Array<String>]
    #
    attr_accessor :cli_prefix

    ##
    # If you don't want commands to take too long, you can set a timeout (in
    # seconds).
    #
    # @return [Integer]
    #
    attr_accessor :timeout
    ##
    # When get to `true`, it outputs each command to STDOUT in their shell
    # version.
    #
    # @return [Boolean]
    #
    attr_reader :debug
    ##
    # Logger for {#debug}, default is `MiniMagick::Logger.new(STDOUT)`, but
    # you can override it, for example if you want the logs to be written to
    # a file.
    #
    # @return [Logger]
    #
    attr_accessor :logger
    ##
    # Temporary directory used by MiniMagick, default is `Dir.tmpdir`, but
    # you can override it.
    #
    # @return [String]
    #
    attr_accessor :tmpdir

    ##
    # If set to `true`, it will `identify` every newly created image, and raise
    # `MiniMagick::Invalid` if the image is not valid. Useful for validating
    # user input, although it adds a bit of overhead. Defaults to `true`.
    #
    # @return [Boolean]
    #
    attr_accessor :validate_on_create
    ##
    # If set to `true`, it will `identify` every image that gets written (with
    # {MiniMagick::Image#write}), and raise `MiniMagick::Invalid` if the image
    # is not valid. Useful for validating that processing was sucessful,
    # although it adds a bit of overhead. Defaults to `true`.
    #
    # @return [Boolean]
    #
    attr_accessor :validate_on_write

    ##
    # If set to `false`, it will not raise errors when ImageMagick returns
    # status code different than 0. Defaults to `true`.
    #
    # @return [Boolean]
    #
    attr_accessor :whiny

    ##
    # Instructs MiniMagick how to execute the shell commands. Available
    # APIs are "open3" (default) and "posix-spawn" (requires the "posix-spawn"
    # gem).
    #
    # @return [String]
    #
    attr_accessor :shell_api

    def self.extended(base)
      base.tmpdir = Dir.tmpdir
      base.validate_on_create = true
      base.validate_on_write = true
      base.whiny = true
      base.shell_api = "open3"
      base.logger = Logger.new($stdout).tap { |l| l.level = Logger::INFO }
    end

    ##
    # @yield [self]
    # @example
    #   MiniMagick.configure do |config|
    #     config.cli = :graphicsmagick
    #     config.timeout = 5
    #   end
    #
    def configure
      yield self
    end

    CLI_DETECTION = {
      imagemagick7:   "magick",
      imagemagick:    "mogrify",
      graphicsmagick: "gm",
    }

    # @private (for backwards compatibility)
    def processor
      @processor ||= CLI_DETECTION.values.detect do |processor|
        MiniMagick::Utilities.which(processor)
      end
    end

    # @private (for backwards compatibility)
    def processor=(processor)
      @processor = processor.to_s

      unless CLI_DETECTION.value?(@processor)
        raise ArgumentError,
          "processor has to be set to either \"magick\", \"mogrify\" or \"gm\"" \
          ", was set to #{@processor.inspect}"
      end
    end

    ##
    # Get [ImageMagick](http://www.imagemagick.org) or
    # [GraphicsMagick](http://www.graphicsmagick.org).
    #
    # @return [Symbol] `:imagemagick` or `:graphicsmagick`
    #
    def cli
      if instance_variable_defined?("@cli")
        instance_variable_get("@cli")
      else
        cli = CLI_DETECTION.key(processor) or
          fail MiniMagick::Error, "You must have ImageMagick or GraphicsMagick installed"

        instance_variable_set("@cli", cli)
      end
    end

    ##
    # Set whether you want to use [ImageMagick](http://www.imagemagick.org) or
    # [GraphicsMagick](http://www.graphicsmagick.org).
    #
    def cli=(value)
      @cli = value

      if not CLI_DETECTION.key?(@cli)
        raise ArgumentError,
          "CLI has to be set to either :imagemagick, :imagemagick7 or :graphicsmagick" \
          ", was set to #{@cli.inspect}"
      end
    end

    ##
    # If you set the path of CLI tools, you can get the path of the
    # executables.
    #
    # @return [String]
    #
    def cli_path
      if instance_variable_defined?("@cli_path")
        instance_variable_get("@cli_path")
      else
        processor_path = instance_variable_get("@processor_path") if instance_variable_defined?("@processor_path")

        instance_variable_set("@cli_path", processor_path)
      end
    end

    ##
    # When set to `true`, it outputs each command to STDOUT in their shell
    # version.
    #
    def debug=(value)
      warn "MiniMagick.debug is deprecated and will be removed in MiniMagick 5. Use `MiniMagick.logger.level = Logger::DEBUG` instead."
      logger.level = value ? Logger::DEBUG : Logger::INFO
    end

    # Backwards compatibility
    def reload_tools
      warn "MiniMagick.reload_tools is deprecated because it is no longer necessary"
    end

  end
end
