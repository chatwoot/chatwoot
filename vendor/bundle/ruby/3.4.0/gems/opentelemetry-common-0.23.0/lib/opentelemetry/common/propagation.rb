# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative './propagation/rack_env_getter'
require_relative './propagation/symbol_key_getter'

module OpenTelemetry
  module Common
    # Propagation contains common helpers for context propagation.
    module Propagation
      extend self

      RACK_ENV_GETTER = RackEnvGetter.new
      SYMBOL_KEY_GETTER = SymbolKeyGetter.new
      private_constant :RACK_ENV_GETTER, :SYMBOL_KEY_GETTER

      # Returns a {RackEnvGetter} instance suitable for reading values from a
      # Rack environment.
      def rack_env_getter
        RACK_ENV_GETTER
      end

      # Returns a {SymbolKeyGetter} instance for reading values from a
      # symbol keyed hash.
      def symbol_key_getter
        SYMBOL_KEY_GETTER
      end
    end
  end
end
