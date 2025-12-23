# frozen_string_literal: true

require 'socket'
require 'securerandom'
require 'sentry/interface'
require 'sentry/backtrace'
require 'sentry/utils/real_ip'
require 'sentry/utils/request_id'
require 'sentry/utils/custom_inspection'

module Sentry
  # This is an abstract class that defines the shared attributes of an event.
  # Please don't use it directly. The user-facing classes are its child classes.
  class Event
    TYPE = "event"
    # These are readable attributes.
    SERIALIZEABLE_ATTRIBUTES = %i[
      event_id level timestamp
      release environment server_name modules
      message user tags contexts extra
      fingerprint breadcrumbs transaction transaction_info
      platform sdk type
    ]

    # These are writable attributes.
    WRITER_ATTRIBUTES = SERIALIZEABLE_ATTRIBUTES - %i[type timestamp level]

    MAX_MESSAGE_SIZE_IN_BYTES = 1024 * 8

    SKIP_INSPECTION_ATTRIBUTES = [:@modules, :@stacktrace_builder, :@send_default_pii, :@trusted_proxies, :@rack_env_whitelist]

    include CustomInspection

    attr_writer(*WRITER_ATTRIBUTES)
    attr_reader(*SERIALIZEABLE_ATTRIBUTES)

    # @return [RequestInterface]
    attr_reader :request

    # Dynamic Sampling Context (DSC) that gets attached
    # as the trace envelope header in the transport.
    # @return [Hash, nil]
    attr_accessor :dynamic_sampling_context

    # @return [Array<Attachment>]
    attr_accessor :attachments

    # @param configuration [Configuration]
    # @param integration_meta [Hash, nil]
    # @param message [String, nil]
    def initialize(configuration:, integration_meta: nil, message: nil)
      # Set some simple default values
      @event_id      = SecureRandom.uuid.delete("-")
      @timestamp     = Sentry.utc_now.iso8601
      @platform      = :ruby
      @type          = self.class::TYPE
      @sdk           = integration_meta || Sentry.sdk_meta

      @user          = {}
      @extra         = {}
      @contexts      = {}
      @tags          = {}
      @attachments   = []

      @fingerprint = []
      @dynamic_sampling_context = nil

      # configuration data that's directly used by events
      @server_name = configuration.server_name
      @environment = configuration.environment
      @release = configuration.release
      @modules = configuration.gem_specs if configuration.send_modules

      # configuration options to help events process data
      @send_default_pii = configuration.send_default_pii
      @trusted_proxies = configuration.trusted_proxies
      @stacktrace_builder = configuration.stacktrace_builder
      @rack_env_whitelist = configuration.rack_env_whitelist

      @message = (message || "").byteslice(0..MAX_MESSAGE_SIZE_IN_BYTES)
    end

    # @deprecated This method will be removed in v5.0.0. Please just use Sentry.configuration
    # @return [Configuration]
    def configuration
      Sentry.configuration
    end

    # Sets the event's timestamp.
    # @param time [Time, Float]
    # @return [void]
    def timestamp=(time)
      @timestamp = time.is_a?(Time) ? time.to_f : time
    end

    # Sets the event's level.
    # @param level [String, Symbol]
    # @return [void]
    def level=(level) # needed to meet the Sentry spec
      @level = level.to_s == "warn" ? :warning : level
    end

    # Sets the event's request environment data with RequestInterface.
    # @see RequestInterface
    # @param env [Hash]
    # @return [void]
    def rack_env=(env)
      unless request || env.empty?
        add_request_interface(env)

        user[:ip_address] ||= calculate_real_ip_from_rack(env) if @send_default_pii

        if request_id = Utils::RequestId.read_from(env)
          tags[:request_id] = request_id
        end
      end
    end

    # @return [Hash]
    def to_hash
      data = serialize_attributes
      data[:breadcrumbs] = breadcrumbs.to_hash if breadcrumbs
      data[:request] = request.to_hash if request
      data
    end

    # @return [Hash]
    def to_json_compatible
      JSON.parse(JSON.generate(to_hash))
    end

    private

    def add_request_interface(env)
      @request = Sentry::RequestInterface.new(env: env, send_default_pii: @send_default_pii, rack_env_whitelist: @rack_env_whitelist)
    end

    def serialize_attributes
      self.class::SERIALIZEABLE_ATTRIBUTES.each_with_object({}) do |att, memo|
        if value = public_send(att)
          memo[att] = value
        end
      end
    end

    # When behind a proxy (or if the user is using a proxy), we can't use
    # REMOTE_ADDR to determine the Event IP, and must use other headers instead.
    def calculate_real_ip_from_rack(env)
      Utils::RealIp.new(
        remote_addr: env["REMOTE_ADDR"],
        client_ip: env["HTTP_CLIENT_IP"],
        real_ip: env["HTTP_X_REAL_IP"],
        forwarded_for: env["HTTP_X_FORWARDED_FOR"],
        trusted_proxies: @trusted_proxies
      ).calculate_ip
    end
  end
end
