# frozen_string_literal: true

# Stripe Ruby bindings
# API spec at https://stripe.com/docs/api
require "cgi"
require "json"
require "logger"
require "net/http"
require "openssl"
require "rbconfig"
require "securerandom"
require "set"
require "socket"
require "uri"
require "forwardable"

# Version
require "stripe/api_version"
require "stripe/version"

# API operations
require "stripe/api_operations/create"
require "stripe/api_operations/delete"
require "stripe/api_operations/list"
require "stripe/api_operations/nested_resource"
require "stripe/api_operations/request"
require "stripe/api_operations/save"
require "stripe/api_operations/singleton_save"
require "stripe/api_operations/search"

# API resource support classes
require "stripe/errors"
require "stripe/object_types"
require "stripe/event_types"
require "stripe/request_options"
require "stripe/request_params"
require "stripe/stripe_context"
require "stripe/util"
require "stripe/connection_manager"
require "stripe/multipart_encoder"
require "stripe/api_requestor"
require "stripe/stripe_service"
require "stripe/stripe_client"
require "stripe/stripe_object"
require "stripe/stripe_response"
require "stripe/list_object"
require "stripe/v2_list_object"
require "stripe/search_result_object"
require "stripe/error_object"
require "stripe/api_resource"
require "stripe/api_resource_test_helpers"
require "stripe/singleton_api_resource"
require "stripe/webhook"
require "stripe/stripe_configuration"
require "stripe/resources/v2/amount"
require "stripe/resources/v2/deleted_object"
require "stripe/resources/v2/core/event_notification"

# Named API resources
require "stripe/resources"
require "stripe/services"
require "stripe/params"

# OAuth
require "stripe/oauth"
require "stripe/services/oauth_service"

module Stripe
  DEFAULT_CA_BUNDLE_PATH = __dir__ + "/data/ca-certificates.crt"

  # map to the same values as the standard library's logger
  LEVEL_DEBUG = Logger::DEBUG
  LEVEL_ERROR = Logger::ERROR
  LEVEL_INFO = Logger::INFO

  # API base constants
  DEFAULT_API_BASE = "https://api.stripe.com"
  DEFAULT_CONNECT_BASE = "https://connect.stripe.com"
  DEFAULT_UPLOAD_BASE = "https://files.stripe.com"
  DEFAULT_METER_EVENTS_BASE = "https://meter-events.stripe.com"

  # Options that can be configured globally by users
  USER_CONFIGURABLE_GLOBAL_OPTIONS = Set.new(%i[
    api_key
    api_version
    stripe_account
    api_base
    uploads_base
    connect_base
    meter_events_base
    open_timeout
    read_timeout
    write_timeout
    proxy
    verify_ssl_certs
    ca_bundle_path
    log_level
    logger
    max_network_retries
    enable_telemetry
    client_id
  ])

  @app_info = nil

  @config = Stripe::StripeConfiguration.setup

  class << self
    extend Forwardable

    attr_reader :config

    # User configurable options
    def_delegators :@config, :api_key, :api_key=
    def_delegators :@config, :api_version, :api_version=
    def_delegators :@config, :stripe_account, :stripe_account=
    def_delegators :@config, :api_base, :api_base=
    def_delegators :@config, :uploads_base, :uploads_base=
    def_delegators :@config, :connect_base, :connect_base=
    def_delegators :@config, :meter_events_base, :meter_events_base=
    def_delegators :@config, :open_timeout, :open_timeout=
    def_delegators :@config, :read_timeout, :read_timeout=
    def_delegators :@config, :write_timeout, :write_timeout=
    def_delegators :@config, :proxy, :proxy=
    def_delegators :@config, :verify_ssl_certs, :verify_ssl_certs=
    def_delegators :@config, :ca_bundle_path, :ca_bundle_path=
    def_delegators :@config, :log_level, :log_level=
    def_delegators :@config, :logger, :logger=
    def_delegators :@config, :max_network_retries, :max_network_retries=
    def_delegators :@config, :enable_telemetry=, :enable_telemetry?
    def_delegators :@config, :client_id=, :client_id

    # Internal configurations
    def_delegators :@config, :max_network_retry_delay
    def_delegators :@config, :initial_network_retry_delay
    def_delegators :@config, :ca_store
  end

  # Gets the application for a plugin that's identified some. See
  # #set_app_info.
  def self.app_info
    @app_info
  end

  def self.app_info=(info)
    @app_info = info
  end

  # Sets some basic information about the running application that's sent along
  # with API requests. Useful for plugin authors to identify their plugin when
  # communicating with Stripe.
  #
  # Takes a name and optional partner program ID, plugin URL, and version.
  def self.set_app_info(name, partner_id: nil, url: nil, version: nil)
    @app_info = {
      name: name,
      partner_id: partner_id,
      url: url,
      version: version,
    }
  end
end

Stripe.log_level = ENV["STRIPE_LOG"] unless ENV["STRIPE_LOG"].nil?
