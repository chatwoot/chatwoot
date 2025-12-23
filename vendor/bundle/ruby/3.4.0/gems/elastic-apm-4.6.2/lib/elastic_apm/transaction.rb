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

module ElasticAPM
  # @api private
  class Transaction
    # @api private
    class Outcome
      FAILURE = "failure"
      SUCCESS = "success"
      UNKNOWN = "unknown"

      def self.from_http_status(code)
        code.to_i >= 500 ? FAILURE : SUCCESS
      end
    end

    extend Forwardable
    include ChildDurations::Methods

    def_delegators :@trace_context,
      :trace_id, :parent_id, :id, :ensure_parent_id

    DEFAULT_TYPE = 'custom'
    MUTEX = Mutex.new

    # rubocop:disable Metrics/ParameterLists
    def initialize(
      name = nil,
      type = nil,
      config:,
      sampled: true,
      sample_rate: 1,
      context: nil,
      trace_context: nil
    )
      @name = name
      @type = type || DEFAULT_TYPE
      @config = config

      # Cache these values in case they are changed during the
      # transaction's lifetime via the remote config
      @span_frames_min_duration = config.span_frames_min_duration
      @collect_metrics = config.collect_metrics?
      @breakdown_metrics = config.breakdown_metrics?
      @framework_name = config.framework_name
      @transaction_max_spans = config.transaction_max_spans
      @default_labels = config.default_labels

      @sampled = sampled
      @sample_rate = sample_rate

      @context = context || Context.new # TODO: Lazy generate this?
      if @default_labels
        Util.reverse_merge!(@context.labels, @default_labels)
      end

      unless (@trace_context = trace_context)
        @trace_context = TraceContext.new(
          traceparent: TraceContext::Traceparent.new(recorded: sampled),
          tracestate: TraceContext::Tracestate.new(
            sample_rate: sampled ? sample_rate : 0
          )
        )
      end

      @started_spans = 0
      @dropped_spans = 0

      @notifications = [] # for AS::Notifications
    end
    # rubocop:enable Metrics/ParameterLists

    attr_accessor :name, :type, :result, :outcome

    attr_reader(
      :breakdown_metrics,
      :collect_metrics,
      :context,
      :dropped_spans,
      :duration,
      :framework_name,
      :notifications,
      :self_time,
      :sample_rate,
      :span_frames_min_duration,
      :started_spans,
      :timestamp,
      :trace_context,
      :transaction_max_spans
    )

    alias :collect_metrics? :collect_metrics

    def sampled?
      @sampled
    end

    def stopped?
      !!duration
    end

    # life cycle

    def start(clock_start = Util.monotonic_micros)
      @timestamp = Util.micros
      @clock_start = clock_start
      self
    end

    def stop(clock_end = Util.monotonic_micros)
      raise 'Transaction not yet start' unless timestamp
      @duration = clock_end - @clock_start
      @self_time = @duration - child_durations.duration

      self
    end

    def done(result = nil, clock_end: Util.monotonic_micros)
      stop clock_end
      self.result = result if result
      self
    end

    # spans

    def inc_started_spans!
      MUTEX.synchronize do
        @started_spans += 1
        if @started_spans > transaction_max_spans
          @dropped_spans += 1
          return false
        end
      end
      true
    end

    # context

    def add_response(status = nil, **args)
      context.response = Context::Response.new(status, **args)
    end

    def set_user(user)
      context.user = Context::User.infer(@config, user)
    end

    def inspect
      "<ElasticAPM::Transaction id:#{id}" \
        " name:#{name.inspect} type:#{type.inspect}>"
    end
  end
end
