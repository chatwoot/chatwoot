# frozen_string_literal: true

module Aws
  class StaticTokenProvider

    include TokenProvider

    # @param [String] token
    # @param [Time] expiration
    def initialize(token, expiration=nil)
      @token = Token.new(token, expiration)
    end
  end
end
