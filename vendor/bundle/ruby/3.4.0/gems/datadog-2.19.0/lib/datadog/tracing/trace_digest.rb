# frozen_string_literal: true

module Datadog
  module Tracing
    # Trace digest that represents the important parts of an active trace.
    # Used to propagate context and continue traces across execution boundaries.
    # TODO: Update all references from span to parent (ex: span_id -> parent_id)
    # @public_api
    class TraceDigest
      # @!attribute [r] span_id
      #   Datadog id for the currently active span.
      #   @return [Integer]
      # @!attribute [r] span_name
      #   The operation name of the currently active span.
      #   @return [String]
      # @!attribute [r] span_resource
      #   The resource name of the currently active span.
      #   @return [String]
      # @!attribute [r] span_service
      #   The service of the currently active span.
      #   @return [String]
      # @!attribute [r] span_type
      #   The type of the currently active span.
      #   @return [String]
      # @!attribute [r] trace_distributed_tags
      #   Datadog-specific tags that support richer distributed tracing association.
      #   @return [Hash<String,String>]
      # @!attribute [r] trace_hostname
      #   The hostname of the currently active trace. Use to attribute traces to hosts.
      #   @return [String]
      # @!attribute [r] trace_id
      #   Datadog id for the currently active trace.
      #   @return [Integer]
      # @!attribute [r] trace_name
      #   Operation name for the currently active trace.
      #   @return [Integer]
      # @!attribute [r] trace_origin
      #   Datadog-specific attribution of this trace's creation.
      #   @return [String]
      # @!attribute [r] trace_process_id
      #   The OS-specific process id.
      #   @return [Integer]
      # @!attribute [r] trace_resource
      #   The resource name of the currently active trace.
      #   @return [String]
      # @!attribute [r] trace_runtime_id
      #   Unique id to this Ruby process. Used to differentiate traces coming from
      #   child processes forked from same parent process.
      #   @return [String]
      # @!attribute [r] trace_sampling_priority
      #   Datadog-specific sampling decision for the currently active trace.
      #   @return [Integer]
      # @!attribute [r] trace_service
      #   The service of the currently active trace.
      #   @return [String]
      # @!attribute [r] span_remote
      #   Represents whether a TraceDigest was propagated from a remote parent or created locally.
      #   @see https://opentelemetry.io/docs/specs/otel/trace/api/#isremote
      #   @return [Boolean]
      # @!attribute [r] trace_distributed_id
      #   The trace id extracted from a distributed context, if different from `trace_id`.
      #
      #   The current use case is when the distributed context has a trace id integer larger than 64-bit:
      #   This attribute will preserve the original id, while `trace_id` will only contain the lower 64 bits.
      #   @return [Integer]
      #   @see https://www.w3.org/TR/trace-context/#trace-id
      # @!attribute [r] trace_flags
      #   The W3C "trace-flags" extracted from a distributed context. This field is an 8-bit unsigned integer.
      #   @return [Integer]
      #   @see https://www.w3.org/TR/trace-context/#trace-flags
      # @!attribute [r] trace_state
      #   The W3C "tracestate" extracted from a distributed context.
      #   This field is a string representing vendor-specific distribution data.
      #   The `dd=` entry is removed from `trace_state` as its value is dynamically calculated
      #   on every propagation injection.
      #   @return [String]
      #   @see https://www.w3.org/TR/trace-context/#tracestate-header
      # @!attribute [r] trace_state_unknown_fields
      #   From W3C "tracestate"'s `dd=` entry, when keys are not recognized they are stored here long with their values.
      #   This allows later propagation to include those unknown fields, as they can represent future versions of the spec
      #   sending data through this service. This value ends in a trailing `;` to facilitate serialization.
      #   @return [String]
      # @!attribute [r] baggage
      #   The W3C "baggage" extracted from a distributed context. This field is a hash of key/value pairs.
      #   @return [Hash<String,String>]
      # TODO: The documentation for the last attribute above won't be rendered.
      # TODO: This might be a YARD bug as adding an attribute, making it now second-last attribute, renders correctly.
      attr_reader \
        :span_id,
        :span_name,
        :span_resource,
        :span_service,
        :span_type,
        :trace_distributed_tags,
        :trace_hostname,
        :trace_id,
        :trace_name,
        :trace_origin,
        :trace_process_id,
        :trace_resource,
        :trace_runtime_id,
        :trace_sampling_priority,
        :trace_service,
        :trace_distributed_id,
        :trace_flags,
        :trace_state,
        :trace_state_unknown_fields,
        :span_remote,
        :baggage

      def initialize(
        span_id: nil,
        span_name: nil,
        span_resource: nil,
        span_service: nil,
        span_type: nil,
        trace_distributed_tags: nil,
        trace_hostname: nil,
        trace_id: nil,
        trace_name: nil,
        trace_origin: nil,
        trace_process_id: nil,
        trace_resource: nil,
        trace_runtime_id: nil,
        trace_sampling_priority: nil,
        trace_service: nil,
        trace_distributed_id: nil,
        trace_flags: nil,
        trace_state: nil,
        trace_state_unknown_fields: nil,
        span_remote: true,
        baggage: nil
      )
        @span_id = span_id
        @span_name = span_name && span_name.dup.freeze
        @span_resource = span_resource && span_resource.dup.freeze
        @span_service = span_service && span_service.dup.freeze
        @span_type = span_type && span_type.dup.freeze
        @trace_distributed_tags = trace_distributed_tags && trace_distributed_tags.dup.freeze
        @trace_hostname = trace_hostname && trace_hostname.dup.freeze
        @trace_id = trace_id
        @trace_name = trace_name && trace_name.dup.freeze
        @trace_origin = trace_origin && trace_origin.dup.freeze
        @trace_process_id = trace_process_id
        @trace_resource = trace_resource && trace_resource.dup.freeze
        @trace_runtime_id = trace_runtime_id && trace_runtime_id.dup.freeze
        @trace_sampling_priority = trace_sampling_priority
        @trace_service = trace_service && trace_service.dup.freeze
        @trace_distributed_id = trace_distributed_id
        @trace_flags = trace_flags
        @trace_state = trace_state && trace_state.dup.freeze
        @trace_state_unknown_fields = trace_state_unknown_fields && trace_state_unknown_fields.dup.freeze
        @span_remote = span_remote
        @baggage = baggage && baggage.dup.freeze
        freeze
      end

      # Creates a copy of this object, modifying the provided fields.
      # @param field_value_pairs [Hash<String>] the fields to be overwritten
      # @return [TraceDigest] returns a copy of this object with the `field_value_pairs` modified
      def merge(field_value_pairs)
        # DEV: Because we want to sometimes freeze the values provided to `TraceDigest`, it's best
        # DEV: to let `#initialize` decide how to handle each field, instead of duplicating that logic here.
        TraceDigest.new(
          **{
            span_id: span_id,
            span_name: span_name,
            span_resource: span_resource,
            span_service: span_service,
            span_type: span_type,
            trace_distributed_tags: trace_distributed_tags,
            trace_hostname: trace_hostname,
            trace_id: trace_id,
            trace_name: trace_name,
            trace_origin: trace_origin,
            trace_process_id: trace_process_id,
            trace_resource: trace_resource,
            trace_runtime_id: trace_runtime_id,
            trace_sampling_priority: trace_sampling_priority,
            trace_service: trace_service,
            trace_distributed_id: trace_distributed_id,
            trace_flags: trace_flags,
            trace_state: trace_state,
            trace_state_unknown_fields: trace_state_unknown_fields,
            span_remote: span_remote,
            baggage: baggage
          }.merge!(field_value_pairs)
        )
      end
    end
  end
end
