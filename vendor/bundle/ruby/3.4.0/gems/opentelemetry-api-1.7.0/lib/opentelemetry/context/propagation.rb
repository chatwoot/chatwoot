# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/context/propagation/composite_text_map_propagator'
require 'opentelemetry/context/propagation/noop_text_map_propagator'
require 'opentelemetry/context/propagation/rack_env_getter'
require 'opentelemetry/context/propagation/text_map_getter'
require 'opentelemetry/context/propagation/text_map_propagator'
require 'opentelemetry/context/propagation/text_map_setter'

module OpenTelemetry
  class Context
    # The propagation module contains APIs and utilities to interact with context
    # and propagate across process boundaries.
    #
    # The API implicitly defines 3 interfaces: TextMapPropagator, TextMapInjector
    # and TextMapExtractor. Concrete implementations of TextMapPropagator are
    # provided. Custom text map propagators can leverage these implementations
    # or simply implement the expected interface. The interfaces are described
    # below.
    #
    # The TextMapPropagator interface:
    #
    #    inject(carrier, context:, setter:)
    #    extract(carrier, context:, getter:) -> Context
    #    fields -> Array<String>
    #
    # The TextMapInjector interface:
    #
    #    inject(carrier, context:, setter:)
    #    fields -> Array<String>
    #
    # The TextMapExtractor interface:
    #
    #    extract(carrier, context:, getter:) -> Context
    #
    # The API provides 3 TextMapPropagator implementations:
    # - A default NoopTextMapPropagator that implements +inject+ and +extract+
    #   methods as no-ops. Its +fields+ method returns an empty list.
    # - A TextMapPropagator that composes an Injector and an Extractor. Its
    #   +fields+ method delegates to the provided Injector.
    # - A CompositeTextMapPropagator that wraps either a list of text map
    #   propagators or a list of Injectors and a list of Extractors. Its
    #   +fields+ method returns the union of fields returned by the Injectors
    #   it wraps.
    module Propagation
      extend self

      TEXT_MAP_GETTER = TextMapGetter.new
      TEXT_MAP_SETTER = TextMapSetter.new
      RACK_ENV_GETTER = RackEnvGetter.new

      private_constant :TEXT_MAP_GETTER, :TEXT_MAP_SETTER, :RACK_ENV_GETTER

      # Returns a {TextMapGetter} instance suitable for reading values from a
      # hash-like carrier
      def text_map_getter
        TEXT_MAP_GETTER
      end

      # Returns a {TextMapSetter} instance suitable for writing values into a
      # hash-like carrier
      def text_map_setter
        TEXT_MAP_SETTER
      end

      # @deprecated Use the rack env getter found in the
      # opentelemetry-common gem instead.
      # Returns a {RackEnvGetter} instance suitable for reading values from a
      # Rack environment.
      def rack_env_getter
        OpenTelemetry.logger.warn('OpenTelemetry::Context::Propagation.rack_env_getter has been deprecated \
          use OpenTelemetry::Common::Propagation.rack_env_getter from the opentelemetry-common gem instead.')
        RACK_ENV_GETTER
      end
    end
  end
end
