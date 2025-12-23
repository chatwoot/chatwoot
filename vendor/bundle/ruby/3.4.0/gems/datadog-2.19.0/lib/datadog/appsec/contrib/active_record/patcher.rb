# frozen_string_literal: true

require_relative 'instrumentation'

module Datadog
  module AppSec
    module Contrib
      module ActiveRecord
        # AppSec patcher module for ActiveRecord
        module Patcher
          module_function

          def patched?
            Patcher.instance_variable_get(:@patched)
          end

          def target_version
            Integration.version
          end

          def patch
            # Rails 7.0 intruduced new on-load hooks for sqlite3 and postgresql adapters
            # The load hook for mysql2 adapter was introduced in Rails 7.1
            #
            # If the adapter is not loaded when the :active_record load hook is called,
            # we need to add a load hook for the adapter
            ActiveSupport.on_load :active_record do
              if defined?(::ActiveRecord::ConnectionAdapters::SQLite3Adapter)
                ::Datadog::AppSec::Contrib::ActiveRecord::Patcher.patch_sqlite3_adapter
              else
                ActiveSupport.on_load :active_record_sqlite3adapter do
                  ::Datadog::AppSec::Contrib::ActiveRecord::Patcher.patch_sqlite3_adapter
                end
              end

              if defined?(::ActiveRecord::ConnectionAdapters::Mysql2Adapter)
                ::Datadog::AppSec::Contrib::ActiveRecord::Patcher.patch_mysql2_adapter
              else
                ActiveSupport.on_load :active_record_mysql2adapter do
                  ::Datadog::AppSec::Contrib::ActiveRecord::Patcher.patch_mysql2_adapter
                end
              end

              if defined?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
                ::Datadog::AppSec::Contrib::ActiveRecord::Patcher.patch_postgresql_adapter
              else
                ActiveSupport.on_load :active_record_postgresqladapter do
                  ::Datadog::AppSec::Contrib::ActiveRecord::Patcher.patch_postgresql_adapter
                end
              end
            end
          end

          def patch_sqlite3_adapter
            instrumentation_module = if ::ActiveRecord.gem_version >= Gem::Version.new('7.1')
              Instrumentation::InternalExecQueryAdapterPatch
            elsif ::ActiveRecord.gem_version.segments.first == 4
              Instrumentation::Rails4ExecQueryAdapterPatch
            else
              Instrumentation::ExecQueryAdapterPatch
            end

            ::ActiveRecord::ConnectionAdapters::SQLite3Adapter.prepend(instrumentation_module)
          end

          def patch_mysql2_adapter
            instrumentation_module = if ::ActiveRecord.gem_version >= Gem::Version.new('7.1')
              Instrumentation::InternalExecQueryAdapterPatch
            elsif ::ActiveRecord.gem_version.segments.first == 4
              Instrumentation::Rails4ExecQueryAdapterPatch
            else
              Instrumentation::ExecQueryAdapterPatch
            end

            ::ActiveRecord::ConnectionAdapters::Mysql2Adapter.prepend(instrumentation_module)
          end

          def patch_postgresql_adapter
            instrumentation_module = if ::ActiveRecord.gem_version.segments.first == 4
              Instrumentation::Rails4ExecuteAndClearAdapterPatch
            else
              Instrumentation::ExecuteAndClearAdapterPatch
            end

            if defined?(::ActiveRecord::ConnectionAdapters::JdbcAdapter)
              instrumentation_module = if ::ActiveRecord.gem_version >= Gem::Version.new('7.1')
                Instrumentation::InternalExecQueryAdapterPatch
              elsif ::ActiveRecord.gem_version.segments.first == 4
                Instrumentation::Rails4ExecQueryAdapterPatch
              else
                Instrumentation::ExecQueryAdapterPatch
              end
            end

            ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(instrumentation_module)
          end
        end
      end
    end
  end
end
