# frozen_string_literal: true

require 'thread'

module Aws

  # Base class used credential classes that can be refreshed. This
  # provides basic refresh logic in a thread-safe manner. Classes mixing in
  # this module are expected to implement a #refresh method that populates
  # the following instance variables:
  #
  # * `@access_key_id`
  # * `@secret_access_key`
  # * `@session_token`
  # * `@expiration`
  #
  # @api private
  module RefreshingCredentials

    SYNC_EXPIRATION_LENGTH = 300 # 5 minutes
    ASYNC_EXPIRATION_LENGTH = 600 # 10 minutes

    CLIENT_EXCLUDE_OPTIONS = Set.new([:before_refresh]).freeze

    def initialize(options = {})
      @mutex = Mutex.new
      @before_refresh = options.delete(:before_refresh) if Hash === options

      @before_refresh.call(self) if @before_refresh
      refresh
    end

    # @return [Credentials]
    def credentials
      refresh_if_near_expiration!
      @credentials
    end

    # Refresh credentials.
    # @return [void]
    def refresh!
      @mutex.synchronize do
        @before_refresh.call(self) if @before_refresh

        refresh
      end
    end

    private

    # Refreshes credentials asynchronously and synchronously.
    # If we are near to expiration, block while getting new credentials.
    # Otherwise, if we're approaching expiration, use the existing credentials
    # but attempt a refresh in the background.
    def refresh_if_near_expiration!
      # Note: This check is an optimization. Rather than acquire the mutex on every #refresh_if_near_expiration
      # call, we check before doing so, and then we check within the mutex to avoid a race condition.
      # See issue: https://github.com/aws/aws-sdk-ruby/issues/2641 for more info.
      if near_expiration?(SYNC_EXPIRATION_LENGTH)
        @mutex.synchronize do
          if near_expiration?(SYNC_EXPIRATION_LENGTH)
            @before_refresh.call(self) if @before_refresh
            refresh
          end
        end
      elsif @async_refresh && near_expiration?(ASYNC_EXPIRATION_LENGTH)
        unless @mutex.locked?
          Thread.new do
            @mutex.synchronize do
              if near_expiration?(ASYNC_EXPIRATION_LENGTH)
                @before_refresh.call(self) if @before_refresh
                refresh
              end
            end
          end
        end
      end
    end

    def near_expiration?(expiration_length)
      if @expiration
        # Are we within expiration?
        (Time.now.to_i + expiration_length) > @expiration.to_i
      else
        true
      end
    end

  end
end
