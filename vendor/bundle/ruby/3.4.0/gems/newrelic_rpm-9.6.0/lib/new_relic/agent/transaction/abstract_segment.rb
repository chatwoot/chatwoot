# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/guid_generator'

module NewRelic
  module Agent
    class Transaction
      class AbstractSegment
        # This class is the base class for all segments. It is responsible for
        # timing, naming, and defining lifecycle callbacks. One of the more
        # complex responsibilities of this class is computing exclusive duration.
        # One of the reasons for this complexity is that exclusive time will be
        # computed using time ranges or by recording an aggregate value for
        # a segments children time. The reason for this is that computing
        # exclusive duration using time ranges is expensive and it's only
        # necessary if a segment's children run concurrently, or a segment ends
        # after its parent. We will use the optimized exclusive duration
        # calculation in all other cases.
        #
        attr_reader :start_time, :end_time, :duration, :exclusive_duration, :guid, :starting_segment_key
        attr_accessor :name, :parent, :children_time, :transaction, :transaction_name
        attr_writer :record_metrics, :record_scoped_metric, :record_on_finish
        attr_reader :noticed_error

        CALLBACK = :@callback
        SEGMENT = 'segment'

        def initialize(name = nil, start_time = nil)
          @name = name
          @starting_segment_key = NewRelic::Agent::Tracer.current_segment_key
          @transaction_name = nil
          @transaction = nil
          @guid = NewRelic::Agent::GuidGenerator.generate_guid
          @parent = nil
          @params = nil
          @start_time = start_time if start_time
          @end_time = nil
          @duration = 0.0
          @exclusive_duration = 0.0
          @children_timings = []
          @children_time = 0.0
          @active_children = 0
          @range_recorded = false
          @concurrent_children = false
          @record_metrics = true
          @record_scoped_metric = true
          @record_on_finish = false
          @noticed_error = nil
          @code_filepath = nil
          @code_function = nil
          @code_lineno = nil
          @code_namespace = nil
          invoke_callback
        end

        def start
          @start_time ||= Process.clock_gettime(Process::CLOCK_REALTIME)
          return unless transaction

          parent&.child_start(self)
        end

        def finish
          @end_time = Process.clock_gettime(Process::CLOCK_REALTIME)
          @duration = end_time - start_time

          return unless transaction

          run_complete_callbacks
          finalize if record_on_finish?
        rescue => e
          NewRelic::Agent.logger.error("Exception finishing segment: #{name}", e)
        end

        def finished?
          !!@end_time
        end

        def record_metrics?
          @record_metrics
        end

        def record_scoped_metric?
          @record_scoped_metric
        end

        def record_on_finish?
          @record_on_finish
        end

        def finalize
          force_finish unless finished?
          record_exclusive_duration
          record_metrics if record_metrics?
        end

        def params
          @params ||= {}
        end

        def params?
          !!@params
        end

        def time_range
          @start_time.to_f..@end_time.to_f
        end

        def children_time_ranges?
          !@children_timings.empty?
        end

        def concurrent_children?
          @concurrent_children
        end

        def code_information=(info = {})
          return unless info[:filepath]

          @code_filepath = info[:filepath]
          @code_function = info[:function]
          @code_lineno = info[:lineno]
          @code_namespace = info[:namespace]
        end

        def all_code_information_present?
          @code_filepath && @code_function && @code_lineno && @code_namespace
        end

        def code_attributes
          return ::NewRelic::EMPTY_HASH unless all_code_information_present?

          @code_attributes ||= {'code.filepath' => @code_filepath,
                                'code.function' => @code_function,
                                'code.lineno' => @code_lineno,
                                'code.namespace' => @code_namespace}
        end

        INSPECT_IGNORE = [:@transaction, :@transaction_state].freeze

        def inspect
          ivars = (instance_variables - INSPECT_IGNORE).inject([]) do |memo, var_name|
            memo << "#{var_name}=#{instance_variable_get(var_name).inspect}"
          end
          sprintf('#<%s:0x%x %s>', self.class.name, object_id, ivars.join(', '))
        end

        # callback for subclasses to override
        def transaction_assigned
        end

        def set_noticed_error(noticed_error)
          if @noticed_error
            NewRelic::Agent.logger.debug( \
              "Segment: #{name} overwriting previously noticed " \
              "error: #{@noticed_error.inspect} with: #{noticed_error.inspect}"
            )
          end
          @noticed_error = noticed_error
        end

        def notice_error(exception, options = {})
          if Agent.config[:high_security]
            NewRelic::Agent.logger.debug( \
              "Segment: #{name} ignores notice_error for " \
              "error: #{exception.inspect} because :high_security is enabled"
            )
          else
            NewRelic::Agent.instance.error_collector.notice_segment_error(self, exception, options)
          end
        end

        def noticed_error_attributes
          return unless @noticed_error

          @noticed_error.attributes_from_notice_error
        end

        protected

        attr_writer :range_recorded

        def range_recorded?
          @range_recorded
        end

        def child_start(segment)
          @active_children += 1
          @concurrent_children ||= @active_children > 1

          transaction.async = true if @concurrent_children
        end

        def child_complete(segment)
          @active_children -= 1
          record_child_time(segment)

          if finished?
            transaction.async = true
            parent&.descendant_complete(self, segment)
          end
        end

        # When a child segment completes after its parent, we need to propagate
        # the information about the descendant further up the tree so that
        # ancestors can properly account for exclusive time. Once we've reached
        # an ancestor whose end time is greater than or equal to the descendant's
        # we can stop the propagation. We pass along the direct child so we can
        # make any corrections needed for exclusive time calculation.
        def descendant_complete(child, descendant)
          add_child_timing(descendant)

          # If this child's time was previously added to this segment's
          # aggregate children time, we need to re-record it using a time range
          # for proper exclusive time calculation
          unless child.range_recorded?
            self.children_time -= child.duration
            record_child_time_as_range(child)
          end

          if parent && finished? && descendant.end_time >= end_time
            parent.descendant_complete(self, descendant)
          end
        end

        private

        def add_child_timing(segment)
          @children_timings << [segment.start_time, segment.end_time]
        end

        def force_finish
          finish
          NewRelic::Agent.logger.send(transaction.async? ? :debug : :warn, "Segment: #{name} was unfinished at " \
            "the end of transaction. Timing information for this segment's " \
            "parent #{parent&.name} in #{transaction.best_name} may be inaccurate.")
        end

        def run_complete_callbacks
          segment_complete
          parent&.child_complete(self)
          transaction.segment_complete(self)
        end

        def record_metrics
          raise NotImplementedError, 'Subclasses must implement record_metrics'
        end

        # callback for subclasses to override
        def segment_complete
        end

        def record_child_time(child)
          if concurrent_children? || finished? && end_time < child.end_time
            record_child_time_as_range(child)
          else
            record_child_time_as_number(child)
          end
        end

        def record_child_time_as_range(child)
          add_child_timing(child)
          child.range_recorded = true
        end

        def record_child_time_as_number(child)
          self.children_time += child.duration
        end

        def record_exclusive_duration
          @exclusive_duration = duration - children_time - overlapping_duration
          transaction.total_time += @exclusive_duration
          params[:exclusive_duration_millis] = @exclusive_duration * 1000 if transaction.async?
        end

        def metric_cache
          transaction.metrics
        end

        def ranges_intersect?(r1, r2)
          r1.begin > r2.begin ? r2.cover?(r1.begin) : r1.cover?(r2.begin)
        end

        def range_overlap(range)
          return 0.0 unless ranges_intersect?(range, time_range)

          [range.end, time_range.end].min - [range.begin, time_range.begin].max
        end

        # Child segments operating concurrently with this segment may have
        # start and end times that overlap with this segment's own times. The
        # amount of overlap needs to be removed from the `children_time` total
        # when calculating an `@exclusive_duration` value to be added to the
        # transaction's total time.
        #
        # If there aren't any child segments, return 0.0. Otherwise, take the
        # `@children_timings` array of arrays (each array holds a child
        # segment's start time and end time), sort it by the first elements
        # (start times), and use the start and finish times to create Range
        # objects. Combine all of the child segment ranges that overlap with
        # one another into new bigger ranges. Then take those bigger ranges
        # and calculate how much overlap there is between them and this
        # segment's own time range. Keep a running sum of all of the overlap
        # amounts and then return it.
        def overlapping_duration
          sum = 0.0
          return sum unless children_time_ranges?

          @children_timings.sort_by!(&:first)
          range = Range.new(*@children_timings.first)
          (1..(@children_timings.size - 1)).each do |i|
            possible = Range.new(*@children_timings[i])

            if ranges_intersect?(range, possible)
              range = range.begin..possible.end
            else
              sum += range_overlap(range)
              range = possible
            end
          end

          sum += range_overlap(range)
        end

        def transaction_state
          @transaction_state ||= if @transaction
            transaction.state
          else
            Tracer.state
          end
        end

        # for segment callback usage info, see self.set_segment_callback
        def invoke_callback
          return unless self.class.instance_variable_defined?(CALLBACK)

          NewRelic::Agent.logger.debug("Invoking callback for #{self.class.name}...")
          self.class.instance_variable_get(CALLBACK).call
        rescue Exception => e
          NewRelic::Agent.logger.error("Error encountered while invoking callback for #{self.class.name}: " +
                                       "#{e.class} - #{e.message}")
        end

        # Setting and invoking a segment callback
        # =======================================
        # Each individual segment class such as `ExternalRequestSegment` allows
        # for exactly one instance of a `Proc` (meaning a proc or lambda) to be
        # set as a callback. A callback can be set on a segment class by calling
        # `.set_segment_callback` with a proc or lambda as the only argument.
        # If set, the callback will be invoked with `#call` at segment class
        # initialization time.
        #
        # Example usage:
        #   callback = -> { puts 'Hello, World! }
        #   ExternalRequestSegment.set_segment_callback(callback)
        #   ExternalRequestSegment.new(library, uri, procedure)
        #
        # A callback set on a segment class will only be called when that
        # specific segment class is initialized. Other segment classes will not
        # be impacted.
        #
        # Great caution should be taken in the defining of the callback block
        # to not have the block perform anything too time consuming or resource
        # intensive in order to keep the New Relic Ruby agent operating
        # normally.
        #
        # Given that callbacks are user defined, they must be set entirely at
        # the user's own risk. It is recommended that each callback use
        # conditional logic that only performs work for certain qualified
        # segments. It is recommended that each callback be thoroughly tested
        # in non-production environments before being introduced to production
        # environments.
        def self.set_segment_callback(callback_proc)
          unless callback_proc.is_a?(Proc)
            NewRelic::Agent.logger.error("#{self}.#{__method__}: expected an argument of type Proc, " \
                                         "got #{callback_proc.class}")
            return
          end

          NewRelic::Agent.record_api_supportability_metric(:set_segment_callback)
          instance_variable_set(CALLBACK, callback_proc)
        end
      end
    end
  end
end
