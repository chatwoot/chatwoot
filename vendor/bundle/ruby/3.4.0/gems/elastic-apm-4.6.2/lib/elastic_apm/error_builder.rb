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
  class ErrorBuilder
    def initialize(agent)
      @agent = agent
    end

    def build_exception(exception, context: nil, handled: true)
      error = Error.new context: context || Context.new
      error.exception =
        Error::Exception.from_exception(exception, handled: handled)

      Util.reverse_merge!(error.context.labels, @agent.config.default_labels)

      if exception.backtrace
        add_stacktrace error, :exception, exception.backtrace
      end

      add_current_transaction_fields error, ElasticAPM.current_transaction

      error
    end

    def build_log(message, context: nil, backtrace: nil, **attrs)
      error = Error.new context: context || Context.new
      error.log = Error::Log.new(message, **attrs)

      if backtrace
        add_stacktrace error, :log, backtrace
      end

      add_current_transaction_fields error, ElasticAPM.current_transaction

      error
    end

    private

    def add_stacktrace(error, kind, backtrace)
      stacktrace =
        @agent.stacktrace_builder.build(backtrace, type: :error)
      return unless stacktrace

      case kind
      when :exception
        error.exception.stacktrace = stacktrace
      when :log
        error.log.stacktrace = stacktrace
      end

      error.culprit = stacktrace.frames.first&.function
    end

    def add_current_transaction_fields(error, transaction)
      return unless transaction

      error.transaction_id = transaction.id
      error.transaction_name = transaction.name
      error.transaction = {
        sampled: transaction.sampled?,
        type: transaction.type
      }
      error.trace_id = transaction.trace_id
      error.parent_id = ElasticAPM.current_span&.id || transaction.id

      return unless transaction.context

      Util.reverse_merge!(error.context.labels, transaction.context.labels)
      Util.reverse_merge!(error.context.custom, transaction.context.custom)
    end
  end
end
