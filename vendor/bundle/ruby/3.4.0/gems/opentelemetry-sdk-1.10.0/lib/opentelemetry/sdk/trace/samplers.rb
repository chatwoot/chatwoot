# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk/trace/samplers/decision'
require 'opentelemetry/sdk/trace/samplers/result'
require 'opentelemetry/sdk/trace/samplers/constant_sampler'
require 'opentelemetry/sdk/trace/samplers/parent_based'
require 'opentelemetry/sdk/trace/samplers/trace_id_ratio_based'

module OpenTelemetry
  module SDK
    module Trace
      # The Samplers module contains the sampling logic for OpenTelemetry. The
      # reference implementation provides a {TraceIdRatioBased}, {ALWAYS_ON},
      # {ALWAYS_OFF}, and {ParentBased}.
      #
      # Custom samplers can be provided by SDK users. The required interface is:
      #
      #   should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:) -> Result
      #   description -> String
      #
      # Where:
      #
      # @param [String] trace_id The trace_id of the {Span} to be created.
      # @param [OpenTelemetry::Context] parent_context The
      #   {OpenTelemetry::Context} with a parent {Span}. The {Span}'s
      #   {OpenTelemetry::Trace::SpanContext} may be invalid to indicate a
      #   root span.
      # @param [Enumerable<Link>] links A collection of links to be associated
      #   with the {Span} to be created. Can be nil.
      # @param [String] name Name of the {Span} to be created.
      # @param [Symbol] kind The {OpenTelemetry::Trace::SpanKind} of the {Span}
      #   to be created. Can be nil.
      # @param [Hash<String, Object>] attributes Attributes to be attached
      #   to the {Span} to be created. Can be nil.
      # @return [Result] The sampling result.
      module Samplers
        # Returns a {Result} with {Decision::RECORD_AND_SAMPLE}.
        ALWAYS_ON = ConstantSampler.new(decision: Decision::RECORD_AND_SAMPLE, description: 'AlwaysOnSampler')

        # Returns a {Result} with {Decision::DROP}.
        ALWAYS_OFF = ConstantSampler.new(decision: Decision::DROP, description: 'AlwaysOffSampler')

        # Returns a new sampler. It delegates to samplers according to the following rules:
        #
        # | Parent | parent.remote? | parent.trace_flags.sampled? | Invoke sampler |
        # |--|--|--|--|
        # | absent | n/a | n/a | root |
        # | present | true | true | remote_parent_sampled |
        # | present | true | false | remote_parent_not_sampled |
        # | present | false | true | local_parent_sampled |
        # | present | false | false | local_parent_not_sampled |
        #
        # @param [Sampler] root The sampler to which the sampling
        #   decision is delegated for spans with no parent (root spans).
        # @param [optional Sampler] remote_parent_sampled The sampler to which the sampling
        #   decision is delegated for remote parent sampled spans. Defaults to ALWAYS_ON.
        # @param [optional Sampler] remote_parent_not_sampled The sampler to which the sampling
        #   decision is delegated for remote parent not sampled spans. Defaults to ALWAYS_OFF.
        # @param [optional Sampler] local_parent_sampled The sampler to which the sampling
        #   decision is delegated for local parent sampled spans. Defaults to ALWAYS_ON.
        # @param [optional Sampler] local_parent_not_sampled The sampler to which the sampling
        #   decision is delegated for local parent not sampld spans. Defaults to ALWAYS_OFF.
        def self.parent_based(
          root:,
          remote_parent_sampled: ALWAYS_ON,
          remote_parent_not_sampled: ALWAYS_OFF,
          local_parent_sampled: ALWAYS_ON,
          local_parent_not_sampled: ALWAYS_OFF
        )
          ParentBased.new(root, remote_parent_sampled, remote_parent_not_sampled, local_parent_sampled, local_parent_not_sampled)
        end

        # Returns a new sampler. The ratio describes the proportion of the trace ID
        # space that is sampled.
        #
        # @param [Numeric] ratio The desired sampling ratio.
        #   Must be within [0.0, 1.0].
        # @raise [ArgumentError] if ratio is out of range
        def self.trace_id_ratio_based(ratio)
          raise ArgumentError, 'ratio must be in range [0.0, 1.0]' unless (0.0..1.0).cover?(ratio)

          TraceIdRatioBased.new(ratio)
        end
      end
    end
  end
end
