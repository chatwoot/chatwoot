module ScoutApm
  class InstrumentManager
    attr_reader :context

    attr_reader :installed_instruments

    def initialize(context)
      @context = context
      @installed_instruments = []
    end

    # Loads the instrumention logic.
    def install!
      case framework
      when :rails then
        install_instrument(ScoutApm::Instruments::ActionControllerRails2)
      when :rails3_or_4 then
        install_instrument(ScoutApm::Instruments::ActionControllerRails3Rails4)
        install_instrument(ScoutApm::Instruments::RailsRouter)

        if config.value("detailed_middleware")
          install_instrument(ScoutApm::Instruments::MiddlewareDetailed)
        else
          install_instrument(ScoutApm::Instruments::MiddlewareSummary)
        end
      end

      install_instrument(ScoutApm::Instruments::ActionView)
      install_instrument(ScoutApm::Instruments::ActiveRecord)
      install_instrument(ScoutApm::Instruments::Moped)
      install_instrument(ScoutApm::Instruments::Mongoid)
      install_instrument(ScoutApm::Instruments::NetHttp)
      install_instrument(ScoutApm::Instruments::Typhoeus)
      install_instrument(ScoutApm::Instruments::HttpClient)
      install_instrument(ScoutApm::Instruments::HTTP)
      install_instrument(ScoutApm::Instruments::Memcached)
      install_instrument(ScoutApm::Instruments::Redis)
      install_instrument(ScoutApm::Instruments::Redis5)
      install_instrument(ScoutApm::Instruments::InfluxDB)
      install_instrument(ScoutApm::Instruments::Elasticsearch)
      install_instrument(ScoutApm::Instruments::Grape)
    rescue
      logger.warn "Exception loading instruments:"
      logger.warn $!.message
      logger.warn $!.backtrace
    end

    # Allows users to skip individual instruments via the config file
    def skip_instrument?(instrument_klass)
      instrument_short_name = instrument_klass.name.split("::").last
      (config.value("disabled_instruments") || []).include?(instrument_short_name)
    end

    def prepend_for_instrument?(instrument_klass)
      instrument_short_name = instrument_klass.name.split("::").last

      # `use_prepend` defaults to false, which means we use `alias_method` by default.
      # If `use_prepend` is `true`, then we should default to using `prepend` unless
      # the instrument is explicitly listed in the `alias_method_instruments` config array.
      if config.value("use_prepend")
        return false if (config.value("alias_method_instruments") || []).include?(instrument_short_name)
        return true
      else
        # `use_prepend` is false, but we should use `prepend` if the instrument is
        # explicitly listed in the `prepend_instruments` array.
        return true if (config.value("prepend_instruments") || []).include?(instrument_short_name)
        return false
      end
    end

    private

    def install_instrument(instrument_klass)
      return if already_installed?(instrument_klass)

      if skip_instrument?(instrument_klass)
        logger.info "Skipping Disabled Instrument: #{instrument_klass} - To re-enable, change `disabled_instruments` key in scout_apm.yml"
        return
      end

      instance = instrument_klass.new(context)
      @installed_instruments << instance
      instance.install(prepend: prepend_for_instrument?(instrument_klass))
    end

    def already_installed?(instrument_klass)
      @installed_instruments.any? do |already_installed_instrument|
        instrument_klass === already_installed_instrument
      end
    end

    ###################
    #  Lookup Helpers #
    ###################

    def logger
      context.logger
    end

    def config
      context.config
    end

    def framework
      context.environment.framework
    end
  end
end
