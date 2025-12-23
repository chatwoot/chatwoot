# frozen_string_literal: true

require 'net/http'
require 'net/https'
require 'cgi'
require 'openssl'
require 'base64'
require 'forwardable'
require 'time'
require 'json'

require 'twilio-ruby/version' unless defined?(Twilio::VERSION)
require 'rack/twilio_webhook_authentication' if defined?(Rack) && defined?(Rack::MediaType)

require 'twilio-ruby/util'
require 'twilio-ruby/security/request_validator'
require 'twilio-ruby/util/configuration'

Dir[File.join(__dir__, 'twilio-ruby/framework/*.rb')].sort.each do |file|
  require file
end

module Twilio
  extend SingleForwardable

  autoload :JWT, File.join(__dir__, 'twilio-ruby', 'jwt', 'jwt.rb')
  autoload :TwiML, File.join(__dir__, 'twilio-ruby', 'twiml', 'twiml.rb')
  autoload :HTTP, File.join(__dir__, 'twilio-ruby', 'http.rb')
  autoload :REST, File.join(__dir__, 'twilio-ruby', 'rest.rb')

  def_delegators :configuration, :account_sid, :auth_token, :http_client, :region, :edge, :logger

  ##
  # Pre-configure with account SID and auth token so that you don't need to
  # pass them to various initializers each time.
  def self.configure(&block)
    yield configuration
  end

  ##
  # Returns an existing or instantiates a new configuration object.
  def self.configuration
    @configuration ||= Util::Configuration.new
  end

  private_class_method :configuration
end
