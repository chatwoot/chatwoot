# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # A link to a {Span}. Used (for example) in batching operations, where a
    # single batch handler processes multiple requests from different traces.
    # A Link can be also used to reference spans from the same trace. A Link
    # and its attributes are immutable.
    class Link
      EMPTY_ATTRIBUTES = {}.freeze

      private_constant :EMPTY_ATTRIBUTES

      # Returns the {SpanContext} for this link
      #
      # @return [SpanContext]
      attr_reader :span_context

      # Returns the frozen attributes for this link.
      #
      # @return [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}]
      attr_reader :attributes

      # Returns a new immutable {Link}.
      #
      # @param [SpanContext] span_context The context of the linked {Span}.
      # @param [optional Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}]
      #   attributes A hash of attributes for this link. Attributes will be
      #   frozen during Link initialization.
      # @return [Link]
      def initialize(span_context, attributes = nil)
        @span_context = span_context
        @attributes = attributes.freeze || EMPTY_ATTRIBUTES
      end

      # Returns true if two {Link}s are equal.
      def ==(other)
        other.span_context == @span_context && other.attributes == @attributes
      end
    end
  end
end
