# frozen_string_literal: true

module Byebug
  #
  # Handles byebug's command line options
  #
  class OptionSetter
    def initialize(runner, opts)
      @runner = runner
      @opts = opts
    end

    def setup
      debug
      include_flag
      post_mortem
      quit
      rc
      stop
      require_flag
      remote
      trace
      version
      help
    end

    private

    def debug
      @opts.on "-d", "--debug", "Set $DEBUG=true" do
        $DEBUG = true
      end
    end

    def include_flag
      @opts.on "-I", "--include list", "Add to paths to $LOAD_PATH" do |list|
        $LOAD_PATH.push(list.split(":")).flatten!
      end
    end

    def post_mortem
      @opts.on "-m", "--[no-]post-mortem", "Use post-mortem mode" do |v|
        Setting[:post_mortem] = v
      end
    end

    def quit
      @opts.on "-q", "--[no-]quit", "Quit when script finishes" do |v|
        @runner.quit = v
      end
    end

    def rc
      @opts.on "-x", "--[no-]rc", "Run byebug initialization file" do |v|
        @runner.init_script = v
      end
    end

    def stop
      @opts.on "-s", "--[no-]stop", "Stop when script is loaded" do |v|
        @runner.stop = v
      end
    end

    def require_flag
      @opts.on "-r", "--require file", "Require library before script" do |lib|
        require lib
      end
    end

    def remote
      @opts.on "-R", "--remote [host:]port", "Remote debug [host:]port" do |p|
        @runner.remote = p
      end
    end

    def trace
      @opts.on "-t", "--[no-]trace", "Turn on line tracing" do |v|
        Setting[:linetrace] = v
      end
    end

    def version
      @opts.on "-v", "--version", "Print program version" do
        @runner.version = Byebug::VERSION
      end
    end

    def help
      @opts.on "-h", "--help", "Display this message" do
        @runner.help = @opts.help
      end
    end
  end
end
