module ScoutApm
  class AgentContext

    attr_accessor :extensions

    # Initially start up without attempting to load a configuration file. We
    # need to be able to lookup configuration options like "application_root"
    # which would then in turn influence where the yaml configuration file is
    # located
    #
    # Later in initialization, we set config= to include the file.
    def initialize()
      @logger = LoggerFactory.build_minimal_logger
      @process_start_time = Time.now
      @extensions = ScoutApm::Extensions::Config.new(self)
    end

    def marshal_dump
      []
    end

    def marshal_load(*args)
      @logger = LoggerFactory.build_minimal_logger
      @process_start_time = Time.now
    end

    #####################################
    #  Lifecycle: Remote Server/Client
    #
    #  This allows short lived forked processes to communicate back to the parent process.
    #  Used in the Resque instrumentation
    #
    #  Parent Pre-fork: start_remote_server! once
    #  Child Post-fork: become_remote_client! after each fork
    #
    #  TODO: Figure out where to extract this to
    #####################################

    def start_remote_server!(bind, port)
      return if @remote_server && @remote_server.running?

      logger.info("Starting Remote Agent Server")

      # Start the listening web server only in parent process.
      @remote_server = ScoutApm::Remote::Server.new(
        bind,
        port,
        ScoutApm::Remote::Router.new(ScoutApm::SynchronousRecorder.new(self), logger),
        logger
      )

      @remote_server.start
    end

    # Execute this in the child process of a remote agent. The parent is
    # expected to have its accepting webserver up and running
    def become_remote_client!(host, port)
      logger.debug("Becoming Remote Agent (reporting to: #{host}:#{port})")
      @recorder = ScoutApm::Remote::Recorder.new(host, port, logger)
      @store = ScoutApm::FakeStore.new
    end


    ###############
    #  Accessors  #
    ###############

    attr_reader :process_start_time

    def config
      @config ||= ScoutApm::Config.without_file(self)
    end

    def environment
      @environment ||= ScoutApm::Environment.instance
    end

    def started?
      @started
    end

    def shutting_down?
      @shutting_down
    end

    def installed?
      @installed
    end

    def logger
      @logger ||= LoggerFactory.build(config, environment)
    end

    def ignored_uris
      @ignored_uris ||= ScoutApm::IgnoredUris.new(config.value('ignore'))
    end

    def slow_request_policy
      @slow_request_policy ||= ScoutApm::SlowRequestPolicy.new(self).tap{|p| p.add_default_policies }
    end

    def slow_job_policy
      @slow_job_policy ||= ScoutApm::SlowRequestPolicy.new(self).tap{|p| p.add_default_policies }
    end

    # Maintains a Histogram of insignificant/significant autoinstrument layers.
    # significant = 1
    # insignificant = 0
    def auto_instruments_layer_histograms
      @auto_instruments_layer_histograms ||= ScoutApm::RequestHistograms.new
    end

    # Histogram of the cumulative requests since the start of the process
    def request_histograms
      @request_histograms ||= ScoutApm::RequestHistograms.new
    end

    # Histogram of the requests, distinct by reporting period (minute)
    # { StoreReportingPeriodTimestamp => RequestHistograms }
    def request_histograms_by_time
      @request_histograms_by_time ||= Hash.new { |h, k| h[k] = ScoutApm::RequestHistograms.new }
    end

    def transaction_time_consumed
      @transaction_time_consumed ||= ScoutApm::TransactionTimeConsumed.new
    end

    def store
      return @store if @store
      self.store = ScoutApm::Store.new(self)
    end

    def layaway
      @layaway ||= ScoutApm::Layaway.new(self)
    end

    def recorder
      @recorder ||= RecorderFactory.build(self)
    end

    def dev_trace_enabled?
      config.value('dev_trace') && environment.env == "development"
    end

    ###################
    #  Error Service  #
    ###################

    def error_buffer
      @error_buffer ||= ScoutApm::ErrorService::ErrorBuffer.new(self)
    end

    def ignored_exceptions
      @ignored_exceptions ||= ScoutApm::ErrorService::IgnoredExceptions.new(self, config.value('errors_ignored_exceptions'))
    end

    #############
    #  Setters  #
    #############

    # When we set the config for any reason, there are some values we must
    # reinitialize, since the config could have changed their settings, so nil
    # them out here, then let them get lazily reset as needed
    #
    # Don't use this in initializer, since it'll attempt to log immediately
    def config=(config)
      @config = config

      @logger = nil

      log_configuration_settings

      @ignored_uris = nil
      @slow_request_policy = nil
      @slow_job_policy = nil
      @request_histograms = nil
      @request_histograms_by_time = nil
      @store = nil
      @layaway = nil
      @recorder = nil
    end

    def installed!
      @installed = true
    end

    def started!
      @started = true
    end

    def shutting_down!
      @shutting_down = true
    end

    def store=(store)
      @store = store

      # Installs the default samplers
      # Don't install samplers on nil stores
      if store
        ScoutApm::Instruments::Samplers::DEFAULT_SAMPLERS.each { |s| store.add_sampler(s) }
      end
    end

    def recorder=(recorder)
      @recorder = recorder
    end

    # I believe this is only useful for testing?
    def environment=(env)
      @environment = env
    end

    #########################
    #  Callbacks & helpers  #
    #
    #  Should find ways to remove these into external spots
    #########################

    # Called after config is reset and loaded from file
    def log_configuration_settings
      @config.log_settings(logger)

      if !@config.any_keys_found?
        logger.info("No configuration file loaded, and no configuration found in ENV. " +
                    "For assistance configuring Scout, visit " +
                    "https://docs.scoutapm.com/#ruby-configuration-options")
      end
    end
  end

  class RecorderFactory
    def self.build(context)
      if context.config.value("async_recording")
        context.logger.debug("Using asynchronous recording")
        ScoutApm::BackgroundRecorder.new(context).start
      else
        context.logger.debug("Using synchronous recording")
        ScoutApm::SynchronousRecorder.new(context).start
      end
    end
  end

  class LoggerFactory
    def self.build(config, environment)
      ScoutApm::Logger.new(environment.root,
        {
          :log_level     => config.value('log_level'),
          :log_file_path => config.value('log_file_path'),
          :stdout        => config.value('log_stdout') || environment.platform_integration.log_to_stdout?,
          :stderr        => config.value('log_stderr'),
          :logger_class  => config.value('log_class'),
        }
      )
    end

    def self.build_minimal_logger
      ScoutApm::Logger.new(nil, :stdout => true)
    end
  end
end
