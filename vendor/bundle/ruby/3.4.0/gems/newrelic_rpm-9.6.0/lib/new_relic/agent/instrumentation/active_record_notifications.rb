# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/active_record_subscriber'
require 'new_relic/agent/instrumentation/active_record_prepend'

# Provides a way to send :connection through ActiveSupport notifications to avoid
# looping through connection handlers to locate a connection by connection_id
# This is not needed in Rails 6+: https://github.com/rails/rails/pull/34602
module NewRelic
  module Agent
    module Instrumentation
      module ActiveRecordNotifications
        SQL_ACTIVE_RECORD = 'sql.active_record'.freeze

        module BaseExtensions4x
          # https://github.com/rails/rails/blob/4-1-stable/activerecord/lib/active_record/connection_adapters/abstract_adapter.rb#L371
          def log(sql, name = 'SQL', binds = [], statement_name = nil)
            @instrumenter.instrument(
              SQL_ACTIVE_RECORD,
              :sql => sql,
              :name => name,
              :connection_id => object_id,
              :connection => self,
              :statement_name => statement_name,
              :binds => binds
            ) { yield }
          rescue => e
            # The translate_exception_class method got introduced in 4.1
            if ::ActiveRecord::VERSION::MINOR == 0
              raise translate_exception(e, sql)
            else
              raise translate_exception_class(e, sql)
            end
          end
        end

        module BaseExtensions50
          # https://github.com/rails/rails/blob/5-0-stable/activerecord/lib/active_record/connection_adapters/abstract_adapter.rb#L582
          def log(sql, name = 'SQL', binds = [], type_casted_binds = [], statement_name = nil)
            @instrumenter.instrument(
              SQL_ACTIVE_RECORD,
              sql: sql,
              name: name,
              binds: binds,
              type_casted_binds: type_casted_binds,
              statement_name: statement_name,
              connection_id: object_id,
              connection: self
            ) { yield }
          rescue => e
            raise translate_exception_class(e, sql)
          end
        end

        module BaseExtensions51
          # https://github.com/rails/rails/blob/5-1-stable/activerecord/lib/active_record/connection_adapters/abstract_adapter.rb#L603
          def log(sql, name = 'SQL', binds = [], type_casted_binds = [], statement_name = nil) # :doc:
            @instrumenter.instrument(
              SQL_ACTIVE_RECORD,
              sql: sql,
              name: name,
              binds: binds,
              type_casted_binds: type_casted_binds,
              statement_name: statement_name,
              connection_id: object_id,
              connection: self
            ) do
              @lock.synchronize do
                yield
              end
            end
          rescue => e
            raise translate_exception_class(e, sql)
          end
        end
      end
    end
  end
end

DependencyDetection.defer do
  named :active_record_notifications

  depends_on do
    defined?(ActiveRecord) && defined?(ActiveRecord::Base) &&
      defined?(ActiveRecord::VERSION) &&
      ActiveRecord::VERSION::MAJOR.to_i >= 4
  end

  depends_on do
    !NewRelic::Agent.config[:disable_active_record_instrumentation] &&
      !NewRelic::Agent.config[:disable_active_record_notifications] &&
      !NewRelic::Agent::Instrumentation::ActiveRecordSubscriber.subscribed?
  end

  executes do
    NewRelic::Agent.logger.info('Installing notifications based Active Record instrumentation')
  end

  executes do
    ActiveSupport::Notifications.subscribe('sql.active_record',
      NewRelic::Agent::Instrumentation::ActiveRecordSubscriber.new)
  end

  executes do
    ActiveSupport.on_load(:active_record) do
      NewRelic::Agent::PrependSupportability.record_metrics_for(
        ActiveRecord::Base,
        ActiveRecord::Relation
      )

      # Default to .prepending, unless the ActiveRecord version is <=4
      # **AND** the :prepend_active_record_instrumentation config is false
      if ActiveRecord::VERSION::MAJOR > 4 \
          || NewRelic::Agent.config[:prepend_active_record_instrumentation]

        ActiveRecord::Base.send(:prepend,
          NewRelic::Agent::Instrumentation::ActiveRecordPrepend::BaseExtensions)
        ActiveRecord::Relation.send(:prepend,
          NewRelic::Agent::Instrumentation::ActiveRecordPrepend::RelationExtensions)
      else
        NewRelic::Agent::Instrumentation::ActiveRecordHelper.instrument_additional_methods
      end
    end
  end

  executes do
    if NewRelic::Agent.config[:backport_fast_active_record_connection_lookup]
      major_version = ActiveRecord::VERSION::MAJOR.to_i
      minor_version = ActiveRecord::VERSION::MINOR.to_i

      activerecord_extension = if major_version == 4
        NewRelic::Agent::Instrumentation::ActiveRecordNotifications::BaseExtensions4x
      elsif major_version == 5 && minor_version == 0
        NewRelic::Agent::Instrumentation::ActiveRecordNotifications::BaseExtensions50
      elsif major_version == 5 && minor_version == 1
        NewRelic::Agent::Instrumentation::ActiveRecordNotifications::BaseExtensions51
      end

      unless activerecord_extension.nil?
        ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:prepend, activerecord_extension)
      end
    end
  end

  executes do
    if ActiveRecord::VERSION::MAJOR == 5 \
        && ActiveRecord::VERSION::MINOR.to_i == 1 \
        && ActiveRecord::VERSION::TINY.to_i >= 6

      ActiveRecord::Base.prepend(NewRelic::Agent::Instrumentation::ActiveRecordPrepend::BaseExtensions516)
    end
  end
end
