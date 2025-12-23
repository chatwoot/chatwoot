require 'rack-protection'

module OmniAuth
  class AuthenticityError < StandardError; end
  class AuthenticityTokenProtection < Rack::Protection::AuthenticityToken
    def initialize(options = {})
      @options = default_options.merge(options)
    end

    def self.call(env)
      new.call!(env)
    end

    def call!(env)
      return if accepts?(env)

      instrument env
      react env
    end

    alias_method :call, :call!

  private

    def deny(_env)
      OmniAuth.logger.send(:warn, "Attack prevented by #{self.class}")
      raise AuthenticityError.new(options[:message])
    end

    alias default_reaction deny
  end
end
