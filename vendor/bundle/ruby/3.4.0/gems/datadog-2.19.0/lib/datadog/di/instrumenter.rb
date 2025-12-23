# frozen_string_literal: true

require_relative '../core/utils/time'

# rubocop:disable Lint/AssignmentInCondition

module Datadog
  module DI
    # Arranges to invoke a callback when a particular Ruby method or
    # line of code is executed.
    #
    # Method instrumentation is accomplished via module prepending.
    # Unlike the alias_method_chain pattern, module prepending permits
    # removing instrumentation with no virtually performance side-effects
    # (the target class retains an empty included module, but no additional
    # code is executed as part of target method).
    #
    # Method hooking works with explicitly defined methods and "virtual"
    # methods defined via method_missing.
    #
    # Line instrumentation is normally accomplished with a targeted line
    # trace point. This requires MRI and at least Ruby 2.6.
    # For testing purposes, it is also possible to use untargeted trace
    # points, but they have a huge performance penalty and should generally
    # not be used in production.
    #
    # Targeted line trace points require tracking of loaded code; see
    # the CodeTracker class for more details.
    #
    # Instrumentation state (i.e., the module or trace point used for
    # instrumentation) is stored in the Probe instance. Thus, Instrumenter
    # mutates attributes of Probes it is asked to install or remove.
    # A previous version of the code attempted to maintain the instrumentation
    # state within Instrumenter but this was very messy and hard to
    # guarantee correctness of. With the state stored in Probes, it is
    # straightforward to determine if a Probe has been successfully instrumented,
    # and thus requires cleanup, and to properly clean it up.
    #
    # Note that the upstream code is responsible for generally storing Probes.
    # This is normally accomplished by ProbeManager. ProbeManager stores all
    # known probes, instrumented or not, and is responsible for calling
    # +unhook+ of Instrumenter to clean up instrumentation when a user
    # deletes a probe in UI or when DI is shut down.
    #
    # Given the need to store state, and also that there are several Probe
    # attributes that affect how instrumentation is set up and that must be
    # consulted very early in the callback invocation (e.g., to perform
    # rate limiting correctly), Instrumenter takes Probe instances as
    # arguments rather than e.g. file + line number or class + method name.
    # As a result, Instrumenter is rather coupled to DI the product and is
    # not trivially usable as a general-purpose Ruby instrumentation tool
    # (however, Probe instances can be replaced by OpenStruct instances
    # providing the same interface with not much effort).
    #
    # Instrumenter (this class) is responsible for building snapshots.
    # This is because to capture values on method entry, those values need to
    # be duplicated or serialized into immutable values to prevent their
    # modification by the instrumented method. Therefore this class must
    # do at least some serialization/snapshot building and to keep the code
    # well-encapsulated, all serialization/snapshot building should thus be
    # initiated from this class rather than downstream code.
    #
    # As a consequence of Instrumenter building snapshots, it should not
    # expose TracePoint objects to any downstream code.
    #
    # @api private
    class Instrumenter
      def initialize(settings, serializer, logger, code_tracker: nil, telemetry: nil)
        @settings = settings
        @serializer = serializer
        @logger = logger
        @telemetry = telemetry
        @code_tracker = code_tracker

        @lock = Mutex.new
      end

      attr_reader :settings
      attr_reader :serializer
      attr_reader :logger
      attr_reader :telemetry
      attr_reader :code_tracker

      # This is a substitute for Thread::Backtrace::Location
      # which does not have a public constructor.
      # Used for the fabricated stack frame for the method itself
      # for method probes (which use Module#prepend and thus aren't called
      # from the method but from outside of the method).
      Location = Struct.new(:path, :lineno, :label)

      def hook_method(probe, &block)
        unless block
          raise ArgumentError, 'block is required'
        end

        lock.synchronize do
          if probe.instrumentation_module
            # Already instrumented, warn?
            return
          end
        end

        cls = symbolize_class_name(probe.type_name)
        serializer = self.serializer
        method_name = probe.method_name
        loc = begin
          cls.instance_method(method_name).source_location
        rescue NameError
          # The target method is not defined.
          # This could be because it will be explicitly defined later
          # (since classes can be reopened in Ruby)
          # or the method is virtual (provided by a method_missing handler).
          # In these cases we do not have a source location for the
          # target method here.
        end
        rate_limiter = probe.rate_limiter
        settings = self.settings

        mod = Module.new do
          define_method(method_name) do |*args, **kwargs, &target_block| # steep:ignore
            if rate_limiter.nil? || rate_limiter.allow?
              # Arguments may be mutated by the method, therefore
              # they need to be serialized prior to method invocation.
              serialized_entry_args = if probe.capture_snapshot?
                serializer.serialize_args(args, kwargs, self,
                  depth: probe.max_capture_depth || settings.dynamic_instrumentation.max_capture_depth,
                  attribute_count: probe.max_capture_attribute_count || settings.dynamic_instrumentation.max_capture_attribute_count)
              end
              start_time = Core::Utils::Time.get_time
              # Under Ruby 2.6 we cannot just call super(*args, **kwargs)
              # for methods defined via method_missing.
              rv = if args.any?
                if kwargs.any?
                  super(*args, **kwargs, &target_block)
                else
                  super(*args, &target_block)
                end
              elsif kwargs.any?
                super(**kwargs, &target_block)
              else
                super(&target_block)
              end
              duration = Core::Utils::Time.get_time - start_time
              # The method itself is not part of the stack trace because
              # we are getting the stack trace from outside of the method.
              # Add the method in manually as the top frame.
              method_frame = if loc
                [Location.new(loc.first, loc.last, method_name)]
              else
                # For virtual and lazily-defined methods, we do not have
                # the original source location here, and they won't be
                # included in the stack trace currently.
                # TODO when begin/end trace points are added for local
                # variable capture in method probes, we should be able
                # to obtain actual method execution location and use
                # that location here.
                []
              end
              caller_locs = method_frame + caller_locations # steep:ignore
              # TODO capture arguments at exit
              # & is to stop steep complaints, block is always present here.
              block&.call(probe: probe, rv: rv,
                duration: duration, caller_locations: caller_locs,
                target_self: self,
                serialized_entry_args: serialized_entry_args)
              rv
            else
              # stop standard from trying to mess up my code
              _ = 42

              # The necessity to invoke super in each of these specific
              # ways is very difficult to test.
              # Existing tests, even though I wrote many, still don't
              # cause a failure if I replace all of the below with a
              # simple super(*args, **kwargs, &target_block).
              # But, let's be safe and go through the motions in case
              # there is actually a legitimate need for the breakdown.
              # TODO figure out how to test this properly.
              if args.any?
                if kwargs.any?
                  super(*args, **kwargs, &target_block)
                else
                  super(*args, &target_block)
                end
              elsif kwargs.any?
                super(**kwargs, &target_block)
              else
                super(&target_block)
              end
            end
          end
        end

        lock.synchronize do
          if probe.instrumentation_module
            # Already instrumented from another thread
            return
          end

          probe.instrumentation_module = mod
          cls.send(:prepend, mod)
        end
      end

      def unhook_method(probe)
        # Ruby does not permit removing modules from classes.
        # We can, however, remove method definitions from modules.
        # After this the modules remain in memory and stay included
        # in the classes but are empty (have no methods).
        lock.synchronize do
          if mod = probe.instrumentation_module
            mod.send(:remove_method, probe.method_name)
            probe.instrumentation_module = nil
          end
        end
      end

      # Instruments a particluar line in a source file.
      # Note that this method only works for physical files,
      # not for eval'd code, unless the eval'd code is associated with
      # a file name and client invokes this method with the correct
      # file name for the eval'd code.
      def hook_line(probe, &block)
        unless block
          raise ArgumentError, 'No block given to hook_line'
        end

        lock.synchronize do
          if probe.instrumentation_trace_point
            # Already instrumented, warn?
            return
          end
        end

        line_no = probe.line_no!
        rate_limiter = probe.rate_limiter

        # Memoize the value to ensure this method always uses the same
        # value for the setting.
        # Normally none of the settings should change, but in the test suite
        # we use mock objects and the methods may be mocked with
        # individual invocations, yielding different return values on
        # different calls to the same method.
        permit_untargeted_trace_points = settings.dynamic_instrumentation.internal.untargeted_trace_points

        iseq = nil
        if code_tracker
          ret = code_tracker.iseqs_for_path_suffix(probe.file) # steep:ignore
          unless ret
            if permit_untargeted_trace_points
              # Continue withoout targeting the trace point.
              # This is going to cause a serious performance penalty for
              # the entire file containing the line to be instrumented.
            else
              # Do not use untargeted trace points unless they have been
              # explicitly requested by the user, since they cause a
              # serious performance penalty.
              #
              # If the requested file is not in code tracker's registry,
              # or the code tracker does not exist at all,
              # do not attempt to instrument now.
              # The caller should add the line to the list of pending lines
              # to instrument and install the hook when the file in
              # question is loaded (and hopefully, by then code tracking
              # is active, otherwise the line will never be instrumented.)
              raise_if_probe_in_loaded_features(probe)
              raise Error::DITargetNotDefined, "File not in code tracker registry: #{probe.file}"
            end
          end
        elsif !permit_untargeted_trace_points
          # Same as previous comment, if untargeted trace points are not
          # explicitly defined, and we do not have code tracking, do not
          # instrument the method.
          raise_if_probe_in_loaded_features(probe)
          raise Error::DITargetNotDefined, "File not in code tracker registry: #{probe.file}"
        end

        if ret
          actual_path, iseq = ret
        end

        # If trace point is not targeted, we only need one trace point per file.
        # Creating a trace point for each probe does work but the performance
        # penalty will be taken for each trace point defined in the file.
        # Since untargeted trace points are only (currently) used internally
        # for benchmarking, and shouldn't be used in customer applications,
        # we always create a trace point here to reduce complexity.
        #
        # For targeted trace points, if multiple probes target the same
        # file and line, we also only need one trace point, but since the
        # overhead of targeted trace points is minimal, don't worry about
        # this optimization just yet and create a trace point for each probe.

        types = if iseq
          # When targeting trace points we can target the 'end' line of a method.
          # However, by adding the :return trace point we lose diagnostics
          # for lines that contain no executable code (e.g. comments only)
          # and thus cannot actually be instrumented.
          [:line, :return, :b_return]
        else
          [:line]
        end
        tp = TracePoint.new(*types) do |tp|
          begin
            # If trace point is not targeted, we must verify that the invocation
            # is the file & line that we want, because untargeted trace points
            # are invoked for *each* line of Ruby executed.
            # TODO find out exactly when the path in trace point is relative.
            # Looks like this is the case when line trace point is not targeted?
            if iseq || tp.lineno == probe.line_no && (
              probe.file == tp.path || probe.file_matches?(tp.path)
            )
              if rate_limiter.nil? || rate_limiter.allow?
                serialized_locals = if probe.capture_snapshot?
                  serializer.serialize_vars(Instrumenter.get_local_variables(tp),
                    depth: probe.max_capture_depth || settings.dynamic_instrumentation.max_capture_depth,
                    attribute_count: probe.max_capture_attribute_count || settings.dynamic_instrumentation.max_capture_attribute_count,)
                end
                if probe.capture_snapshot?
                  serializer.serialize_value(tp.self,
                    depth: probe.max_capture_depth || settings.dynamic_instrumentation.max_capture_depth,
                    attribute_count: probe.max_capture_attribute_count || settings.dynamic_instrumentation.max_capture_attribute_count,)
                end
                # & is to stop steep complaints, block is always present here.
                block&.call(probe: probe,
                  serialized_locals: serialized_locals,
                  target_self: tp.self,
                  path: tp.path, caller_locations: caller_locations)
              end
            end
          rescue => exc
            raise if settings.dynamic_instrumentation.internal.propagate_all_exceptions
            logger.debug { "di: unhandled exception in line trace point: #{exc.class}: #{exc}" }
            telemetry&.report(exc, description: "Unhandled exception in line trace point")
            # TODO test this path
          end
        rescue => exc
          raise if settings.dynamic_instrumentation.internal.propagate_all_exceptions
          logger.debug { "di: unhandled exception in line trace point: #{exc.class}: #{exc}" }
          telemetry&.report(exc, description: "Unhandled exception in line trace point")
          # TODO test this path
        end

        # TODO internal check - remove or use a proper exception
        if !iseq && !permit_untargeted_trace_points
          raise "Trying to use an untargeted trace point when user did not permit it"
        end

        lock.synchronize do
          if probe.instrumentation_trace_point
            # Already instrumented in another thread, warn?
            return
          end

          probe.instrumentation_trace_point = tp
          # actual_path could be nil if we don't use targeted trace points.
          probe.instrumented_path = actual_path

          if iseq
            tp.enable(target: iseq, target_line: line_no)
          else
            tp.enable
          end
          # TracePoint#enable returns false when it succeeds.
        end
        true
      end

      def unhook_line(probe)
        lock.synchronize do
          if tp = probe.instrumentation_trace_point
            tp.disable
            probe.instrumentation_trace_point = nil
          end
        end
      end

      def hook(probe, &block)
        if probe.method?
          hook_method(probe, &block)
        elsif probe.line?
          hook_line(probe, &block)
        else
          # TODO add test coverage for this path
          logger.debug { "di: unknown probe type to hook: #{probe}" }
        end
      end

      def unhook(probe)
        if probe.method?
          unhook_method(probe)
        elsif probe.line?
          unhook_line(probe)
        else
          # TODO add test coverage for this path
          logger.debug { "di: unknown probe type to unhook: #{probe}" }
        end
      end

      class << self
        def get_local_variables(trace_point)
          # binding appears to be constructed on access, therefore
          # 1) we should attempt to cache it and
          # 2) we should not call +binding+ until we actually need variable values.
          binding = trace_point.binding

          # steep hack - should never happen
          return {} unless binding

          binding.local_variables.each_with_object({}) do |name, map|
            value = binding.local_variable_get(name)
            map[name] = value
          end
        end
      end

      private

      attr_reader :lock

      def raise_if_probe_in_loaded_features(probe)
        return unless probe.file

        # If the probe file is in the list of loaded files
        # (as per $LOADED_FEATURES, using either exact or suffix match),
        # raise an error indicating that
        # code tracker is missing the loaded file because the file
        # won't be loaded again (DI only works in production environments
        # that do not normally reload code).
        if $LOADED_FEATURES.include?(probe.file)
          raise Error::DITargetNotInRegistry, "File loaded but is not in code tracker registry: #{probe.file}"
        end
        # Ths is an expensive check
        $LOADED_FEATURES.each do |path|
          if Utils.path_matches_suffix?(path, probe.file)
            raise Error::DITargetNotInRegistry, "File matching probe path (#{probe.file}) was loaded and is not in code tracker registry: #{path}"
          end
        end
      end

      # TODO test that this resolves qualified names e.g. A::B
      def symbolize_class_name(cls_name)
        Object.const_get(cls_name)
      rescue NameError => exc
        raise Error::DITargetNotDefined, "Class not defined: #{cls_name}: #{exc.class}: #{exc}"
      end
    end
  end
end

# rubocop:enable Lint/AssignmentInCondition
