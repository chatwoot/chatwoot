# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    # The instrumentation Registry contains information about instrumentation
    # available and facilitates discovery, installation and
    # configuration. This functionality is primarily useful for SDK
    # implementers.
    class Registry
      def initialize
        @lock = Mutex.new
        @instrumentation = []
      end

      # @api private
      def register(instrumentation)
        @lock.synchronize do
          @instrumentation << instrumentation
        end
      end

      # Lookup an instrumentation definition by name. Returns nil if +instrumentation_name+
      # is not found.
      #
      # @param [String] instrumentation_name A stringified class name for an instrumentation
      # @return [Instrumentation]
      def lookup(instrumentation_name)
        @lock.synchronize do
          find_instrumentation(instrumentation_name)
        end
      end

      # Install the specified instrumentation with optionally specified configuration.
      #
      # @param [Array<String>] instrumentation_names An array of instrumentation names to
      #   install
      # @param [optional Hash<String, Hash>] instrumentation_config_map A map of
      #   instrumentation_name to config. This argument is optional and config can be
      #   passed for as many or as few instrumentations as desired.
      def install(instrumentation_names, instrumentation_config_map = {})
        @lock.synchronize do
          instrumentation_names.each do |instrumentation_name|
            instrumentation = find_instrumentation(instrumentation_name)
            if instrumentation.nil?
              OpenTelemetry.logger.warn "Could not install #{instrumentation_name} because it was not found"
            else
              install_instrumentation(instrumentation, instrumentation_config_map[instrumentation.name])
            end
          end
        end
      end

      # Install all instrumentation available and installable in this process.
      #
      # @param [optional Hash<String, Hash>] instrumentation_config_map A map of
      #   instrumentation_name to config. This argument is optional and config can be
      #   passed for as many or as few instrumentations as desired.
      def install_all(instrumentation_config_map = {})
        @lock.synchronize do
          @instrumentation.map(&:instance).each do |instrumentation|
            install_instrumentation(instrumentation, instrumentation_config_map[instrumentation.name])
          end
        end
      end

      private

      def find_instrumentation(instrumentation_name)
        @instrumentation.detect { |a| a.instance.name == instrumentation_name }
                        &.instance
      end

      def install_instrumentation(instrumentation, config)
        if !instrumentation.present?
          OpenTelemetry.logger.debug "Instrumentation: #{instrumentation.name} skipping install given corresponding dependency not found"
        elsif instrumentation.install(config)
          OpenTelemetry.logger.info "Instrumentation: #{instrumentation.name} was successfully installed with the following options #{instrumentation.config}"
        else
          OpenTelemetry.logger.warn "Instrumentation: #{instrumentation.name} failed to install"
        end
      rescue => e # rubocop:disable Style/RescueStandardError
        OpenTelemetry.handle_error(exception: e, message: "Instrumentation: #{instrumentation.name} unhandled exception during install: #{e.backtrace}")
      end
    end
  end
end

require_relative './registry/version'
