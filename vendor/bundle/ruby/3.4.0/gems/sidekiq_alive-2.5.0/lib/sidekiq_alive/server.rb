# frozen_string_literal: true

module SidekiqAlive
  module Server
    class << self
      def run!
        server.run!
      end

      private

      def server
        use_rack? ? Rack : Default
      end

      def use_rack?
        return false unless SidekiqAlive.config.server

        Helpers.use_rackup? || Helpers.use_rack?
      end

      def logger
        SidekiqAlive.logger
      end
    end
  end
end

require_relative "server/default"
require_relative "server/rack"
