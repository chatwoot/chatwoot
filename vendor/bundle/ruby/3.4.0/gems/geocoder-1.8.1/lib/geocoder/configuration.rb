require 'singleton'
require 'geocoder/configuration_hash'
require 'geocoder/util'

module Geocoder

  ##
  # Configuration options should be set by passing a hash:
  #
  #   Geocoder.configure(
  #     :timeout  => 5,
  #     :lookup   => :yandex,
  #     :api_key  => "2a9fsa983jaslfj982fjasd",
  #     :units    => :km
  #   )
  #
  def self.configure(options = nil, &block)
    if !options.nil?
      Configuration.instance.configure(options)
    end
  end

  ##
  # Read-only access to the singleton's config data.
  #
  def self.config
    Configuration.instance.data
  end

  ##
  # Read-only access to lookup-specific config data.
  #
  def self.config_for_lookup(lookup_name)
    data = config.clone
    data.reject!{ |key,value| !Configuration::OPTIONS.include?(key) }
    if config.has_key?(lookup_name)
      data.merge!(config[lookup_name])
    end
    data
  end

  ##
  # Merge the given hash into a lookup's existing configuration.
  #
  def self.merge_into_lookup_config(lookup_name, options)
    base = Geocoder.config[lookup_name]
    Geocoder.configure(lookup_name => base.merge(options))
  end

  class Configuration
    include Singleton

    OPTIONS = [
      :timeout,
      :lookup,
      :ip_lookup,
      :language,
      :host,
      :http_headers,
      :use_https,
      :http_proxy,
      :https_proxy,
      :api_key,
      :cache,
      :always_raise,
      :units,
      :distances,
      :basic_auth,
      :logger,
      :kernel_logger_level,
      :cache_options
    ]

    attr_accessor :data

    def self.set_defaults
      instance.set_defaults
    end

    def self.initialize
      instance.send(:initialize)
    end

    OPTIONS.each do |o|
      define_method o do
        @data[o]
      end
      define_method "#{o}=" do |value|
        @data[o] = value
      end
    end

    def configure(options)
      Util.recursive_hash_merge(@data, options)
    end

    def initialize # :nodoc
      @data = Geocoder::ConfigurationHash.new
      set_defaults
    end

    def set_defaults

      # geocoding options
      @data[:timeout]      = 3           # geocoding service timeout (secs)
      @data[:lookup]       = :nominatim  # name of street address geocoding service (symbol)
      @data[:ip_lookup]    = :ipinfo_io  # name of IP address geocoding service (symbol)
      @data[:language]     = :en         # ISO-639 language code
      @data[:http_headers] = {}          # HTTP headers for lookup
      @data[:use_https]    = false       # use HTTPS for lookup requests? (if supported)
      @data[:http_proxy]   = nil         # HTTP proxy server (user:pass@host:port)
      @data[:https_proxy]  = nil         # HTTPS proxy server (user:pass@host:port)
      @data[:api_key]      = nil         # API key for geocoding service
      @data[:basic_auth]   = {}          # user and password for basic auth ({:user => "user", :password => "password"})
      @data[:logger]       = :kernel     # :kernel or Logger instance
      @data[:kernel_logger_level] = ::Logger::WARN # log level, if kernel logger is used

      # exceptions that should not be rescued by default
      # (if you want to implement custom error handling);
      # supports SocketError and Timeout::Error
      @data[:always_raise] = []

      # calculation options
      @data[:units]     = :mi      # :mi or :km
      @data[:distances] = :linear  # :linear or :spherical

      # Set the default values for the caching mechanism
      # By default, the cache keys will not expire as IP addresses and phyiscal
      # addresses will rarely change.
      @data[:cache]        = nil   # cache object (must respond to #[], #[]=, and optionally #keys)
      @data[:cache_prefix] = nil   # - DEPRECATED - prefix (string) to use for all cache keys
      @data[:cache_options] = {
        prefix: 'geocoder:',
        expiration: nil
      }
    end

    instance_eval(OPTIONS.map do |option|
      o = option.to_s
      <<-EOS
      def #{o}
        instance.data[:#{o}]
      end

      def #{o}=(value)
        instance.data[:#{o}] = value
      end
      EOS
    end.join("\n\n"))
  end
end
