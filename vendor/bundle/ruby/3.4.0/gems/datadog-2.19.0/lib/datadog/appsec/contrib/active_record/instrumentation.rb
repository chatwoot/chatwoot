# frozen_string_literal: true

require_relative '../../event'
require_relative '../../security_event'

module Datadog
  module AppSec
    module Contrib
      module ActiveRecord
        # AppSec module that will be prepended to ActiveRecord adapter
        module Instrumentation
          module_function

          def detect_sql_injection(sql, adapter_name)
            return unless AppSec.rasp_enabled?

            context = AppSec.active_context
            return unless context

            # libddwaf expects db system to be lowercase,
            # in case of sqlite adapter, libddwaf expects 'sqlite' as db system
            db_system = adapter_name.downcase
            db_system = 'sqlite' if db_system == 'sqlite3'

            ephemeral_data = {
              'server.db.statement' => sql,
              'server.db.system' => db_system
            }

            waf_timeout = Datadog.configuration.appsec.waf_timeout
            result = context.run_rasp(Ext::RASP_SQLI, {}, ephemeral_data, waf_timeout)

            if result.match?
              AppSec::Event.tag_and_keep!(context, result)

              context.events.push(
                AppSec::SecurityEvent.new(result, trace: context.trace, span: context.span)
              )

              AppSec::ActionsHandler.handle(result.actions)
            end
          end

          # patch for mysql2, sqlite3, and postgres+jdbc adapters in ActiveRecord >= 7.1
          module InternalExecQueryAdapterPatch
            def internal_exec_query(sql, *args, **rest)
              Instrumentation.detect_sql_injection(sql, adapter_name)

              super
            end
          end

          # patch for mysql2, sqlite3, and postgres+jdbc adapters in ActiveRecord < 7.1
          module ExecQueryAdapterPatch
            def exec_query(sql, *args, **rest)
              Instrumentation.detect_sql_injection(sql, adapter_name)

              super
            end
          end

          # patch for mysql2, sqlite3, and postgres+jdbc db adapters in ActiveRecord 4
          module Rails4ExecQueryAdapterPatch
            def exec_query(sql, *args)
              Instrumentation.detect_sql_injection(sql, adapter_name)

              super
            end
          end

          # patch for non-jdbc postgres adapter in ActiveRecord > 4
          module ExecuteAndClearAdapterPatch
            def execute_and_clear(sql, *args, **rest)
              Instrumentation.detect_sql_injection(sql, adapter_name)

              super
            end
          end

          # patch for non-jdbc postgres adapter in ActiveRecord 4
          module Rails4ExecuteAndClearAdapterPatch
            def execute_and_clear(sql, name, binds)
              Instrumentation.detect_sql_injection(sql, adapter_name)

              super
            end
          end
        end
      end
    end
  end
end
