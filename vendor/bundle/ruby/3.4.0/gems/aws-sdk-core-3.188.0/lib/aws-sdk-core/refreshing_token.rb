# frozen_string_literal: true

require 'thread'

module Aws

  # Module/mixin used by token provider classes that can be refreshed. This
  # provides basic refresh logic in a thread-safe manner. Classes mixing in
  # this module are expected to implement a #refresh method that populates
  # the following instance variable:
  #
  # * `@token` [Token] - {Aws::Token} object with the `expiration` and `token`
  #       fields set.
  #
  # @api private
  module RefreshingToken

    def initialize(options = {})
      @mutex = Mutex.new
      @before_refresh = options.delete(:before_refresh) if Hash === options

      @before_refresh.call(self) if @before_refresh
      refresh
    end

    # @return [Token]
    def token
      refresh_if_near_expiration
      @token
    end

    # @return [Time,nil]
    def expiration
      refresh_if_near_expiration
      @expiration
    end

    # Refresh token.
    # @return [void]
    def refresh!
      @mutex.synchronize do
        @before_refresh.call(self) if @before_refresh
        refresh
      end
    end

    private

    # Refreshes token if it is within
    # 5 minutes of expiration.
    def refresh_if_near_expiration
      if near_expiration?
        @mutex.synchronize do
          if near_expiration?
            @before_refresh.call(self) if @before_refresh
            refresh
          end
        end
      end
    end

    def near_expiration?
      if @token && @token.expiration
        # are we within 5 minutes of expiration?
        (Time.now.to_i + 5 * 60) > @token.expiration.to_i
      else
        true
      end
    end
  end
end
