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

require 'elastic_apm/trace_context'
require 'elastic_apm/child_durations'
require 'elastic_apm/span'
require 'elastic_apm/transaction'
require 'elastic_apm/span_helpers'

module ElasticAPM
  # @api private
  class Instrumenter
    TRANSACTION_KEY = :__elastic_instrumenter_transaction_key
    SPAN_KEY = :__elastic_instrumenter_spans_key

    include Logging

    # @api private
    class Current
      def initialize
        self.transaction = nil
        self.spans = []
      end

      def transaction
        Thread.current[TRANSACTION_KEY]
      end

      def transaction=(transaction)
        Thread.current[TRANSACTION_KEY] = transaction
      end

      def spans
        Thread.current[SPAN_KEY] ||= []
      end

      def spans=(spans)
        Thread.current[SPAN_KEY] ||= []
        Thread.current[SPAN_KEY] = spans
      end
    end

    def initialize(config, metrics:, stacktrace_builder:, &enqueue)
      @config = config
      @stacktrace_builder = stacktrace_builder
      @enqueue = enqueue
      @metrics = metrics

      @current = Current.new
    end

    attr_reader :stacktrace_builder, :enqueue

    def start
      debug 'Starting instrumenter'
      # We call register! on @subscriber in case the
      # instrumenter was stopped and started again
      @subscriber&.register!
    end

    def stop
      debug 'Stopping instrumenter'

      self.current_transaction = nil
      current_spans.pop until current_spans.empty?

      @subscriber&.unregister!
    end

    def handle_forking!
      stop
      start
    end

    def subscriber=(subscriber)
      debug 'Registering ActiveSupport::Notifications subscriber'
      @subscriber = subscriber
      @subscriber.register!
    end

    # transactions

    def current_transaction
      @current.transaction
    end

    def current_transaction=(transaction)
      @current.transaction = transaction
    end

    def start_transaction(
      name = nil,
      type = nil,
      config:,
      context: nil,
      trace_context: nil
    )
      return nil unless config.instrument?

      if (transaction = current_transaction)
        raise ExistingTransactionError,
          "Transactions may not be nested.\n" \
          "Already inside #{transaction.inspect}"
      end

      if trace_context
        sampled = trace_context.recorded?
        sample_rate = trace_context.tracestate.sample_rate
      else
        sampled = random_sample?(config)
        sample_rate = sampled ? config.transaction_sample_rate : 0
      end

      transaction =
        Transaction.new(
          name,
          type,
          context: context,
          trace_context: trace_context,
          sampled: sampled,
          sample_rate: sample_rate,
          config: config
        )

      transaction.start

      self.current_transaction = transaction
    end

    def end_transaction(result = nil)
      return nil unless (transaction = current_transaction)

      self.current_transaction = nil

      transaction.done result

      if transaction.sampled? || @config.version < Config::ServerInfo::VERSION_8_0
        enqueue.call transaction
      end

      update_transaction_metrics(transaction)

      transaction
    end

    # spans

    def current_spans
      @current.spans
    end

    def current_span
      current_spans.last
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/ParameterLists
    def start_span(
      name,
      type = nil,
      subtype: nil,
      action: nil,
      backtrace: nil,
      context: nil,
      trace_context: nil,
      parent: nil,
      sync: nil,
      exit_span: nil
    )

      transaction =
        case parent
        when Span
          parent.transaction
        when Transaction
          parent
        else
          current_transaction
        end
      return unless transaction
      return unless transaction.sampled?
      return unless transaction.inc_started_spans!

      parent ||= (current_span || current_transaction)

      # To not mess with breakdown metric stats, exit spans MUST not add
      # sub-spans unless they share the same type and subtype.
      if parent && parent.is_a?(Span) && parent.exit_span?
        if parent.type != type || parent.subtype != subtype
          debug "Skipping new span '#{name}' as its parent is an exit_span"
          return
        end
      end

      span = Span.new(
        name: name,
        subtype: subtype,
        action: action,
        transaction: transaction,
        parent: parent,
        trace_context: trace_context,
        type: type,
        context: context,
        stacktrace_builder: stacktrace_builder,
        sync: sync,
        exit_span: exit_span
      )

      if backtrace && transaction.span_frames_min_duration
        span.original_backtrace = backtrace
      end

      current_spans.push span

      span.start
    end
    # rubocop:enable Metrics/ParameterLists
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def end_span(span = nil)
      if span
        current_spans.delete(span)
      else
        span = current_spans.pop
      end

      return unless span

      span.done

      enqueue.call span

      update_span_metrics(span)

      span
    end

    # metadata

    def set_label(key, value)
      return unless current_transaction

      key = key.to_s.gsub(/[."*]/, '_').to_sym
      current_transaction.context.labels[key] = value
    end

    def set_custom_context(context)
      return unless current_transaction
      current_transaction.context.custom.merge!(context)
    end

    def set_user(user)
      return unless current_transaction
      current_transaction.set_user(user)
    end

    def inspect
      '<ElasticAPM::Instrumenter ' \
        "current_transaction=#{current_transaction.inspect}" \
        '>'
    end

    private

    def random_sample?(config)
      rand <= config.transaction_sample_rate
    end

    def update_transaction_metrics(transaction)
      return unless transaction.collect_metrics?

      tags = {
        'transaction.name': transaction.name,
        'transaction.type': transaction.type
      }

      return unless transaction.sampled?
      return unless transaction.breakdown_metrics

      span_tags = tags.merge('span.type': 'app')

      @metrics.get(:breakdown).timer(
        :'span.self_time.sum.us',
        tags: span_tags, reset_on_collect: true
      ).update(transaction.self_time)

      @metrics.get(:breakdown).counter(
        :'span.self_time.count',
        tags: span_tags, reset_on_collect: true
      ).inc!
    end

    def update_span_metrics(span)
      return unless span.transaction.collect_metrics?

      tags = {
        'span.type': span.type,
        'transaction.name': span.transaction.name,
        'transaction.type': span.transaction.type
      }

      tags[:'span.subtype'] = span.subtype if span.subtype

      @metrics.get(:breakdown).timer(
        :'span.self_time.sum.us',
        tags: tags, reset_on_collect: true
      ).update(span.self_time)

      @metrics.get(:breakdown).counter(
        :'span.self_time.count',
        tags: tags, reset_on_collect: true
      ).inc!
    end
  end
end
