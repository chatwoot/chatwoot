# frozen_string_literal: true
module Slack
  module RealTime
    class Client
      class ClientNotStartedError < StandardError; end

      class ClientAlreadyStartedError < StandardError; end

      include Api::MessageId
      include Api::Ping
      include Api::Message
      include Api::Typing

      attr_accessor :web_client, :store, :url, *Config::ATTRIBUTES

      protected :store_class, :store_class=, :store_options, :store_options=

      def initialize(options = {})
        @callbacks = Hash.new { |h, k| h[k] = [] }
        Slack::RealTime::Config::ATTRIBUTES.each do |key|
          send("#{key}=", options.key?(key) ? options[key] : Slack::RealTime.config.send(key))
        end
        @token ||= Slack.config.token
        @logger ||= (Slack::Config.logger || Slack::Logger.default)
        @web_client = Slack::Web::Client.new(token: token, logger: logger)
      end

      [:self, :team, *Stores::Base::CACHES].each do |store_method|
        define_method store_method do
          store&.send(store_method)
        end
      end

      def on(type, &block)
        type = type.to_s
        callbacks[type] << block
      end

      # Start RealTime client and block until it disconnects.
      def start!(&block)
        @callback = block if block
        build_socket
        @socket.start_sync(self)
      end

      # Start RealTime client and return immediately.
      # The RealTime::Client will run in the background.
      def start_async(&block)
        @callback = block if block
        build_socket
        @socket.start_async(self)
      end

      def stop!
        raise ClientNotStartedError unless started?

        @socket&.disconnect!
      end

      def started?
        @socket&.connected?
      end

      class << self
        def configure
          block_given? ? yield(config) : config
        end

        def config
          Config
        end
      end

      def run_loop
        @socket.connect! do |driver|
          driver.on :open do |event|
            logger.debug("#{self}##{__method__}") { event.class.name }
            open_event(event)
            callback(event, :open)
          end

          driver.on :message do |event|
            logger.debug("#{self}##{__method__}") { "#{event.class}, #{event.data}" }
            dispatch(event)
          end

          driver.on :close do |event|
            logger.debug("#{self}##{__method__}") { event.class.name }
            callback(event, :close)
            close(event)
            callback(event, :closed)
          end

          # This must be called last to ensure any events are registered before invoking user code.
          @callback&.call(driver)
        end
      end

      # Ensure the server is running, and ping the remote server if no other messages were sent.
      def keep_alive?
        # We can't ping the remote server if we aren't connected.
        return false if @socket.nil? || !@socket.connected?

        time_since_last_message = @socket.time_since_last_message

        # If the server responded within the specified time, we are okay:
        return true if time_since_last_message < websocket_ping

        # If the server has not responded for a while:
        return false if time_since_last_message > (websocket_ping * 2)

        # Kick off the next ping message:
        ping

        true
      end

      # Check if the remote server is responsive, and if not, restart the connection.
      def run_ping!
        return if keep_alive?

        logger.warn(to_s) { 'is offline' }

        restart_async
      rescue Slack::Web::Api::Errors::SlackError => e
        # stop pinging if bot was uninstalled
        case e.message
        when 'account_inactive', 'invalid_auth'
          logger.warn(to_s) { e.message }
          raise e
        end
        logger.debug("#{self}##{__method__}") { e }
      rescue StandardError => e
        # disregard all ping worker failures, keep pinging
        logger.debug("#{self}##{__method__}") { e }
      end

      def run_ping?
        !websocket_ping.nil? && websocket_ping.positive?
      end

      def websocket_ping_timer
        websocket_ping / 2
      end

      def to_s
        if store&.team
          "id=#{store.team.id}, name=#{store.team.name}, domain=#{store.team.domain}"
        else
          super
        end
      end

      protected

      def restart_async
        logger.debug("#{self}##{__method__}")
        @socket.close
        start = web_client.rtm_connect(start_options)
        data = Slack::Messages::Message.new(start)
        @url = data.url
        @store = store_class.new(data, store_options.to_h) if store_class
        @socket.restart_async(self, @url)
      end

      # @return [Slack::RealTime::Socket]
      def build_socket
        raise ClientAlreadyStartedError if started?

        start = web_client.rtm_connect(start_options)
        data = Slack::Messages::Message.new(start)
        @url = data.url
        @store = store_class.new(data, store_options.to_h) if store_class
        @socket = socket_class.new(@url, socket_options)
      end

      def socket_options
        socket_options = {}
        socket_options[:ping] = websocket_ping if websocket_ping
        socket_options[:proxy] = websocket_proxy if websocket_proxy
        socket_options[:logger] = logger
        socket_options
      end

      attr_reader :callbacks

      def socket_class
        concurrency::Socket
      end

      def send_json(data)
        raise ClientNotStartedError unless started?

        logger.debug("#{self}##{__method__}") { data }
        @socket.send_data(data.to_json)
      end

      def open_event(_event); end

      def close(_event)
        [@socket, socket_class].each do |s|
          s.close if s.respond_to?(:close)
        end
      end

      def callback(event, type)
        callbacks = self.callbacks[type.to_s]
        return false unless callbacks

        callbacks.each do |c|
          c.call(event)
        end
        true
      rescue StandardError => e
        logger.error("#{self}##{__method__}") { e }
        false
      end

      def dispatch(event)
        return false unless event.data

        data = Slack::Messages::Message.new(JSON.parse(event.data))
        type = data.type
        return false unless type

        type = type.to_s
        logger.debug("#{self}##{__method__}") { data.to_s }
        run_handlers(type, data) if @store
        run_callbacks(type, data)
      rescue StandardError => e
        logger.error("#{self}##{__method__}") { e }
        false
      end

      def run_handlers(type, data)
        handlers = store.class.events[type.to_s]
        case async_handlers
        when :all
          @socket.run_async { handlers_loop(handlers, data) }
        when :none
          handlers_loop(handlers, data)
        else
          raise Config::InvalidAsyncHandlersError,
                "Invalid value '#{async_handlers.inspect}' for config#async_handlers, must be :all or :none."
        end
      rescue StandardError => e
        logger.error("#{self}##{__method__}") { e }
        false
      end

      def handlers_loop(handlers, data)
        handlers.each do |handler|
          store.instance_exec(data, self, &handler)
        end
      end

      def run_callbacks(type, data)
        callbacks = self.callbacks[type]
        return false unless callbacks

        callbacks.each do |c|
          c.call(data)
        end
        true
      rescue StandardError => e
        logger.error("#{self}##{__method__}") { e }
        false
      end
    end
  end
end
