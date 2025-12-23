# frozen_string_literal: true

# rubocop:disable Lint/AssignmentInCondition

require 'monitor'

module Datadog
  module DI
    # Stores probes received from remote config (that we can parse, in other
    # words, whose type/attributes we support), requests needed instrumentation
    # for the probes via Instrumenter, and stores pending probes (those which
    # haven't yet been instrumented successfully due to their targets not
    # existing) and failed probes (where we are certain the target will not
    # ever be loaded, or otherwise become valid).
    #
    # @api private
    class ProbeManager
      def initialize(settings, instrumenter, probe_notification_builder,
        probe_notifier_worker, logger, telemetry: nil)
        @settings = settings
        @instrumenter = instrumenter
        @probe_notification_builder = probe_notification_builder
        @probe_notifier_worker = probe_notifier_worker
        @logger = logger
        @telemetry = telemetry
        @installed_probes = {}
        @pending_probes = {}
        @failed_probes = {}
        @lock = Monitor.new

        @definition_trace_point = TracePoint.trace(:end) do |tp|
          install_pending_method_probes(tp.self)
        rescue => exc
          raise if settings.dynamic_instrumentation.internal.propagate_all_exceptions
          logger.debug { "di: unhandled exception in definition trace point: #{exc.class}: #{exc}" }
          telemetry&.report(exc, description: "Unhandled exception in definition trace point")
          # TODO test this path
        end
      end

      attr_reader :logger
      attr_reader :telemetry

      # TODO test that close is called during component teardown and
      # the trace point is cleared
      def close
        definition_trace_point.disable
        clear_hooks
      end

      def clear_hooks
        @lock.synchronize do
          @pending_probes.clear
          @installed_probes.each do |probe_id, probe|
            instrumenter.unhook(probe)
          end
          @installed_probes.clear
        end
      end

      attr_reader :settings
      attr_reader :instrumenter
      attr_reader :probe_notification_builder
      attr_reader :probe_notifier_worker

      def installed_probes
        @lock.synchronize do
          @installed_probes
        end
      end

      def pending_probes
        @lock.synchronize do
          @pending_probes
        end
      end

      # Probes that failed to instrument for reasons other than the target is
      # not yet loaded are added to this collection, so that we do not try
      # to instrument them every time remote configuration is processed.
      def failed_probes
        @lock.synchronize do
          @failed_probes
        end
      end

      # Requests to install the specified probe.
      #
      # If the target of the probe does not exist, assume the relevant
      # code is not loaded yet (rather than that it will never be loaded),
      # and store the probe in a pending probe list. When classes are
      # defined, or files loaded, the probe will be checked against the
      # newly defined classes/loaded files, and will be installed if it
      # matches.
      def add_probe(probe)
        @lock.synchronize do
          # Probe failed to install previously, do not try to install it again.
          if msg = @failed_probes[probe.id]
            # TODO test this path
            raise Error::ProbePreviouslyFailed, msg
          end

          begin
            instrumenter.hook(probe, &method(:probe_executed_callback))

            @installed_probes[probe.id] = probe
            payload = probe_notification_builder.build_installed(probe)
            probe_notifier_worker.add_status(payload)
            # The probe would only be in the pending probes list if it was
            # previously attempted to be installed and the target was not loaded.
            # Always remove from pending list here because it makes the
            # API smaller and shouldn't cause any actual problems.
            @pending_probes.delete(probe.id)
            logger.trace { "di: installed #{probe.type} probe at #{probe.location} (#{probe.id})" }
            true
          rescue Error::DITargetNotDefined
            @pending_probes[probe.id] = probe
            logger.trace { "di: could not install #{probe.type} probe at #{probe.location} (#{probe.id}) because its target is not defined, adding it to pending list" }
            false
          end
        rescue => exc
          # In "propagate all exceptions" mode we will try to instrument again.
          raise if settings.dynamic_instrumentation.internal.propagate_all_exceptions

          logger.debug { "di: error processing probe configuration: #{exc.class}: #{exc}" }
          telemetry&.report(exc, description: "Error processing probe configuration")
          # TODO report probe as failed to agent since we won't attempt to
          # install it again.

          # TODO add top stack frame to message
          @failed_probes[probe.id] = "#{exc.class}: #{exc}"

          raise
        end
      end

      # Removes probes with ids other than in the specified list.
      #
      # This method is meant to be invoked from remote config processor.
      # Remote config contains the list of currently defined probes; any
      # probes not in that list have been removed by user and should be
      # de-instrumented from the application.
      def remove_other_probes(probe_ids)
        @lock.synchronize do
          @pending_probes.values.each do |probe|
            unless probe_ids.include?(probe.id)
              @pending_probes.delete(probe.id)
            end
          end
          @installed_probes.values.each do |probe|
            unless probe_ids.include?(probe.id)
              begin
                instrumenter.unhook(probe)
                # Only remove the probe from installed list if it was
                # successfully de-instrumented. Active probes do incur overhead
                # for the running application, and if the error is ephemeral
                # we want to try removing the probe again at the next opportunity.
                #
                # TODO give up after some time?
                @installed_probes.delete(probe.id)
              rescue => exc
                raise if settings.dynamic_instrumentation.internal.propagate_all_exceptions
                # Silence all exceptions?
                # TODO should we propagate here and rescue upstream?
                logger.debug { "di: error removing #{probe.type} probe at #{probe.location} (#{probe.id}): #{exc.class}: #{exc}" }
                telemetry&.report(exc, description: "Error removing probe")
              end
            end
          end
        end
      end

      # Installs pending method probes, if any, for the specified class.
      #
      # This method is meant to be called from the "end" trace point,
      # which is invoked for each class definition.
      private def install_pending_method_probes(cls)
        @lock.synchronize do
          # TODO search more efficiently than linearly
          @pending_probes.each do |probe_id, probe|
            if probe.method?
              # TODO move this stringification elsewhere
              if probe.type_name == cls.name
                begin
                  # TODO is it OK to hook from trace point handler?
                  # TODO the class is now defined, but can hooking still fail?
                  instrumenter.hook(probe, &method(:probe_executed_callback))
                  @pending_probes.delete(probe.id)
                  break
                rescue Error::DITargetNotDefined
                  # This should not happen... try installing again later?
                rescue => exc
                  raise if settings.dynamic_instrumentation.internal.propagate_all_exceptions

                  logger.debug { "di: error installing #{probe.type} probe at #{probe.location} (#{probe.id}) after class is defined: #{exc.class}: #{exc}" }
                  telemetry&.report(exc, description: "Error installing probe after class is defined")
                end
              end
            end
          end
        end
      end

      # Installs pending line probes, if any, for the file of the specified
      # absolute path.
      #
      # This method is meant to be called from the script_compiled trace
      # point, which is invoked for each required or loaded file
      # (and also for eval'd code, but those invocations are filtered out).
      def install_pending_line_probes(path)
        if path.nil?
          raise ArgumentError, "path must not be nil"
        end
        @lock.synchronize do
          @pending_probes.values.each do |probe|
            if probe.line?
              if probe.file_matches?(path)
                add_probe(probe)
              end
            end
          end
        end
      end

      # Entry point invoked from the instrumentation when the specfied probe
      # is invoked (that is, either its target method is invoked, or
      # execution reached its target file/line).
      #
      # This method is responsible for queueing probe status to be sent to the
      # backend (once per the probe's lifetime) and a snapshot corresponding
      # to the current invocation.
      def probe_executed_callback(probe:, **opts)
        logger.trace { "di: executed #{probe.type} probe at #{probe.location} (#{probe.id})" }
        unless probe.emitting_notified?
          payload = probe_notification_builder.build_emitting(probe)
          probe_notifier_worker.add_status(payload)
          probe.emitting_notified = true
        end

        payload = probe_notification_builder.build_executed(probe, **opts)
        probe_notifier_worker.add_snapshot(payload)
      end

      # Class/module definition trace point (:end type).
      # Used to install hooks when the target classes/modules aren't yet
      # defined when the hook request is received.
      attr_reader :definition_trace_point
    end
  end
end

# rubocop:enable Lint/AssignmentInCondition
