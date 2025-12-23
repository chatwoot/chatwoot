# frozen_string_literal: true

module Stripe
  # Configurable options:
  #
  # =ca_bundle_path=
  # The location of a file containing a bundle of CA certificates. By default
  # the library will use an included bundle that can successfully validate
  # Stripe certificates.
  #
  # =log_level=
  # When set prompts the library to log some extra information to $stdout and
  # $stderr about what it's doing. For example, it'll produce information about
  # requests, responses, and errors that are received. Valid log levels are
  # `debug` and `info`, with `debug` being a little more verbose in places.
  #
  # Use of this configuration is only useful when `.logger` is _not_ set. When
  # it is, the decision what levels to print is entirely deferred to the logger.
  #
  # =logger=
  # The logger should support the same interface as the `Logger` class that's
  # part of Ruby's standard library (hint, anything in `Rails.logger` will
  # likely be suitable).
  #
  # If `.logger` is set, the value of `.log_level` is ignored. The decision on
  # what levels to print is entirely deferred to the logger.
  class StripeConfiguration
    attr_accessor :api_key, :api_version, :client_id, :enable_telemetry, :logger, :stripe_account, :stripe_context

    attr_reader :api_base, :uploads_base, :connect_base, :meter_events_base, :base_addresses, :ca_bundle_path,
                :log_level, :initial_network_retry_delay, :max_network_retries, :max_network_retry_delay,
                :open_timeout, :read_timeout, :write_timeout, :proxy, :verify_ssl_certs

    def self.setup
      new.tap do |instance|
        yield(instance) if block_given?
      end
    end

    # Set options to the StripeClient configured options, if valid as a client option and provided
    # Otherwise, for user configurable global options, set them to the global configuration
    # For all other options, set them to the StripeConfiguration default value
    def self.client_init(config_opts)
      global_config = Stripe.config
      imported_options = USER_CONFIGURABLE_GLOBAL_OPTIONS - StripeClient::CLIENT_OPTIONS
      client_config = StripeConfiguration.setup do |instance|
        imported_options.each do |key|
          instance.public_send("#{key}=", global_config.public_send(key)) if global_config.respond_to?(key)
        end
      end
      client_config.reverse_duplicate_merge(config_opts)
    end

    # Create a new config based off an existing one. This is useful when the
    # caller wants to override the global configuration
    def reverse_duplicate_merge(hash)
      dup.tap do |instance|
        hash.each do |option, value|
          instance.public_send("#{option}=", value)
        end
        instance.send("instance_variable_set", "@base_addresses",
                      { api: instance.api_base, connect: instance.connect_base,
                        files: instance.uploads_base, meter_events: instance.meter_events_base, })
      end
    end

    def initialize
      @api_version = ApiVersion::CURRENT
      @ca_bundle_path = Stripe::DEFAULT_CA_BUNDLE_PATH
      @enable_telemetry = true
      @verify_ssl_certs = true

      @max_network_retries = 2
      @initial_network_retry_delay = 0.5
      @max_network_retry_delay = 5

      @open_timeout = 30
      @read_timeout = 80
      @write_timeout = 30

      @api_base = DEFAULT_API_BASE
      @connect_base = DEFAULT_CONNECT_BASE
      @uploads_base = DEFAULT_UPLOAD_BASE
      @meter_events_base = DEFAULT_METER_EVENTS_BASE
      @base_addresses = { api: @api_base, connect: @connect_base, files: @uploads_base,
                          meter_events: @meter_events_base, }
    end

    def log_level=(val)
      # Backwards compatibility for values that we briefly allowed
      if val == "debug"
        val = Stripe::LEVEL_DEBUG
      elsif val == "info"
        val = Stripe::LEVEL_INFO
      elsif val == "error"
        val = Stripe::LEVEL_ERROR
      end

      levels = [Stripe::LEVEL_INFO, Stripe::LEVEL_DEBUG, Stripe::LEVEL_ERROR]

      if !val.nil? && !levels.include?(val)
        raise ArgumentError,
              "log_level should only be set to `nil`, `debug`, `info`, " \
              "or `error`"
      end
      @log_level = val
    end

    def max_network_retries=(val)
      @max_network_retries = val.to_i
    end

    def max_network_retry_delay=(val)
      @max_network_retry_delay = val.to_i
    end

    def initial_network_retry_delay=(val)
      @initial_network_retry_delay = val.to_i
    end

    def open_timeout=(open_timeout)
      @open_timeout = open_timeout
      APIRequestor.clear_all_connection_managers(config: self)
    end

    def read_timeout=(read_timeout)
      @read_timeout = read_timeout
      APIRequestor.clear_all_connection_managers(config: self)
    end

    def write_timeout=(write_timeout)
      raise NotImplementedError unless Net::HTTP.instance_methods.include?(:write_timeout=)

      @write_timeout = write_timeout
      APIRequestor.clear_all_connection_managers(config: self)
    end

    def proxy=(proxy)
      @proxy = proxy
      APIRequestor.clear_all_connection_managers(config: self)
    end

    def verify_ssl_certs=(verify_ssl_certs)
      @verify_ssl_certs = verify_ssl_certs
      APIRequestor.clear_all_connection_managers(config: self)
    end

    def meter_events_base=(meter_events_base)
      @meter_events_base = meter_events_base
      @base_addresses[:meter_events] = meter_events_base
      APIRequestor.clear_all_connection_managers(config: self)
    end

    def uploads_base=(uploads_base)
      @uploads_base = uploads_base
      @base_addresses[:files] = uploads_base
      APIRequestor.clear_all_connection_managers(config: self)
    end

    def connect_base=(connect_base)
      @connect_base = connect_base
      @base_addresses[:connect] = connect_base
      APIRequestor.clear_all_connection_managers(config: self)
    end

    def api_base=(api_base)
      @api_base = api_base
      @base_addresses[:api] = api_base
      APIRequestor.clear_all_connection_managers(config: self)
    end

    def ca_bundle_path=(path)
      @ca_bundle_path = path

      # empty this field so a new store is initialized
      @ca_store = nil

      APIRequestor.clear_all_connection_managers(config: self)
    end

    # A certificate store initialized from the the bundle in #ca_bundle_path and
    # which is used to validate TLS on every request.
    #
    # This was added to the give the gem "pseudo thread safety" in that it seems
    # when initiating many parallel requests marshaling the certificate store is
    # the most likely point of failure (see issue #382). Any program attempting
    # to leverage this pseudo safety should make a call to this method (i.e.
    # `Stripe.ca_store`) in their initialization code because it marshals lazily
    # and is itself not thread safe.
    def ca_store
      @ca_store ||= begin
        store = OpenSSL::X509::Store.new
        store.add_file(ca_bundle_path)
        store
      end
    end

    def enable_telemetry?
      enable_telemetry
    end

    # Generates a deterministic key to identify configuration objects with
    # identical configuration values.
    def key
      instance_variables
        .collect { |variable| instance_variable_get(variable) }
        .join
    end
  end
end
