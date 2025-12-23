# frozen_string_literal: true

module Datadog
  module DI
    # Builds probe status notification and snapshot payloads.
    #
    # @api private
    class ProbeNotificationBuilder
      def initialize(settings, serializer)
        @settings = settings
        @serializer = serializer
      end

      attr_reader :settings
      attr_reader :serializer

      def build_received(probe)
        build_status(probe,
          message: "Probe #{probe.id} has been received correctly",
          status: 'RECEIVED',)
      end

      def build_installed(probe)
        build_status(probe,
          message: "Probe #{probe.id} has been instrumented correctly",
          status: 'INSTALLED',)
      end

      def build_emitting(probe)
        build_status(probe,
          message: "Probe #{probe.id} is emitting",
          status: 'EMITTING',)
      end

      def build_errored(probe, exc)
        build_status(probe,
          message: "Instrumentation for probe #{probe.id} failed: #{exc}",
          status: 'ERROR',)
      end

      # Duration is in seconds.
      # path is the actual path of the instrumented file.
      def build_executed(probe,
        path: nil, rv: nil, duration: nil, caller_locations: nil,
        serialized_locals: nil, args: nil, kwargs: nil, target_self: nil,
        serialized_entry_args: nil)
        build_snapshot(probe, rv: rv, serialized_locals: serialized_locals,
          # Actual path of the instrumented file.
          path: path,
          duration: duration,
          # TODO check how many stack frames we should be keeping/sending,
          # this should be all frames for enriched probes and no frames for
          # non-enriched probes?
          caller_locations: caller_locations,
          args: args, kwargs: kwargs,
          target_self: target_self,
          serialized_entry_args: serialized_entry_args)
      end

      def build_snapshot(probe, rv: nil, serialized_locals: nil, path: nil,
        # In Ruby everything is a method, therefore we should always have
        # a target self. However, if we are not capturing a snapshot,
        # there is no need to pass in the target self.
        target_self: nil,
        duration: nil, caller_locations: nil,
        args: nil, kwargs: nil,
        serialized_entry_args: nil)
        if probe.capture_snapshot? && !target_self
          raise ArgumentError, "Asked to build snapshot with snapshot capture but target_self is nil"
        end

        # TODO also verify that non-capturing probe does not pass
        # snapshot or vars/args into this method
        captures = if probe.capture_snapshot?
          if probe.method?
            return_arguments = {
              "@return": serializer.serialize_value(rv,
                depth: probe.max_capture_depth || settings.dynamic_instrumentation.max_capture_depth,
                attribute_count: probe.max_capture_attribute_count || settings.dynamic_instrumentation.max_capture_attribute_count),
              self: serializer.serialize_value(target_self),
            }
            {
              entry: {
                # standard:disable all
                arguments: if serialized_entry_args
                  serialized_entry_args
                else
                  (args || kwargs) && serializer.serialize_args(args, kwargs, target_self,
                    depth: probe.max_capture_depth || settings.dynamic_instrumentation.max_capture_depth,
                    attribute_count: probe.max_capture_attribute_count || settings.dynamic_instrumentation.max_capture_attribute_count)
                end,
                # standard:enable all
              },
              return: {
                arguments: return_arguments,
                throwable: nil,
              },
            }
          elsif probe.line?
            {
              lines: serialized_locals && {
                probe.line_no => {
                  locals: serialized_locals,
                  arguments: {self: serializer.serialize_value(target_self)},
                },
              },
            }
          end
        end

        location = if probe.line?
          {
            file: path,
            lines: [probe.line_no],
          }
        elsif probe.method?
          {
            method: probe.method_name,
            type: probe.type_name,
          }
        end

        stack = if caller_locations
          format_caller_locations(caller_locations)
        end

        timestamp = timestamp_now
        {
          service: settings.service,
          "debugger.snapshot": {
            id: SecureRandom.uuid,
            timestamp: timestamp,
            evaluationErrors: [],
            probe: {
              id: probe.id,
              version: 0,
              location: location,
            },
            language: 'ruby',
            # TODO add test coverage for callers being nil
            stack: stack,
            captures: captures,
          },
          # In python tracer duration is under debugger.snapshot,
          # but UI appears to expect it here at top level.
          duration: duration ? (duration * 10**9).to_i : 0,
          host: nil,
          logger: {
            name: probe.file,
            method: probe.method_name || 'no_method',
            thread_name: Thread.current.name,
            # Dynamic instrumentation currently does not need thread_id for
            # anything. It can be sent if a customer requests it at which point
            # we can also determine which thread identifier to send
            # (Thread#native_thread_id or something else).
            thread_id: nil,
            version: 2,
          },
          # TODO add tests that the trace/span id is correctly propagated
          "dd.trace_id": active_trace&.id&.to_s,
          "dd.span_id": active_span&.id&.to_s,
          ddsource: 'dd_debugger',
          message: probe.template && evaluate_template(probe.template,
            duration: duration ? duration * 1000 : 0),
          timestamp: timestamp,
        }
      end

      private

      def build_status(probe, message:, status:)
        {
          service: settings.service,
          timestamp: timestamp_now,
          message: message,
          ddsource: 'dd_debugger',
          debugger: {
            diagnostics: {
              probeId: probe.id,
              probeVersion: 0,
              runtimeId: Core::Environment::Identity.id,
              parentId: nil,
              status: status,
            },
          },
        }
      end

      def format_caller_locations(caller_locations)
        caller_locations.map do |loc|
          {fileName: loc.path, function: loc.label, lineNumber: loc.lineno}
        end
      end

      def evaluate_template(template, **vars)
        message = template.dup
        vars.each do |key, value|
          message.gsub!("{@#{key}}", value.to_s)
        end
        message
      end

      def timestamp_now
        (Core::Utils::Time.now.to_f * 1000).to_i
      end

      def active_trace
        if defined?(Datadog::Tracing)
          Datadog::Tracing.active_trace
        end
      end

      def active_span
        if defined?(Datadog::Tracing)
          Datadog::Tracing.active_span
        end
      end
    end
  end
end
