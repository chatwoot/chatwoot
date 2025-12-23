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

require 'elastic_apm/span/context'

module ElasticAPM
  # @api private
  class Span
    extend Forwardable
    include ChildDurations::Methods

    # @api private
    class Outcome
      FAILURE = "failure"
      SUCCESS = "success"
      UNKNOWN = "unknown"

      def self.from_http_status(code)
        code.to_i >= 400 ? FAILURE : SUCCESS
      end
    end

    DEFAULT_TYPE = 'custom'

    # rubocop:disable Metrics/ParameterLists
    def initialize(
      name:,
      transaction:,
      trace_context:,
      parent:,
      type: nil,
      subtype: nil,
      action: nil,
      context: nil,
      stacktrace_builder: nil,
      sync: nil,
      exit_span: false
    )
      @name = name

      if subtype.nil? && type&.include?('.')
        @type, @subtype, @action = type.split('.')
      else
        @type = type || DEFAULT_TYPE
        @subtype = subtype
        @action = action
      end

      @transaction = transaction
      @parent = parent
      @trace_context = trace_context || parent.trace_context.child
      @sample_rate = transaction.sample_rate

      @context = context || Span::Context.new(sync: sync)
      @stacktrace_builder = stacktrace_builder

      @exit_span = exit_span
    end
    # rubocop:enable Metrics/ParameterLists

    def_delegators :@trace_context, :trace_id, :parent_id, :id

    attr_accessor(
      :action,
      :exit_span,
      :name,
      :original_backtrace,
      :outcome,
      :subtype,
      :trace_context,
      :type
    )
    attr_reader(
      :context,
      :duration,
      :parent,
      :sample_rate,
      :self_time,
      :stacktrace,
      :timestamp,
      :transaction
    )

    alias :exit_span? :exit_span

    # life cycle

    def start(clock_start = Util.monotonic_micros)
      @timestamp = Util.micros
      @clock_start = clock_start
      @parent.child_started
      self
    end

    def stop(clock_end = Util.monotonic_micros)
      @duration ||= (clock_end - @clock_start)
      @parent.child_stopped
      @self_time = @duration - child_durations.duration

      self
    end

    def done(clock_end: Util.monotonic_micros)
      stop clock_end
      self
    end

    def prepare_for_serialization!
      build_stacktrace! if should_build_stacktrace?
      self.original_backtrace = nil # release original
    end

    def stopped?
      !!duration
    end

    def started?
      !!timestamp
    end

    def running?
      started? && !stopped?
    end

    def set_destination(address: nil, port: nil, service: nil, cloud: nil)
      context.destination = Span::Context::Destination.new(
        address: address,
        port: port,
        service: service,
        cloud: cloud
      )
      context.service = Span::Context::Service.new(
        target: Span::Context::Service::Target.new(name: context.destination.service.name, type: context.destination.service.type )
      )
    end

    def inspect
      "<ElasticAPM::Span id:#{trace_context&.id}" \
        " name:#{name.inspect}" \
        " type:#{type.inspect}" \
        " subtype:#{subtype.inspect}" \
        " action:#{action.inspect}" \
        " exit_span:#{exit_span.inspect}" \
        '>'
    end

    private

    def build_stacktrace!
      @stacktrace = @stacktrace_builder.build(original_backtrace, type: :span)
    end

    def should_build_stacktrace?
      @stacktrace_builder && original_backtrace && long_enough_for_stacktrace?
    end

    def long_enough_for_stacktrace?
      min_duration =
        @stacktrace_builder.config.span_frames_min_duration_us

      return true if min_duration < 0
      return false if min_duration == 0

      duration >= min_duration
    end
  end
end
