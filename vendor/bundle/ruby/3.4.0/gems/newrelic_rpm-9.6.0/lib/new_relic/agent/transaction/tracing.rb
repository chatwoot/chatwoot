# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    class Transaction
      module Tracing
        attr_reader :current_segment_by_thread

        def async?
          @async ||= false
        end

        attr_writer :async

        def total_time
          @total_time ||= 0.0
        end

        attr_writer :total_time

        def add_segment(segment, parent = nil)
          segment.transaction = self
          segment.parent = parent || current_segment
          set_current_segment(segment)
          if @segments.length < segment_limit
            @segments << segment
          else
            segment.record_on_finish = true
            ::NewRelic::Agent.logger.debug("Segment limit of #{segment_limit} reached, ceasing collection.")

            if finished?
              ::NewRelic::Agent.logger.debug("Transaction #{best_name} has finished but segments still being created, resetting state.")
              NewRelic::Agent::Tracer.state.reset
              NewRelic::Agent.record_metric('Supportability/Transaction/SegmentLimitReachedAfterFinished/ResetState', 1)
            end
          end
          segment.transaction_assigned
        end

        def segment_complete(segment)
          # if parent was in another thread, remove the current_segment entry for this thread
          if segment.parent && segment.parent.starting_segment_key != NewRelic::Agent::Tracer.current_segment_key
            remove_current_segment_by_thread_id(NewRelic::Agent::Tracer.current_segment_key)
          else
            set_current_segment(segment.parent)
          end
        end

        def segment_limit
          Agent.config[:'transaction_tracer.limit_segments']
        end

        private

        def finalize_segments
          segments.each { |s| s.finalize }
        end

        WEB_TRANSACTION_TOTAL_TIME = 'WebTransactionTotalTime'.freeze
        OTHER_TRANSACTION_TOTAL_TIME = 'OtherTransactionTotalTime'.freeze

        def record_total_time_metrics
          total_time_metric = if recording_web_transaction?
            WEB_TRANSACTION_TOTAL_TIME
          else
            OTHER_TRANSACTION_TOTAL_TIME
          end

          @metrics.record_unscoped(total_time_metric, total_time)
          @metrics.record_unscoped("#{total_time_metric}/#{@frozen_name}", total_time)
        end
      end
    end
  end
end
