module Koala
  module Utils

    # Utility methods used by Koala.
    require 'logger'
    require 'forwardable'

    extend Forwardable
    extend self

    def_delegators :logger, :debug, :info, :warn, :error, :fatal, :level, :level=

    # The Koala logger, an instance of the standard Ruby logger, pointing to STDOUT by default.
    # In Rails projects, you can set this to Rails.logger.
    attr_accessor :logger
    self.logger = Logger.new(STDOUT)
    self.logger.level = Logger::ERROR

    # @private
    DEPRECATION_PREFIX = "KOALA: Deprecation warning: "

    # Prints a deprecation message.
    # Each individual message will only be printed once to avoid spamming.
    def deprecate(message)
      @posted_deprecations ||= []
      unless @posted_deprecations.include?(message)
        # only include each message once
        Kernel.warn("#{DEPRECATION_PREFIX}#{message}")
        @posted_deprecations << message
      end
    end

    # Ensures that a hash uses symbols as opposed to strings
    # Useful for allowing either syntax for end users
    def symbolize_hash(hash)
      return hash unless hash.is_a?(Hash)

      hash.inject({}){ |memo,(key,value)| memo[key.to_sym] = symbolize_hash(value); memo }
    end
  end
end