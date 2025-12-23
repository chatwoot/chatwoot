# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    # @api private
    #
    # {ProxyTracer} is an implementation of {OpenTelemetry::Trace::Tracer}. It is returned from
    # the ProxyTracerProvider until a delegate tracer provider is installed. After the delegate
    # tracer provider is installed, the ProxyTracer will delegate to the corresponding "real"
    # tracer.
    class ProxyTracer < Trace::Tracer
      attr_writer :delegate

      # Returns a new {ProxyTracer} instance.
      #
      # @return [ProxyTracer]
      def initialize
        @delegate = nil
      end

      def start_root_span(name, attributes: nil, links: nil, start_timestamp: nil, kind: nil)
        return @delegate.start_root_span(name, attributes: attributes, links: links, start_timestamp: start_timestamp, kind: kind) unless @delegate.nil?

        super
      end

      def start_span(name, with_parent: nil, attributes: nil, links: nil, start_timestamp: nil, kind: nil)
        return @delegate.start_span(name, with_parent: with_parent, attributes: attributes, links: links, start_timestamp: start_timestamp, kind: kind) unless @delegate.nil?

        super
      end
    end
  end
end
