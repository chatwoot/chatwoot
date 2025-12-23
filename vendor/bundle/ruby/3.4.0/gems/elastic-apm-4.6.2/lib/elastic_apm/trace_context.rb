# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# frozen_string_literal: true

require 'elastic_apm/trace_context/tracestate'
require 'elastic_apm/trace_context/traceparent'

module ElasticAPM
  # @api private
  class TraceContext
    extend Forwardable

    class InvalidTraceparentHeader < StandardError; end

    def initialize(
      traceparent: nil,
      tracestate: nil
    )
      @traceparent = traceparent || Traceparent.new
      @tracestate = tracestate || Tracestate.new
    end

    attr_accessor :traceparent, :tracestate

    def_delegators :traceparent,
      :version, :trace_id, :id, :parent_id, :ensure_parent_id, :recorded?

    class << self
      def parse(env: nil, metadata: nil)
        unless env || metadata
          raise ArgumentError, 'TraceContext expects env:, metadata: ' \
            'or single argument header string'
        end

        if env
          trace_context_from_env(env)
        elsif metadata
          trace_context_from_metadata(metadata)
        end
      end

      private

      def trace_context_from_env(env)
        return unless (
          header =
            env['HTTP_ELASTIC_APM_TRACEPARENT'] || env['HTTP_TRACEPARENT']
        )

        parent = TraceContext::Traceparent.parse(header)

        state =
          if (header = env['HTTP_TRACESTATE'])
            TraceContext::Tracestate.parse(header)
          end

        new(traceparent: parent, tracestate: state)
      end

      def trace_context_from_metadata(metadata)
        return unless (header = metadata['elastic-apm-traceparent'] ||
          metadata['traceparent'])

        parent = TraceContext::Traceparent.parse(header)

        state =
          if (header = metadata['tracestate'])
            TraceContext::Tracestate.parse(header)
          end

        new(traceparent: parent, tracestate: state)
      end
    end

    def child
      dup.tap do |tc|
        tc.traceparent = tc.traceparent.child
      end
    end

    def apply_headers
      yield 'Traceparent', traceparent.to_header

      if tracestate && !tracestate.to_header.empty?
        yield 'Tracestate', tracestate.to_header
      end

      return unless ElasticAPM.agent.config.use_elastic_traceparent_header

      yield 'Elastic-Apm-Traceparent', traceparent.to_header
    end
  end
end
