# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  class Context
    # The Key class provides mechanisms to index and access values from a
    # Context
    class Key
      attr_reader :name

      # @api private
      # Use Context.create_key to obtain a Key instance.
      def initialize(name)
        @name = name
      end

      # Returns the value indexed by this Key in the specified context
      #
      # @param [optional Context] context The Context to lookup the key from.
      #   Defaults to +Context.current+.
      def get(context = Context.current)
        context[self]
      end
    end
  end
end
