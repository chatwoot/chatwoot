# frozen_string_literal: true

module SidekiqAlive
  module Helpers
    class << self
      def sidekiq_7
        current_sidekiq_version >= Gem::Version.new("7")
      end

      def sidekiq_6
        current_sidekiq_version >= Gem::Version.new("6") &&
          current_sidekiq_version < Gem::Version.new("7")
      end

      def sidekiq_5
        current_sidekiq_version >= Gem::Version.new("5") &&
          current_sidekiq_version < Gem::Version.new("6")
      end

      def use_rack?
        return @use_rack if defined?(@use_rack)

        require "rack"
        @use_rack = current_rack_version < Gem::Version.new("3")
      rescue LoadError
        # currently this won't happen because rack is a dependency of sidekiq
        @use_rack = false
      end

      def use_rackup?
        return @use_rackup if defined?(@use_rackup)

        require "rackup"
        @use_rackup = current_rack_version >= Gem::Version.new("3")
      rescue LoadError
        if current_rack_version >= Gem::Version.new("3")
          SidekiqAlive.logger.warn("rackup gem required with rack >= 3, defaulting to default server")
        end
        @use_rackup = false
      end

      private

      def current_sidekiq_version
        Gem.loaded_specs["sidekiq"].version
      end

      def current_rack_version
        Gem.loaded_specs["rack"].version
      end
    end
  end
end
