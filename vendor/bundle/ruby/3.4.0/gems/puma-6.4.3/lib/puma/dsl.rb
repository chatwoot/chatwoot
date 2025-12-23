# frozen_string_literal: true

require_relative 'const'
require_relative 'util'

module Puma
  # The methods that are available for use inside the configuration file.
  # These same methods are used in Puma cli and the rack handler
  # internally.
  #
  # Used manually (via CLI class):
  #
  #   config = Configuration.new({}) do |user_config|
  #     user_config.port 3001
  #   end
  #   config.load
  #
  #   puts config.options[:binds] # => "tcp://127.0.0.1:3001"
  #
  # Used to load file:
  #
  #   $ cat puma_config.rb
  #   port 3002
  #
  # Resulting configuration:
  #
  #   config = Configuration.new(config_file: "puma_config.rb")
  #   config.load
  #
  #   puts config.options[:binds] # => "tcp://127.0.0.1:3002"
  #
  # You can also find many examples being used by the test suite in
  # +test/config+.
  #
  # Puma v6 adds the option to specify a key name (String or Symbol) to the
  # hooks that run inside the forked workers.  All the hooks run inside the
  # {Puma::Cluster::Worker#run} method.
  #
  # Previously, the worker index and the LogWriter instance were passed to the
  # hook blocks/procs.  If a key name is specified, a hash is passed as the last
  # parameter.  This allows storage of data, typically objects that are created
  # before the worker that need to be passed to the hook when the worker is shutdown.
  #
  # The following hooks have been updated:
  #
  #     | DSL Method         |  Options Key            | Fork Block Location |
  #     | on_worker_boot     | :before_worker_boot     | inside, before      |
  #     | on_worker_shutdown | :before_worker_shutdown | inside, after       |
  #     | on_refork          | :before_refork          | inside              |
  #
  class DSL
    ON_WORKER_KEY = [String, Symbol].freeze

    # convenience method so logic can be used in CI
    # @see ssl_bind
    #
    def self.ssl_bind_str(host, port, opts)
      verify = opts.fetch(:verify_mode, 'none').to_s

      tls_str =
        if opts[:no_tlsv1_1]  then '&no_tlsv1_1=true'
        elsif opts[:no_tlsv1] then '&no_tlsv1=true'
        else ''
        end

      ca_additions = "&ca=#{Puma::Util.escape(opts[:ca])}" if ['peer', 'force_peer'].include?(verify)

      low_latency_str = opts.key?(:low_latency) ? "&low_latency=#{opts[:low_latency]}" : ''
      backlog_str = opts[:backlog] ? "&backlog=#{Integer(opts[:backlog])}" : ''

      if defined?(JRUBY_VERSION)
        cipher_suites = opts[:ssl_cipher_list] ? "&ssl_cipher_list=#{opts[:ssl_cipher_list]}" : nil # old name
        cipher_suites = "#{cipher_suites}&cipher_suites=#{opts[:cipher_suites]}" if opts[:cipher_suites]
        protocols = opts[:protocols] ? "&protocols=#{opts[:protocols]}" : nil

        keystore_additions = "keystore=#{opts[:keystore]}&keystore-pass=#{opts[:keystore_pass]}"
        keystore_additions = "#{keystore_additions}&keystore-type=#{opts[:keystore_type]}" if opts[:keystore_type]
        if opts[:truststore]
          truststore_additions = "&truststore=#{opts[:truststore]}"
          truststore_additions = "#{truststore_additions}&truststore-pass=#{opts[:truststore_pass]}" if opts[:truststore_pass]
          truststore_additions = "#{truststore_additions}&truststore-type=#{opts[:truststore_type]}" if opts[:truststore_type]
        end

        "ssl://#{host}:#{port}?#{keystore_additions}#{truststore_additions}#{cipher_suites}#{protocols}" \
          "&verify_mode=#{verify}#{tls_str}#{ca_additions}#{backlog_str}"
      else
        ssl_cipher_filter = opts[:ssl_cipher_filter] ? "&ssl_cipher_filter=#{opts[:ssl_cipher_filter]}" : nil
        v_flags = (ary = opts[:verification_flags]) ? "&verification_flags=#{Array(ary).join ','}" : nil

        cert_flags = (cert = opts[:cert]) ? "cert=#{Puma::Util.escape(cert)}" : nil
        key_flags = (key = opts[:key]) ? "&key=#{Puma::Util.escape(key)}" : nil
        password_flags = (password_command = opts[:key_password_command]) ? "&key_password_command=#{Puma::Util.escape(password_command)}" : nil

        reuse_flag =
          if (reuse = opts[:reuse])
            if reuse == true
              '&reuse=dflt'
            elsif reuse.is_a?(Hash) && (reuse.key?(:size) || reuse.key?(:timeout))
              val = +''
              if (size = reuse[:size]) && Integer === size
                val << size.to_s
              end
              if (timeout = reuse[:timeout]) && Integer === timeout
                val << ",#{timeout}"
              end
              if val.empty?
                nil
              else
                "&reuse=#{val}"
              end
            else
              nil
            end
          else
            nil
          end

        "ssl://#{host}:#{port}?#{cert_flags}#{key_flags}#{password_flags}#{ssl_cipher_filter}" \
          "#{reuse_flag}&verify_mode=#{verify}#{tls_str}#{ca_additions}#{v_flags}#{backlog_str}#{low_latency_str}"
      end
    end

    def initialize(options, config)
      @config  = config
      @options = options

      @plugins = []
    end

    def _load_from(path)
      if path
        @path = path
        instance_eval(File.read(path), path, 1)
      end
    ensure
      _offer_plugins
    end

    def _offer_plugins
      @plugins.each do |o|
        if o.respond_to? :config
          @options.shift
          o.config self
        end
      end

      @plugins.clear
    end

    def set_default_host(host)
      @options[:default_host] = host
    end

    def default_host
      @options[:default_host] || Configuration::DEFAULTS[:tcp_host]
    end

    def inject(&blk)
      instance_eval(&blk)
    end

    def get(key,default=nil)
      @options[key.to_sym] || default
    end

    # Load the named plugin for use by this configuration
    #
    def plugin(name)
      @plugins << @config.load_plugin(name)
    end

    # Use an object or block as the rack application. This allows the
    # configuration file to be the application itself.
    #
    # @example
    #   app do |env|
    #     body = 'Hello, World!'
    #
    #     [
    #       200,
    #       {
    #         'Content-Type' => 'text/plain',
    #         'Content-Length' => body.length.to_s
    #       },
    #       [body]
    #     ]
    #   end
    #
    # @see Puma::Configuration#app
    #
    def app(obj=nil, &block)
      obj ||= block

      raise "Provide either a #call'able or a block" unless obj

      @options[:app] = obj
    end

    # Start the Puma control rack application on +url+. This application can
    # be communicated with to control the main server. Additionally, you can
    # provide an authentication token, so all requests to the control server
    # will need to include that token as a query parameter. This allows for
    # simple authentication.
    #
    # Check out {Puma::App::Status} to see what the app has available.
    #
    # @example
    #   activate_control_app 'unix:///var/run/pumactl.sock'
    # @example
    #   activate_control_app 'unix:///var/run/pumactl.sock', { auth_token: '12345' }
    # @example
    #   activate_control_app 'unix:///var/run/pumactl.sock', { no_token: true }
    def activate_control_app(url="auto", opts={})
      if url == "auto"
        path = Configuration.temp_path
        @options[:control_url] = "unix://#{path}"
        @options[:control_url_temp] = path
      else
        @options[:control_url] = url
      end

      if opts[:no_token]
        # We need to use 'none' rather than :none because this value will be
        # passed on to an instance of OptionParser, which doesn't support
        # symbols as option values.
        #
        # See: https://github.com/puma/puma/issues/1193#issuecomment-305995488
        auth_token = 'none'
      else
        auth_token = opts[:auth_token]
        auth_token ||= Configuration.random_token
      end

      @options[:control_auth_token] = auth_token
      @options[:control_url_umask] = opts[:umask] if opts[:umask]
    end

    # Load additional configuration from a file
    # Files get loaded later via Configuration#load
    def load(file)
      @options[:config_files] ||= []
      @options[:config_files] << file
    end

    # Bind the server to +url+. "tcp://", "unix://" and "ssl://" are the only
    # accepted protocols. Multiple urls can be bound to, calling +bind+ does
    # not overwrite previous bindings.
    #
    # The default is "tcp://0.0.0.0:9292".
    #
    # You can use query parameters within the url to specify options:
    #
    # * Set the socket backlog depth with +backlog+, default is 1024.
    # * Set up an SSL certificate with +key+ & +cert+.
    # * Set up an SSL certificate for mTLS with +key+, +cert+, +ca+ and +verify_mode+.
    # * Set whether to optimize for low latency instead of throughput with
    #   +low_latency+, default is to not optimize for low latency. This is done
    #   via +Socket::TCP_NODELAY+.
    # * Set socket permissions with +umask+.
    #
    # @example Backlog depth
    #   bind 'unix:///var/run/puma.sock?backlog=512'
    # @example SSL cert
    #   bind 'ssl://127.0.0.1:9292?key=key.key&cert=cert.pem'
    # @example SSL cert for mutual TLS (mTLS)
    #   bind 'ssl://127.0.0.1:9292?key=key.key&cert=cert.pem&ca=ca.pem&verify_mode=force_peer'
    # @example Disable optimization for low latency
    #   bind 'tcp://0.0.0.0:9292?low_latency=false'
    # @example Socket permissions
    #   bind 'unix:///var/run/puma.sock?umask=0111'
    # @see Puma::Runner#load_and_bind
    # @see Puma::Cluster#run
    #
    def bind(url)
      @options[:binds] ||= []
      @options[:binds] << url
    end

    def clear_binds!
      @options[:binds] = []
    end

    # Bind to (systemd) activated sockets, regardless of configured binds.
    #
    # Systemd can present sockets as file descriptors that are already opened.
    # By default Puma will use these but only if it was explicitly told to bind
    # to the socket. If not, it will close the activated sockets. This means
    # all configuration is duplicated.
    #
    # Binds can contain additional configuration, but only SSL config is really
    # relevant since the unix and TCP socket options are ignored.
    #
    # This means there is a lot of duplicated configuration for no additional
    # value in most setups. This method tells the launcher to bind to all
    # activated sockets, regardless of existing bind.
    #
    # To clear configured binds, the value only can be passed. This will clear
    # out any binds that may have been configured.
    #
    # @example Use any systemd activated sockets as well as configured binds
    #   bind_to_activated_sockets
    #
    # @example Only bind to systemd activated sockets, ignoring other binds
    #   bind_to_activated_sockets 'only'
    def bind_to_activated_sockets(bind=true)
      @options[:bind_to_activated_sockets] = bind
    end

    # Define the TCP port to bind to. Use +bind+ for more advanced options.
    #
    # @example
    #   port 9292
    def port(port, host=nil)
      host ||= default_host
      bind URI::Generic.build(scheme: 'tcp', host: host, port: Integer(port)).to_s
    end

    # Define how long the tcp socket stays open, if no data has been received.
    # @see Puma::Server.new
    def first_data_timeout(seconds)
      @options[:first_data_timeout] = Integer(seconds)
    end

    # Define how long persistent connections can be idle before Puma closes them.
    # @see Puma::Server.new
    def persistent_timeout(seconds)
      @options[:persistent_timeout] = Integer(seconds)
    end

    # If a new request is not received within this number of seconds, begin shutting down.
    # @see Puma::Server.new
    def idle_timeout(seconds)
      @options[:idle_timeout] = Integer(seconds)
    end

    # Work around leaky apps that leave garbage in Thread locals
    # across requests.
    def clean_thread_locals(which=true)
      @options[:clean_thread_locals] = which
    end

    # When shutting down, drain the accept socket of pending connections and
    # process them. This loops over the accept socket until there are no more
    # read events and then stops looking and waits for the requests to finish.
    # @see Puma::Server#graceful_shutdown
    #
    def drain_on_shutdown(which=true)
      @options[:drain_on_shutdown] = which
    end

    # Set the environment in which the rack's app will run. The value must be
    # a string.
    #
    # The default is "development".
    #
    # @example
    #   environment 'production'
    def environment(environment)
      @options[:environment] = environment
    end

    # How long to wait for threads to stop when shutting them
    # down. Defaults to :forever. Specifying :immediately will cause
    # Puma to kill the threads immediately.  Otherwise the value
    # is the number of seconds to wait.
    #
    # Puma always waits a few seconds after killing a thread for it to try
    # to finish up it's work, even in :immediately mode.
    # @see Puma::Server#graceful_shutdown
    def force_shutdown_after(val=:forever)
      i = case val
          when :forever
            -1
          when :immediately
            0
          else
            Float(val)
          end

      @options[:force_shutdown_after] = i
    end

    # Code to run before doing a restart. This code should
    # close log files, database connections, etc.
    #
    # This can be called multiple times to add code each time.
    #
    # @example
    #   on_restart do
    #     puts 'On restart...'
    #   end
    def on_restart(&block)
      @options[:on_restart] ||= []
      @options[:on_restart] << block
    end

    # Command to use to restart Puma. This should be just how to
    # load Puma itself (ie. 'ruby -Ilib bin/puma'), not the arguments
    # to Puma, as those are the same as the original process.
    #
    # @example
    #   restart_command '/u/app/lolcat/bin/restart_puma'
    def restart_command(cmd)
      @options[:restart_cmd] = cmd.to_s
    end

    # Store the pid of the server in the file at "path".
    #
    # @example
    #   pidfile '/u/apps/lolcat/tmp/pids/puma.pid'
    def pidfile(path)
      @options[:pidfile] = path.to_s
    end

    # Disable request logging, if this isn't used it'll be enabled by default.
    #
    # @example
    #   quiet
    def quiet(which=true)
      @options[:log_requests] = !which
    end

    # Enable request logging
    #
    def log_requests(which=true)
      @options[:log_requests] = which
    end

    # Pass in a custom logging class instance
    def custom_logger(custom_logger)
      @options[:custom_logger] = custom_logger
    end

    # Show debugging info
    #
    def debug
      @options[:debug] = true
    end

    # Load +path+ as a rackup file.
    #
    # The default is "config.ru".
    #
    # @example
    #   rackup '/u/apps/lolcat/config.ru'
    def rackup(path)
      @options[:rackup] ||= path.to_s
    end

    # Allows setting `env['rack.url_scheme']`.
    # Only necessary if X-Forwarded-Proto is not being set by your proxy
    # Normal values are 'http' or 'https'.
    def rack_url_scheme(scheme=nil)
      @options[:rack_url_scheme] = scheme
    end

    def early_hints(answer=true)
      @options[:early_hints] = answer
    end

    # Redirect +STDOUT+ and +STDERR+ to files specified. The +append+ parameter
    # specifies whether the output is appended, the default is +false+.
    #
    # @example
    #   stdout_redirect '/app/lolcat/log/stdout', '/app/lolcat/log/stderr'
    # @example
    #   stdout_redirect '/app/lolcat/log/stdout', '/app/lolcat/log/stderr', true
    def stdout_redirect(stdout=nil, stderr=nil, append=false)
      @options[:redirect_stdout] = stdout
      @options[:redirect_stderr] = stderr
      @options[:redirect_append] = append
    end

    def log_formatter(&block)
      @options[:log_formatter] = block
    end

    # Configure +min+ to be the minimum number of threads to use to answer
    # requests and +max+ the maximum.
    #
    # The default is the environment variables +PUMA_MIN_THREADS+ / +PUMA_MAX_THREADS+
    # (or +MIN_THREADS+ / +MAX_THREADS+ if the +PUMA_+ variables aren't set).
    #
    # If these environment variables aren't set, the default is "0, 5" in MRI or "0, 16" for other interpreters.
    #
    # @example
    #   threads 0, 16
    # @example
    #   threads 5, 5
    def threads(min, max)
      min = Integer(min)
      max = Integer(max)
      if min > max
        raise "The minimum (#{min}) number of threads must be less than or equal to the max (#{max})"
      end

      if max < 1
        raise "The maximum number of threads (#{max}) must be greater than 0"
      end

      @options[:min_threads] = min
      @options[:max_threads] = max
    end

    # Instead of using +bind+ and manually constructing a URI like:
    #
    #    bind 'ssl://127.0.0.1:9292?key=key_path&cert=cert_path'
    #
    # you can use the this method.
    #
    # When binding on localhost you don't need to specify +cert+ and +key+,
    # Puma will assume you are using the +localhost+ gem and try to load the
    # appropriate files.
    #
    # When using the options hash parameter, the `reuse:` value is either
    # `true`, which sets reuse 'on' with default values, or a hash, with `:size`
    # and/or `:timeout` keys, each with integer values.
    #
    # The `cert:` options hash parameter can be the path to a certificate
    # file including all intermediate certificates in PEM format.
    #
    # The `cert_pem:` options hash parameter can be String containing the
    # cerificate and all intermediate certificates in PEM format.
    #
    # @example
    #   ssl_bind '127.0.0.1', '9292', {
    #     cert: path_to_cert,
    #     key: path_to_key,
    #     ssl_cipher_filter: cipher_filter, # optional
    #     verify_mode: verify_mode,         # default 'none'
    #     verification_flags: flags,        # optional, not supported by JRuby
    #     reuse: true                       # optional
    #   }
    #
    # @example Using self-signed certificate with the +localhost+ gem:
    #   ssl_bind '127.0.0.1', '9292'
    #
    # @example Alternatively, you can provide +cert_pem+ and +key_pem+:
    #   ssl_bind '127.0.0.1', '9292', {
    #     cert_pem: File.read(path_to_cert),
    #     key_pem: File.read(path_to_key),
    #     reuse: {size: 2_000, timeout: 20} # optional
    #   }
    #
    # @example For JRuby, two keys are required: +keystore+ & +keystore_pass+
    #   ssl_bind '127.0.0.1', '9292', {
    #     keystore: path_to_keystore,
    #     keystore_pass: password,
    #     ssl_cipher_list: cipher_list,     # optional
    #     verify_mode: verify_mode          # default 'none'
    #   }
    def ssl_bind(host, port, opts = {})
      add_pem_values_to_options_store(opts)
      bind self.class.ssl_bind_str(host, port, opts)
    end

    # Use +path+ as the file to store the server info state. This is
    # used by +pumactl+ to query and control the server.
    #
    # @example
    #   state_path '/u/apps/lolcat/tmp/pids/puma.state'
    def state_path(path)
      @options[:state] = path.to_s
    end

    # Use +permission+ to restrict permissions for the state file.
    #
    # @example
    #   state_permission 0600
    # @version 5.0.0
    #
    def state_permission(permission)
      @options[:state_permission] = permission
    end

    # How many worker processes to run.  Typically this is set to
    # the number of available cores.
    #
    # The default is the value of the environment variable +WEB_CONCURRENCY+ if
    # set, otherwise 0.
    #
    # @note Cluster mode only.
    # @see Puma::Cluster
    def workers(count)
      @options[:workers] = count.to_i
    end

    # Disable warning message when running in cluster mode with a single worker.
    #
    # Cluster mode has some overhead of running an additional 'control' process
    # in order to manage the cluster. If only running a single worker it is
    # likely not worth paying that overhead vs running in single mode with
    # additional threads instead.
    #
    # There are some scenarios where running cluster mode with a single worker
    # may still be warranted and valid under certain deployment scenarios, see
    # https://github.com/puma/puma/issues/2534
    #
    # Moving from workers = 1 to workers = 0 will save 10-30% of memory use.
    #
    # @note Cluster mode only.
    def silence_single_worker_warning
      @options[:silence_single_worker_warning] = true
    end

    # Disable warning message when running single mode with callback hook defined.
    def silence_fork_callback_warning
      @options[:silence_fork_callback_warning] = true
    end

    # Code to run immediately before master process
    # forks workers (once on boot). These hooks can block if necessary
    # to wait for background operations unknown to Puma to finish before
    # the process terminates.
    # This can be used to close any connections to remote servers (database,
    # Redis, ...) that were opened when preloading the code.
    #
    # This can be called multiple times to add several hooks.
    #
    # @note Cluster mode only.
    # @example
    #   before_fork do
    #     puts "Starting workers..."
    #   end
    def before_fork(&block)
      warn_if_in_single_mode('before_fork')

      @options[:before_fork] ||= []
      @options[:before_fork] << block
    end

    # Code to run in a worker when it boots to setup
    # the process before booting the app.
    #
    # This can be called multiple times to add several hooks.
    #
    # @note Cluster mode only.
    # @example
    #   on_worker_boot do
    #     puts 'Before worker boot...'
    #   end
    def on_worker_boot(key = nil, &block)
      warn_if_in_single_mode('on_worker_boot')

      process_hook :before_worker_boot, key, block, 'on_worker_boot'
    end

    # Code to run immediately before a worker shuts
    # down (after it has finished processing HTTP requests). These hooks
    # can block if necessary to wait for background operations unknown
    # to Puma to finish before the process terminates.
    #
    # This can be called multiple times to add several hooks.
    #
    # @note Cluster mode only.
    # @example
    #   on_worker_shutdown do
    #     puts 'On worker shutdown...'
    #   end
    def on_worker_shutdown(key = nil, &block)
      warn_if_in_single_mode('on_worker_shutdown')

      process_hook :before_worker_shutdown, key, block, 'on_worker_shutdown'
    end

    # Code to run in the master right before a worker is started. The worker's
    # index is passed as an argument.
    #
    # This can be called multiple times to add several hooks.
    #
    # @note Cluster mode only.
    # @example
    #   on_worker_fork do
    #     puts 'Before worker fork...'
    #   end
    def on_worker_fork(&block)
      warn_if_in_single_mode('on_worker_fork')

      process_hook :before_worker_fork, nil, block, 'on_worker_fork'
    end

    # Code to run in the master after a worker has been started. The worker's
    # index is passed as an argument.
    #
    # This is called everytime a worker is to be started.
    #
    # @note Cluster mode only.
    # @example
    #   after_worker_fork do
    #     puts 'After worker fork...'
    #   end
    def after_worker_fork(&block)
      warn_if_in_single_mode('after_worker_fork')

      process_hook :after_worker_fork, nil, block, 'after_worker_fork'
    end

    alias_method :after_worker_boot, :after_worker_fork

    # Code to run after puma is booted (works for both: single and clustered)
    #
    # @example
    #   on_booted do
    #     puts 'After booting...'
    #   end
    def on_booted(&block)
      @config.options[:events].on_booted(&block)
    end

    # When `fork_worker` is enabled, code to run in Worker 0
    # before all other workers are re-forked from this process,
    # after the server has temporarily stopped serving requests
    # (once per complete refork cycle).
    #
    # This can be used to trigger extra garbage-collection to maximize
    # copy-on-write efficiency, or close any connections to remote servers
    # (database, Redis, ...) that were opened while the server was running.
    #
    # This can be called multiple times to add several hooks.
    #
    # @note Cluster mode with `fork_worker` enabled only.
    # @example
    #   on_refork do
    #     3.times {GC.start}
    #   end
    # @version 5.0.0
    #
    def on_refork(key = nil, &block)
      process_hook :before_refork, key, block, 'on_refork'
    end

    # Provide a block to be executed just before a thread is added to the thread
    # pool. Be careful: while the block executes, thread creation is delayed, and
    # probably a request will have to wait too! The new thread will not be added to
    # the threadpool until the provided block returns.
    #
    # Return values are ignored.
    # Raising an exception will log a warning.
    #
    # This hook is useful for doing something when the thread pool grows.
    #
    # This can be called multiple times to add several hooks.
    #
    # @example
    #   on_thread_start do
    #     puts 'On thread start...'
    #   end
    def on_thread_start(&block)
      @options[:before_thread_start] ||= []
      @options[:before_thread_start] << block
    end

    # Provide a block to be executed after a thread is trimmed from the thread
    # pool. Be careful: while this block executes, Puma's main loop is
    # blocked, so no new requests will be picked up.
    #
    # This hook only runs when a thread in the threadpool is trimmed by Puma.
    # It does not run when a thread dies due to exceptions or any other cause.
    #
    # Return values are ignored.
    # Raising an exception will log a warning.
    #
    # This hook is useful for cleaning up thread local resources when a thread
    # is trimmed.
    #
    # This can be called multiple times to add several hooks.
    #
    # @example
    #   on_thread_exit do
    #     puts 'On thread exit...'
    #   end
    def on_thread_exit(&block)
      @options[:before_thread_exit] ||= []
      @options[:before_thread_exit] << block
    end

    # Code to run out-of-band when the worker is idle.
    # These hooks run immediately after a request has finished
    # processing and there are no busy threads on the worker.
    # The worker doesn't accept new requests until this code finishes.
    #
    # This hook is useful for running out-of-band garbage collection
    # or scheduling asynchronous tasks to execute after a response.
    #
    # This can be called multiple times to add several hooks.
    def out_of_band(&block)
      process_hook :out_of_band, nil, block, 'out_of_band'
    end

    # The directory to operate out of.
    #
    # The default is the current directory.
    #
    # @example
    #   directory '/u/apps/lolcat'
    def directory(dir)
      @options[:directory] = dir.to_s
    end

    # Preload the application before starting the workers; this conflicts with
    # phased restart feature. On by default if your app uses more than 1 worker.
    #
    # @note Cluster mode only.
    # @example
    #   preload_app!
    def preload_app!(answer=true)
      @options[:preload_app] = answer
    end

    # Use +obj+ or +block+ as the low level error handler. This allows the
    # configuration file to change the default error on the server.
    #
    # @example
    #   lowlevel_error_handler do |err|
    #     [200, {}, ["error page"]]
    #   end
    def lowlevel_error_handler(obj=nil, &block)
      obj ||= block
      raise "Provide either a #call'able or a block" unless obj
      @options[:lowlevel_error_handler] = obj
    end

    # This option is used to allow your app and its gems to be
    # properly reloaded when not using preload.
    #
    # When set, if Puma detects that it's been invoked in the
    # context of Bundler, it will cleanup the environment and
    # re-run itself outside the Bundler environment, but directly
    # using the files that Bundler has setup.
    #
    # This means that Puma is now decoupled from your Bundler
    # context and when each worker loads, it will be loading a
    # new Bundler context and thus can float around as the release
    # dictates.
    #
    # @see extra_runtime_dependencies
    #
    # @note This is incompatible with +preload_app!+.
    # @note This is only supported for RubyGems 2.2+
    def prune_bundler(answer=true)
      @options[:prune_bundler] = answer
    end

    # By default, Puma will raise SignalException when SIGTERM is received. In
    # environments where SIGTERM is something expected, you can suppress these
    # with this option.
    #
    # This can be useful for example in Kubernetes, where rolling restart is
    # guaranteed usually on infrastructure level.
    #
    # @example
    #   raise_exception_on_sigterm false
    # @see Puma::Launcher#setup_signals
    # @see Puma::Cluster#setup_signals
    #
    def raise_exception_on_sigterm(answer=true)
      @options[:raise_exception_on_sigterm] = answer
    end

    # When using prune_bundler, if extra runtime dependencies need to be loaded to
    # initialize your app, then this setting can be used. This includes any Puma plugins.
    #
    # Before bundler is pruned, the gem names supplied will be looked up in the bundler
    # context and then loaded again after bundler is pruned.
    # Only applies if prune_bundler is used.
    #
    # @example
    #   extra_runtime_dependencies ['gem_name_1', 'gem_name_2']
    # @example
    #   extra_runtime_dependencies ['puma_worker_killer', 'puma-heroku']
    # @see Puma::Launcher#extra_runtime_deps_directories
    #
    def extra_runtime_dependencies(answer = [])
      @options[:extra_runtime_dependencies] = Array(answer)
    end

    # Additional text to display in process listing.
    #
    # If you do not specify a tag, Puma will infer it. If you do not want Puma
    # to add a tag, use an empty string.
    #
    # @example
    #   tag 'app name'
    # @example
    #   tag ''
    def tag(string)
      @options[:tag] = string.to_s
    end

    # Change the default interval for checking workers.
    #
    # The default value is 5 seconds.
    #
    # @note Cluster mode only.
    # @example
    #   worker_check_interval 5
    # @see Puma::Cluster#check_workers
    #
    def worker_check_interval(interval)
      @options[:worker_check_interval] = Integer(interval)
    end

    # Verifies that all workers have checked in to the master process within
    # the given timeout. If not the worker process will be restarted. This is
    # not a request timeout, it is to protect against a hung or dead process.
    # Setting this value will not protect against slow requests.
    #
    # This value must be greater than worker_check_interval.
    # The default value is 60 seconds.
    #
    # @note Cluster mode only.
    # @example
    #   worker_timeout 60
    # @see Puma::Cluster::Worker#ping_timeout
    #
    def worker_timeout(timeout)
      timeout = Integer(timeout)
      min = @options.fetch(:worker_check_interval, Configuration::DEFAULTS[:worker_check_interval])

      if timeout <= min
        raise "The minimum worker_timeout must be greater than the worker reporting interval (#{min})"
      end

      @options[:worker_timeout] = timeout
    end

    # Change the default worker timeout for booting.
    #
    # If unspecified, this defaults to the value of worker_timeout.
    #
    # @note Cluster mode only.
    #
    # @example
    #   worker_boot_timeout 60
    # @see Puma::Cluster::Worker#ping_timeout
    #
    def worker_boot_timeout(timeout)
      @options[:worker_boot_timeout] = Integer(timeout)
    end

    # Set the timeout for worker shutdown.
    #
    # @note Cluster mode only.
    # @see Puma::Cluster::Worker#term
    #
    def worker_shutdown_timeout(timeout)
      @options[:worker_shutdown_timeout] = Integer(timeout)
    end

    # Set the strategy for worker culling.
    #
    # There are two possible values:
    #
    # 1. **:youngest** - the youngest workers (i.e. the workers that were
    #    the most recently started) will be culled.
    # 2. **:oldest** - the oldest workers (i.e. the workers that were started
    #    the longest time ago) will be culled.
    #
    # @note Cluster mode only.
    # @example
    #   worker_culling_strategy :oldest
    # @see Puma::Cluster#cull_workers
    #
    def worker_culling_strategy(strategy)
      stategy = strategy.to_sym

      if ![:youngest, :oldest].include?(strategy)
        raise "Invalid value for worker_culling_strategy - #{stategy}"
      end

      @options[:worker_culling_strategy] = strategy
    end

    # When set to true (the default), workers accept all requests
    # and queue them before passing them to the handlers.
    # When set to false, each worker process accepts exactly as
    # many requests as it is configured to simultaneously handle.
    #
    # Queueing requests generally improves performance. In some
    # cases, such as a single threaded application, it may be
    # better to ensure requests get balanced across workers.
    #
    # Note that setting this to false disables HTTP keepalive and
    # slow clients will occupy a handler thread while the request
    # is being sent. A reverse proxy, such as nginx, can handle
    # slow clients and queue requests before they reach Puma.
    # @see Puma::Server
    def queue_requests(answer=true)
      @options[:queue_requests] = answer
    end

    # When a shutdown is requested, the backtraces of all the
    # threads will be written to $stdout. This can help figure
    # out why shutdown is hanging.
    #
    def shutdown_debug(val=true)
      @options[:shutdown_debug] = val
    end


    # Attempts to route traffic to less-busy workers by causing them to delay
    # listening on the socket, allowing workers which are not processing any
    # requests to pick up new requests first.
    #
    # Only works on MRI. For all other interpreters, this setting does nothing.
    # @see Puma::Server#handle_servers
    # @see Puma::ThreadPool#wait_for_less_busy_worker
    # @version 5.0.0
    #
    def wait_for_less_busy_worker(val=0.005)
      @options[:wait_for_less_busy_worker] = val.to_f
    end

    # Control how the remote address of the connection is set. This
    # is configurable because to calculate the true socket peer address
    # a kernel syscall is required which for very fast rack handlers
    # slows down the handling significantly.
    #
    # There are 5 possible values:
    #
    # 1. **:socket** (the default) - read the peername from the socket using the
    #    syscall. This is the normal behavior. If this fails for any reason (e.g.,
    #    if the peer disconnects between the connection being accepted and the getpeername
    #    system call), Puma will return "0.0.0.0"
    # 2. **:localhost** - set the remote address to "127.0.0.1"
    # 3. **header: <http_header>**- set the remote address to the value of the
    #    provided http header. For instance:
    #    `set_remote_address header: "X-Real-IP"`.
    #    Only the first word (as separated by spaces or comma) is used, allowing
    #    headers such as X-Forwarded-For to be used as well. If this header is absent,
    #    Puma will fall back to the behavior of :socket
    # 4. **proxy_protocol: :v1**- set the remote address to the value read from the
    #    HAproxy PROXY protocol, version 1. If the request does not have the PROXY
    #    protocol attached to it, will fall back to :socket
    # 5. **\<Any string\>** - this allows you to hardcode remote address to any value
    #    you wish. Because Puma never uses this field anyway, it's format is
    #    entirely in your hands.
    #
    def set_remote_address(val=:socket)
      case val
      when :socket
        @options[:remote_address] = val
      when :localhost
        @options[:remote_address] = :value
        @options[:remote_address_value] = "127.0.0.1".freeze
      when String
        @options[:remote_address] = :value
        @options[:remote_address_value] = val
      when Hash
        if hdr = val[:header]
          @options[:remote_address] = :header
          @options[:remote_address_header] = "HTTP_" + hdr.upcase.tr("-", "_")
        elsif protocol_version = val[:proxy_protocol]
          @options[:remote_address] = :proxy_protocol
          protocol_version = protocol_version.downcase.to_sym
          unless [:v1].include?(protocol_version)
            raise "Invalid value for proxy_protocol - #{protocol_version.inspect}"
          end
          @options[:remote_address_proxy_protocol] = protocol_version
        else
          raise "Invalid value for set_remote_address - #{val.inspect}"
        end
      else
        raise "Invalid value for set_remote_address - #{val}"
      end
    end

    # When enabled, workers will be forked from worker 0 instead of from the master process.
    # This option is similar to `preload_app` because the app is preloaded before forking,
    # but it is compatible with phased restart.
    #
    # This option also enables the `refork` command (SIGURG), which optimizes copy-on-write performance
    # in a running app.
    #
    # A refork will automatically trigger once after the specified number of requests
    # (default 1000), or pass 0 to disable auto refork.
    #
    # @note Cluster mode only.
    # @version 5.0.0
    #
    def fork_worker(after_requests=1000)
      @options[:fork_worker] = Integer(after_requests)
    end

    # The number of requests to attempt inline before sending a client back to
    # the reactor to be subject to normal ordering.
    #
    def max_fast_inline(num_of_requests)
      @options[:max_fast_inline] = Float(num_of_requests)
    end

    # Specify the backend for the IO selector.
    #
    # Provided values will be passed directly to +NIO::Selector.new+, with the
    # exception of +:auto+ which will let nio4r choose the backend.
    #
    # Check the documentation of +NIO::Selector.backends+ for the list of valid
    # options. Note that the available options on your system will depend on the
    # operating system. If you want to use the pure Ruby backend (not
    # recommended due to its comparatively low performance), set environment
    # variable +NIO4R_PURE+ to +true+.
    #
    # The default is +:auto+.
    #
    # @see https://github.com/socketry/nio4r/blob/master/lib/nio/selector.rb
    #
    def io_selector_backend(backend)
      @options[:io_selector_backend] = backend.to_sym
    end

    def mutate_stdout_and_stderr_to_sync_on_write(enabled=true)
      @options[:mutate_stdout_and_stderr_to_sync_on_write] = enabled
    end

    # Specify how big the request payload should be, in bytes.
    # This limit is compared against Content-Length HTTP header.
    # If the payload size (CONTENT_LENGTH) is larger than http_content_length_limit,
    # HTTP 413 status code is returned.
    #
    # When no Content-Length http header is present, it is compared against the
    # size of the body of the request.
     #
    # The default value for http_content_length_limit is nil.
    def http_content_length_limit(limit)
      @options[:http_content_length_limit] = limit
    end

    # Supported http methods, which will replace `Puma::Const::SUPPORTED_HTTP_METHODS`.
    # The value of `:any` will allows all methods, otherwise, the value must be
    # an array of strings.  Note that methods are all uppercase.
    #
    # `Puma::Const::SUPPORTED_HTTP_METHODS` is conservative, if you want a
    # complete set of methods, the methods defined by the
    # [IANA Method Registry](https://www.iana.org/assignments/http-methods/http-methods.xhtml)
    # are pre-defined as the constant `Puma::Const::IANA_HTTP_METHODS`.
    #
    # @note If the `methods` value is `:any`, no method check with be performed,
    #   similar to Puma v5 and earlier.
    #
    # @example Adds 'PROPFIND' to existing supported methods
    #   supported_http_methods(Puma::Const::SUPPORTED_HTTP_METHODS + ['PROPFIND'])
    # @example Restricts methods to the array elements
    #   supported_http_methods %w[HEAD GET POST PUT DELETE OPTIONS PROPFIND]
    # @example Restricts methods to the methods in the IANA Registry
    #   supported_http_methods Puma::Const::IANA_HTTP_METHODS
    # @example Allows any method
    #   supported_http_methods :any
    #
    def supported_http_methods(methods)
      if methods == :any
        @options[:supported_http_methods] = :any
      elsif Array === methods && methods == (ary = methods.grep(String).uniq) &&
        !ary.empty?
        @options[:supported_http_methods] = ary
      else
        raise "supported_http_methods must be ':any' or a unique array of strings"
      end
    end

    private

    # To avoid adding cert_pem and key_pem as URI params, we store them on the
    # options[:store] from where Puma binder knows how to find and extract them.
    def add_pem_values_to_options_store(opts)
      return if defined?(JRUBY_VERSION)

      @options[:store] ||= []

      # Store cert_pem and key_pem to options[:store] if present
      [:cert, :key].each do |v|
        opt_key = :"#{v}_pem"
        if opts[opt_key]
          index = @options[:store].length
          @options[:store] << opts[opt_key]
          opts[v] = "store:#{index}"
        end
      end
    end

    def process_hook(options_key, key, block, meth)
      @options[options_key] ||= []
      if ON_WORKER_KEY.include? key.class
        @options[options_key] << [block, key.to_sym]
      elsif key.nil?
        @options[options_key] << block
      else
        raise "'#{meth}' key must be String or Symbol"
      end
    end

    def warn_if_in_single_mode(hook_name)
      return if @options[:silence_fork_callback_warning]
      # user_options (CLI) have precedence over config file
      workers_val = @config.options.user_options[:workers] || @options[:workers] ||
        @config.puma_default_options[:workers] || 0
      if workers_val == 0
        log_string =
          "Warning: You specified code to run in a `#{hook_name}` block, " \
          "but Puma is not configured to run in cluster mode (worker count > 0 ), " \
          "so your `#{hook_name}` block did not run"

        LogWriter.stdio.log(log_string)
      end
    end
  end
end
