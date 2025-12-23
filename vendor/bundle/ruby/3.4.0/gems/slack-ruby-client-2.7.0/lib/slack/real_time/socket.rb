# frozen_string_literal: true
module Slack
  module RealTime
    class Socket
      attr_accessor :url, :options
      attr_reader :driver

      def initialize(url, options = {})
        @url = url
        @options = options.dup
        @driver = nil
        @logger = @options.delete(:logger) || Slack::RealTime::Config.logger || Slack::Config.logger
        @last_message_at = nil
      end

      def send_data(message)
        logger.debug("#{self.class}##{__method__}") { message }
        case message
        when Numeric then @driver.text(message.to_s)
        when String  then @driver.text(message)
        when Array   then @driver.binary(message)
        else false
        end
      end

      def connect!
        return if connected?

        connect
        logger.debug("#{self.class}##{__method__}") { @driver.class }

        @driver.on :message do
          @last_message_at = current_time
        end

        yield @driver if block_given?
      end

      # Gracefully shut down the connection.
      def disconnect!
        @driver.close
      ensure
        close
      end

      def connected?
        !@driver.nil?
      end

      def start_sync(client)
        thread = start_async(client)
        thread&.join
      rescue Interrupt
        thread&.exit
      end

      # @return [#join]
      def start_async(_client)
        raise NotImplementedError, "Expected #{self.class} to implement #{__method__}."
      end

      def restart_async(_client, _url)
        raise NotImplementedError, "Expected #{self.class} to implement #{__method__}."
      end

      def run_async(&_block)
        raise NotImplementedError, "Expected #{self.class} to implement #{__method__}."
      end

      def time_since_last_message
        return 0 unless @last_message_at

        current_time - @last_message_at
      end

      def current_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def close
        # When you call `driver.emit(:close)`, it will typically end up calling `client.close`
        # which will call `@socket.close` and end up back here. In order to break this infinite
        # recursion, we check and set `@driver = nil` before invoking `client.close`.
        return unless (driver = @driver)

        @driver = nil
        driver.emit(:close)
      end

      protected

      attr_reader :logger

      def addr
        URI(url).host
      end

      def secure?
        port == URI::HTTPS::DEFAULT_PORT
      end

      def port
        case (uri = URI(url)).scheme
        when 'wss', 'https'
          URI::HTTPS::DEFAULT_PORT
        when 'ws', 'http'
          URI::HTTP::DEFAULT_PORT
        else
          uri.port
        end
      end

      def connect
        raise NotImplementedError, "Expected #{self.class} to implement #{__method__}."
      end
    end
  end
end
