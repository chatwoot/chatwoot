# frozen_string_literal: true

require 'optparse'
require_relative 'const'
require_relative 'detect'
require 'uri'
require 'socket'

module Puma
  class ControlCLI

    # values must be string or nil
    # value of `nil` means command cannot be processed via signal
    # @version 5.0.3
    CMD_PATH_SIG_MAP = {
      'gc'       => nil,
      'gc-stats' => nil,
      'halt'              => 'SIGQUIT',
      'info'              => 'SIGINFO',
      'phased-restart'    => 'SIGUSR1',
      'refork'            => 'SIGURG',
      'reload-worker-directory' => nil,
      'reopen-log'        => 'SIGHUP',
      'restart'           => 'SIGUSR2',
      'start'    => nil,
      'stats'    => nil,
      'status'   => '',
      'stop'              => 'SIGTERM',
      'thread-backtraces' => nil,
      'worker-count-down' => 'SIGTTOU',
      'worker-count-up'   => 'SIGTTIN'
    }.freeze

    # commands that cannot be used in a request
    NO_REQ_COMMANDS = %w[info reopen-log worker-count-down worker-count-up].freeze

    # @version 5.0.0
    PRINTABLE_COMMANDS = %w[gc-stats stats thread-backtraces].freeze

    def initialize(argv, stdout=STDOUT, stderr=STDERR)
      @state = nil
      @quiet = false
      @pidfile = nil
      @pid = nil
      @control_url = nil
      @control_auth_token = nil
      @config_file = nil
      @command = nil
      @environment = ENV['APP_ENV'] || ENV['RACK_ENV'] || ENV['RAILS_ENV']

      @argv = argv.dup
      @stdout = stdout
      @stderr = stderr
      @cli_options = {}

      opts = OptionParser.new do |o|
        o.banner = "Usage: pumactl (-p PID | -P pidfile | -S status_file | -C url -T token | -F config.rb) (#{CMD_PATH_SIG_MAP.keys.join("|")})"

        o.on "-S", "--state PATH", "Where the state file to use is" do |arg|
          @state = arg
        end

        o.on "-Q", "--quiet", "Not display messages" do |arg|
          @quiet = true
        end

        o.on "-P", "--pidfile PATH", "Pid file" do |arg|
          @pidfile = arg
        end

        o.on "-p", "--pid PID", "Pid" do |arg|
          @pid = arg.to_i
        end

        o.on "-C", "--control-url URL", "The bind url to use for the control server" do |arg|
          @control_url = arg
        end

        o.on "-T", "--control-token TOKEN", "The token to use as authentication for the control server" do |arg|
          @control_auth_token = arg
        end

        o.on "-F", "--config-file PATH", "Puma config script" do |arg|
          @config_file = arg
        end

        o.on "-e", "--environment ENVIRONMENT",
          "The environment to run the Rack app on (default development)" do |arg|
          @environment = arg
        end

        o.on_tail("-H", "--help", "Show this message") do
          @stdout.puts o
          exit
        end

        o.on_tail("-V", "--version", "Show version") do
          @stdout.puts Const::PUMA_VERSION
          exit
        end
      end

      opts.order!(argv) { |a| opts.terminate a }
      opts.parse!

      @command = argv.shift

      # check presence of command
      unless @command
        raise "Available commands: #{CMD_PATH_SIG_MAP.keys.join(", ")}"
      end

      unless CMD_PATH_SIG_MAP.key? @command
        raise "Invalid command: #{@command}"
      end

      unless @config_file == '-'
        environment = @environment || 'development'

        if @config_file.nil?
          @config_file = %W(config/puma/#{environment}.rb config/puma.rb).find do |f|
            File.exist?(f)
          end
        end

        if @config_file
          require_relative 'configuration'
          require_relative 'log_writer'

          config = Puma::Configuration.new({ config_files: [@config_file] }, {})
          config.load
          @state              ||= config.options[:state]
          @control_url        ||= config.options[:control_url]
          @control_auth_token ||= config.options[:control_auth_token]
          @pidfile            ||= config.options[:pidfile]
        end
      end
    rescue => e
      @stdout.puts e.message
      exit 1
    end

    def message(msg)
      @stdout.puts msg unless @quiet
    end

    def prepare_configuration
      if @state
        unless File.exist? @state
          raise "State file not found: #{@state}"
        end

        require_relative 'state_file'

        sf = Puma::StateFile.new
        sf.load @state

        @control_url = sf.control_url
        @control_auth_token = sf.control_auth_token
        @pid = sf.pid
      elsif @pidfile
        # get pid from pid_file
        @pid = File.read(@pidfile, mode: 'rb:UTF-8').to_i
      end
    end

    def send_request
      uri = URI.parse @control_url

      host = uri.host

      # create server object by scheme
      server =
        case uri.scheme
        when 'ssl'
          require 'openssl'
          host = host[1..-2] if host&.start_with? '['
          OpenSSL::SSL::SSLSocket.new(
            TCPSocket.new(host, uri.port),
            OpenSSL::SSL::SSLContext.new)
            .tap { |ssl| ssl.sync_close = true }  # default is false
            .tap(&:connect)
        when 'tcp'
          host = host[1..-2] if host&.start_with? '['
          TCPSocket.new host, uri.port
        when 'unix'
          # check for abstract UNIXSocket
          UNIXSocket.new(@control_url.start_with?('unix://@') ?
            "\0#{host}#{uri.path}" : "#{host}#{uri.path}")
        else
          raise "Invalid scheme: #{uri.scheme}"
        end

      if @command == 'status'
        message 'Puma is started'
      else
        url = "/#{@command}"

        if @control_auth_token
          url = url + "?token=#{@control_auth_token}"
        end

        server.syswrite "GET #{url} HTTP/1.0\r\n\r\n"

        unless data = server.read
          raise 'Server closed connection before responding'
        end

        response = data.split("\r\n")

        if response.empty?
          raise "Server sent empty response"
        end

        @http, @code, @message = response.first.split(' ',3)

        if @code == '403'
          raise 'Unauthorized access to server (wrong auth token)'
        elsif @code == '404'
          raise "Command error: #{response.last}"
        elsif @code != '200'
          raise "Bad response from server: #{@code}"
        end

        message "Command #{@command} sent success"
        message response.last if PRINTABLE_COMMANDS.include?(@command)
      end
    ensure
      if server
        if uri.scheme == 'ssl'
          server.sysclose
        else
          server.close unless server.closed?
        end
      end
    end

    def send_signal
      unless @pid
        raise 'Neither pid nor control url available'
      end

      begin
        sig = CMD_PATH_SIG_MAP[@command]

        if sig.nil?
          @stdout.puts "'#{@command}' not available via pid only"
          @stdout.flush unless @stdout.sync
          return
        elsif sig.start_with? 'SIG'
          if Signal.list.key? sig.sub(/\ASIG/, '')
            Process.kill sig, @pid
          else
            raise "Signal '#{sig}' not available'"
          end
        elsif @command == 'status'
          begin
            Process.kill 0, @pid
            @stdout.puts 'Puma is started'
            @stdout.flush unless @stdout.sync
          rescue Errno::ESRCH
            raise 'Puma is not running'
          end
          return
        end
      rescue SystemCallError
        if @command == 'restart'
          start
        else
          raise "No pid '#{@pid}' found"
        end
      end

      message "Command #{@command} sent success"
    end

    def run
      return start if @command == 'start'
      prepare_configuration

      if Puma.windows? || @control_url && !NO_REQ_COMMANDS.include?(@command)
        send_request
      else
        send_signal
      end

    rescue => e
      message e.message
      exit 1
    end

    private
    def start
      require_relative 'cli'

      run_args = []

      run_args += ["-S", @state]  if @state
      run_args += ["-q"] if @quiet
      run_args += ["--pidfile", @pidfile] if @pidfile
      run_args += ["--control-url", @control_url] if @control_url
      run_args += ["--control-token", @control_auth_token] if @control_auth_token
      run_args += ["-C", @config_file] if @config_file
      run_args += ["-e", @environment] if @environment

      log_writer = Puma::LogWriter.new(@stdout, @stderr)

      # replace $0 because puma use it to generate restart command
      puma_cmd = $0.gsub(/pumactl$/, 'puma')
      $0 = puma_cmd if File.exist?(puma_cmd)

      cli = Puma::CLI.new run_args, log_writer
      cli.run
    end
  end
end
