# frozen_string_literal: true

module Aws
  class Token

    # @param [String] token
    # @param [Time] expiration
    def initialize(token, expiration=nil)
      @token = token
      @expiration = expiration
    end

    # @return [String, nil]
    attr_reader :token

    # @return [Time, nil]
    attr_reader :expiration

    # @return [Boolean] Returns `true` if token is set
    def set?
      !token.nil? && !token.empty?
    end

    # Removing the token from the default inspect string.
    # @api private
    def inspect
      "#<#{self.class.name} token=[FILTERED]> expiration=#{expiration}>"
    end

  end
end
