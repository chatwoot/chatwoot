# frozen_string_literal: true

require_relative '../../metadata/ext'
require_relative '../analytics'
require_relative '../ext'
require_relative 'ext'

require_relative '../propagation/sql_comment'
require_relative '../propagation/sql_comment/mode'

module Datadog
  module Tracing
    module Contrib
      module Pg
        # PG::Connection patch module
        module Instrumentation
          def self.included(base)
            base.prepend(InstanceMethods)
          end

          # PG::Connection patch methods
          module InstanceMethods
            def exec(sql, *args, &block)
              return super unless enabled?

              trace(Ext::SPAN_EXEC, sql: sql, block: block) do |sql_statement, wrapped_block|
                super(sql_statement, *args, &wrapped_block)
              end
            end

            def exec_params(sql, params, *args, &block)
              return super unless enabled?

              trace(Ext::SPAN_EXEC_PARAMS, sql: sql, block: block) do |sql_statement, wrapped_block|
                super(sql_statement, params, *args, &wrapped_block)
              end
            end

            def exec_prepared(statement_name, params, *args, &block)
              return super unless enabled?

              trace(Ext::SPAN_EXEC_PREPARED, statement_name: statement_name, block: block) do |_, wrapped_block|
                super(statement_name, params, *args, &wrapped_block)
              end
            end

            # async_exec is an alias to exec
            def async_exec(sql, *args, &block)
              return super unless enabled?

              trace(Ext::SPAN_ASYNC_EXEC, sql: sql, block: block) do |sql_statement, wrapped_block|
                super(sql_statement, *args, &wrapped_block)
              end
            end

            # async_exec_params is an alias to exec_params
            def async_exec_params(sql, params, *args, &block)
              return super unless enabled?

              trace(Ext::SPAN_ASYNC_EXEC_PARAMS, sql: sql, block: block) do |sql_statement, wrapped_block|
                super(sql_statement, params, *args, &wrapped_block)
              end
            end

            # async_exec_prepared is an alias to exec_prepared
            def async_exec_prepared(statement_name, params, *args, &block)
              return super unless enabled?

              trace(Ext::SPAN_ASYNC_EXEC_PREPARED, statement_name: statement_name, block: block) do |_, wrapped_block|
                super(statement_name, params, *args, &wrapped_block)
              end
            end

            def sync_exec(sql, *args, &block)
              return super unless enabled?

              trace(Ext::SPAN_SYNC_EXEC, sql: sql, block: block) do |sql_statement, wrapped_block|
                super(sql_statement, *args, &wrapped_block)
              end
            end

            def sync_exec_params(sql, params, *args, &block)
              return super unless enabled?

              trace(Ext::SPAN_SYNC_EXEC_PARAMS, sql: sql, block: block) do |sql_statement, wrapped_block|
                super(sql_statement, params, *args, &wrapped_block)
              end
            end

            def sync_exec_prepared(statement_name, params, *args, &block)
              return super unless enabled?

              trace(Ext::SPAN_SYNC_EXEC_PREPARED, statement_name: statement_name, block: block) do |_, wrapped_block|
                super(statement_name, params, *args, &wrapped_block)
              end
            end

            private

            def trace(name, sql: nil, statement_name: nil, block: nil)
              service = Datadog.configuration_for(self, :service_name) || datadog_configuration[:service_name]
              on_error = datadog_configuration[:on_error]
              resource = statement_name || sql

              Tracing.trace(
                name,
                on_error: on_error,
                service: service,
                resource: resource,
                type: Tracing::Metadata::Ext::SQL::TYPE
              ) do |span, trace_op|
                annotate_span_with_query!(span, service)
                # Set analytics sample rate
                Contrib::Analytics.set_sample_rate(span, analytics_sample_rate) if analytics_enabled?

                if sql
                  propagation_mode = Contrib::Propagation::SqlComment::Mode.new(
                    comment_propagation,
                    datadog_configuration[:append_comment]
                  )
                  Contrib::Propagation::SqlComment.annotate!(span, propagation_mode)
                  propagated_sql_statement = Contrib::Propagation::SqlComment.prepend_comment(
                    sql,
                    span,
                    trace_op,
                    propagation_mode
                  )
                end

                # Read metadata from PG::Result
                #
                # It is important to guard with `nil` check, because it is possible
                # the result is `nil` instead of `PG::Result`.
                #
                # A non-null pointer will generally be returned except in out-of-memory conditions or
                # serious errors such as inability to send the command to the server.
                #
                # see: https://www.postgresql.org/docs/current/libpq-exec.html#LIBPQ-PQEXEC
                if block
                  yield(propagated_sql_statement, proc do |result|
                    annotate_span_with_result!(span, result) if result
                    block.call(result)
                  end)
                else
                  result = yield(propagated_sql_statement)
                  annotate_span_with_result!(span, result) if result
                  result
                end
              end
            end

            def annotate_span_with_query!(span, service)
              span.set_tag(Ext::TAG_DB_NAME, db)

              if datadog_configuration[:peer_service]
                span.set_tag(
                  Tracing::Metadata::Ext::TAG_PEER_SERVICE,
                  datadog_configuration[:peer_service]
                )
              end

              # Tag original global service name if not used
              if span.service != Datadog.configuration.service
                span.set_tag(Tracing::Contrib::Ext::Metadata::TAG_BASE_SERVICE, Datadog.configuration.service)
              end

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_QUERY)
              span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_CLIENT)

              span.set_tag(Tracing::Metadata::Ext::TAG_PEER_HOSTNAME, host)

              span.set_tag(Contrib::Ext::DB::TAG_INSTANCE, db)
              span.set_tag(Contrib::Ext::DB::TAG_USER, user)
              span.set_tag(Contrib::Ext::DB::TAG_SYSTEM, Ext::TAG_SYSTEM)

              span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_HOST, host)
              span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_PORT, port)
              span.set_tag(Tracing::Metadata::Ext::NET::TAG_DESTINATION_NAME, host)
              span.set_tag(Tracing::Metadata::Ext::NET::TAG_DESTINATION_PORT, port)

              Contrib::SpanAttributeSchema.set_peer_service!(span, Ext::PEER_SERVICE_SOURCES)
            end

            # @param [PG::Result] result
            def annotate_span_with_result!(span, result)
              span.set_tag(Contrib::Ext::DB::TAG_ROW_COUNT, result.ntuples)
            end

            def datadog_configuration
              Datadog.configuration.tracing[:pg]
            end

            def analytics_enabled?
              datadog_configuration[:analytics_enabled]
            end

            def analytics_sample_rate
              datadog_configuration[:analytics_sample_rate]
            end

            def comment_propagation
              datadog_configuration[:comment_propagation]
            end

            def enabled?
              datadog_configuration[:enabled]
            end
          end
        end
      end
    end
  end
end
