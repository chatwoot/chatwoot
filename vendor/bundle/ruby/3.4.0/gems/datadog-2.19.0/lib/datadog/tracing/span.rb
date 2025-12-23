# frozen_string_literal: true

require_relative '../core/utils/safe_dup'
require_relative 'utils'

require_relative 'metadata/ext'
require_relative 'metadata'

module Datadog
  module Tracing
    # Represents a logical unit of work in the system. Each trace consists of one or more spans.
    # Each span consists of a start time and a duration. For example, a span can describe the time
    # spent on a distributed call on a separate machine, or the time spent in a small component
    # within a larger operation. Spans can be nested within each other, and in those instances
    # will have a parent-child relationship.
    # @public_api
    class Span
      include Metadata

      attr_accessor \
        :end_time,
        :id,
        :meta,
        :metrics,
        :name,
        :parent_id,
        :resource,
        :service,
        :links,
        :events,
        :type,
        :start_time,
        :status,
        :trace_id

      attr_reader \
        :metastruct

      attr_writer \
        :duration

      # Create a new span manually. Call the <tt>start()</tt> method to start the time
      # measurement and then <tt>stop()</tt> once the timing operation is over.
      #
      # * +service+: the service name for this span
      # * +resource+: the resource this span refers, or +name+ if it's missing.
      #     +nil+ can be used as a placeholder, when the resource value is not yet known at +#initialize+ time.
      # * +type+: the type of the span (such as +http+, +db+ and so on)
      # * +parent_id+: the identifier of the parent span
      # * +trace_id+: the identifier of the root span for this trace
      # * +service_entry+: whether it is a service entry span.
      # * +events+: the list of events that occurred while a span was active.
      def initialize(
        name,
        duration: nil,
        end_time: nil,
        id: nil,
        meta: nil,
        metrics: nil,
        metastruct: nil,
        parent_id: 0,
        resource: name,
        service: nil,
        start_time: nil,
        status: 0,
        type: nil,
        trace_id: nil,
        service_entry: nil,
        links: nil,
        events: nil
      )
        @name = Core::Utils::SafeDup.frozen_or_dup(name)
        @service = Core::Utils::SafeDup.frozen_or_dup(service)
        @resource = Core::Utils::SafeDup.frozen_or_dup(resource)
        @type = Core::Utils::SafeDup.frozen_or_dup(type)

        @id = id || Tracing::Utils.next_id
        @parent_id = parent_id || 0
        @trace_id = trace_id || Tracing::Utils.next_id

        @meta = meta || {}
        @metrics = metrics || {}
        @metastruct = metastruct || {}
        @status = status || 0

        # start_time and end_time track wall clock. In Ruby, wall clock
        # has less accuracy than monotonic clock, so if possible we look to only use wall clock
        # to measure duration when a time is supplied by the user, or if monotonic clock
        # is unsupported.
        @start_time = start_time
        @end_time = end_time

        # duration_start and duration_end track monotonic clock, and may remain nil in cases where it
        # is known that we have to use wall clock to measure duration.
        @duration = duration

        @service_entry = service_entry

        @links = links || []

        @events = events || []

        # Mark with the service entry span metric, if applicable
        set_metric(Metadata::Ext::TAG_TOP_LEVEL, 1.0) if service_entry
      end

      # Return whether the duration is started or not
      def started?
        !@start_time.nil?
      end

      # Return whether the duration is stopped or not.
      def stopped?
        !@end_time.nil?
      end
      alias :finished? :stopped?

      def duration
        return @duration if @duration

        start_time = @start_time
        end_time = @end_time
        end_time - start_time if start_time && end_time
      end

      def set_error(e)
        @status = Metadata::Ext::Errors::STATUS
        set_error_tags(e)
      end

      # Spans with the same ID are considered the same span
      def ==(other)
        other.instance_of?(Span) &&
          @id == other.id
      end

      # Return a string representation of the span.
      def to_s
        "Span(name:#{@name},sid:#{@id},tid:#{@trace_id},pid:#{@parent_id})"
      end

      # Return the hash representation of the current span.
      # TODO: Change this to reflect attributes when serialization
      # isn't handled by this method.
      def to_hash
        @meta['events'] = @events.map(&:to_hash).to_json unless @events.empty?

        h = {
          error: @status,
          meta: @meta,
          metrics: @metrics,
          meta_struct: @metastruct.to_h,
          name: @name,
          parent_id: @parent_id,
          resource: @resource,
          service: @service,
          span_id: @id,
          trace_id: @trace_id,
          type: @type,
          span_links: @links.map(&:to_hash)
        }

        if stopped?
          h[:start] = start_time_nano
          h[:duration] = duration_nano
        end

        h
      end

      # Return a human readable version of the span
      def pretty_print(q)
        start_time = (self.start_time.to_f * 1e9).to_i
        end_time = (self.end_time.to_f * 1e9).to_i
        q.group 0 do
          q.breakable
          q.text "Name: #{@name}\n"
          q.text "Span ID: #{@id}\n"
          q.text "Parent ID: #{@parent_id}\n"
          q.text "Trace ID: #{@trace_id}\n"
          q.text "Type: #{@type}\n"
          q.text "Service: #{@service}\n"
          q.text "Resource: #{@resource}\n"
          q.text "Error: #{@status}\n"
          q.text "Start: #{start_time}\n"
          q.text "End: #{end_time}\n"
          q.text "Duration: #{duration.to_f}\n"
          q.group(2, 'Tags: [', "]\n") do
            q.breakable
            q.seplist @meta.each do |key, value|
              q.text "#{key} => #{value}"
            end
          end
          q.group(2, 'Metrics: [', "]\n") do
            q.breakable
            q.seplist @metrics.each do |key, value|
              q.text "#{key} => #{value}"
            end
          end
          q.group(2, 'Metastruct: [', ']') do
            metastruct.pretty_print(q)
          end
        end
      end

      private

      # Used for serialization
      # @return [Integer] in nanoseconds since Epoch
      def start_time_nano
        return unless (start_time = @start_time)

        start_time.to_i * 1000000000 + start_time.nsec
      end

      # Used for serialization
      # @return [Integer] in nanoseconds since Epoch
      def duration_nano
        duration = self.duration
        return unless duration

        (duration * 1e9).to_i
      end

      # https://docs.datadoghq.com/tracing/visualization/#service-entry-span
      # A span is a service entry span when it is the entrypoint method for a request to a service.
      # You can visualize this within Datadog APM when the color of the immediate parent on a flame graph is a different
      # color. Services are also listed on the right when viewing a flame graph.
      #
      # @return [Boolean] `true` if the span is a serivce entry span
      def service_entry?
        @service_entry == true
      end
    end
  end
end
