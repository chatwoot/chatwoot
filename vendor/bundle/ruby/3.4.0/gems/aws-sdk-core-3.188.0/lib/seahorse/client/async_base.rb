# frozen_string_literal: true

module Seahorse
  module Client
    class AsyncBase < Seahorse::Client::Base

      # default H2 plugins
      @plugins = PluginList.new([
        Plugins::Endpoint,
        Plugins::H2,
        Plugins::ResponseTarget
      ])

      def initialize(plugins, options)
        super
        @connection = H2::Connection.new(options)
        @options = options
      end

      # @return [H2::Connection]
      attr_reader :connection

      # @return [Array<Symbol>] Returns a list of valid async request
      #   operation names.
      def operation_names
        self.class.api.async_operation_names
      end

      # Closes the underlying HTTP2 Connection for the client
      # @return [Symbol] Returns the status of the connection (:closed)
      def close_connection
        @connection.close!
      end

      # Creates a new HTTP2 Connection for the client
      # @return [Seahorse::Client::H2::Connection]
      def new_connection
        if @connection.closed?
          @connection = H2::Connection.new(@options)
        else
          @connection
        end
      end

      def connection_errors
        @connection.errors
      end

    end
  end
end
