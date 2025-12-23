# frozen_string_literal: true
module Slack
  module RealTime
    module Config
      class NoConcurrencyError < StandardError; end
      class InvalidAsyncHandlersError < StandardError; end

      extend self

      ATTRIBUTES = %i[
        token
        websocket_ping
        websocket_proxy
        concurrency
        start_options
        store_class
        store_options
        logger
        async_handlers
      ].freeze

      attr_accessor(*Config::ATTRIBUTES - [:concurrency])
      attr_writer :concurrency

      def reset
        self.websocket_ping = 30
        self.websocket_proxy = nil
        self.token = nil
        self.concurrency = method(:detect_concurrency)
        self.start_options = { request: { timeout: 180 } }
        self.store_class = Slack::RealTime::Stores::Starter
        self.store_options = {}
        self.logger = nil
        self.async_handlers = :none
      end

      def concurrency
        (val = @concurrency).respond_to?(:call) ? val.call : val
      end

      private

      def detect_concurrency
        Slack::RealTime::Concurrency.const_get(:Async)
      rescue LoadError, NameError
        raise NoConcurrencyError, 'Missing concurrency. Add async-websocket to your Gemfile.'
      end
    end

    class << self
      def configure
        block_given? ? yield(Config) : Config
      end

      def config
        Config
      end
    end
  end
end

Slack::RealTime::Config.reset
