# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/helper'
require 'new_relic/agent/transaction/trace'
require 'new_relic/agent/transaction/trace_node'

module NewRelic
  module Agent
    class Transaction
      module TraceBuilder
        extend self

        def build_trace(transaction)
          trace = Trace.new(transaction.start_time)
          trace.root_node.exit_timestamp = transaction.end_time - transaction.start_time
          copy_attributes(transaction, trace)
          first, *rest = transaction.segments
          relationship_map = rest.group_by { |s| s.parent }
          trace.root_node.children << process_segments(transaction, first, trace.root_node, relationship_map)
          trace
        end

        private

        # recursively builds a transaction trace from the flat list of segments
        def process_segments(transaction, segment, parent, relationship_map)
          current = create_trace_node(transaction, segment, parent)

          if children = relationship_map[segment]
            current.children = children.map! do |child|
              process_segments(transaction, child, current, relationship_map)
            end
          end

          current
        end

        def create_trace_node(transaction, segment, parent)
          relative_start = segment.start_time - transaction.start_time
          relative_end = segment.end_time - transaction.start_time
          TraceNode.new(segment.name, relative_start, relative_end, segment.params, parent)
        end

        def copy_attributes(transaction, trace)
          trace.transaction_name = transaction.best_name
          trace.guid = transaction.guid
          trace.attributes = transaction.attributes
          trace.threshold = transaction.threshold
          trace.finished = true
        end
      end
    end
  end
end
