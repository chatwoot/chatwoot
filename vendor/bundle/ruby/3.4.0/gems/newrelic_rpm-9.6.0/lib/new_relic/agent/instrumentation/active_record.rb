# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/active_record_prepend'

module NewRelic
  module Agent
    module Instrumentation
      module ActiveRecord
        EXPLAINER = lambda do |statement|
          connection = NewRelic::Agent::Database.get_connection(statement.config) do
            ::ActiveRecord::Base.send("#{statement.config[:adapter]}_connection",
              statement.config)
          end
          # the following line needs else branch coverage
          if connection && connection.respond_to?(:execute) # rubocop:disable Style/SafeNavigation
            return connection.execute("EXPLAIN #{statement.sql}")
          end
        end

        def self.insert_instrumentation
          if defined?(::ActiveRecord::VERSION::MAJOR) && ::ActiveRecord::VERSION::MAJOR.to_i >= 3
            if ::NewRelic::Agent.config[:prepend_active_record_instrumentation]
              ::ActiveRecord::Base.prepend(::NewRelic::Agent::Instrumentation::ActiveRecordPrepend::BaseExtensions)
              ::ActiveRecord::Relation.prepend(::NewRelic::Agent::Instrumentation::ActiveRecordPrepend::RelationExtensions)
            else
              ::NewRelic::Agent::Instrumentation::ActiveRecordHelper.instrument_additional_methods
            end
          end

          ::ActiveRecord::ConnectionAdapters::AbstractAdapter.module_eval do
            include ::NewRelic::Agent::Instrumentation::ActiveRecord
          end
        end

        def self.included(instrumented_class)
          instrumented_class.class_eval do
            unless instrumented_class.method_defined?(:log_without_newrelic_instrumentation)
              alias_method(:log_without_newrelic_instrumentation, :log)
              alias_method(:log, :log_with_newrelic_instrumentation)
              protected(:log)
            end
          end
        end

        if RUBY_VERSION < '2.7.0'
          def log_with_newrelic_instrumentation(*args, &block)
            state = NewRelic::Agent::Tracer.state

            if !state.is_execution_traced?
              return log_without_newrelic_instrumentation(*args, &block)
            end

            sql, name, _ = args

            product, operation, collection = ActiveRecordHelper.product_operation_collection_for(
              NewRelic::Helper.correctly_encoded(name),
              NewRelic::Helper.correctly_encoded(sql),
              @config && @config[:adapter]
            )

            host = nil
            port_path_or_id = nil
            database = nil

            if ActiveRecordHelper::InstanceIdentification.supported_adapter?(@config)
              host = ActiveRecordHelper::InstanceIdentification.host(@config)
              port_path_or_id = ActiveRecordHelper::InstanceIdentification.port_path_or_id(@config)
              database = @config && @config[:database]
            end

            segment = NewRelic::Agent::Tracer.start_datastore_segment(
              product: product,
              operation: operation,
              collection: collection,
              host: host,
              port_path_or_id: port_path_or_id,
              database_name: database
            )
            segment._notice_sql(sql, @config, EXPLAINER)

            begin
              NewRelic::Agent::Tracer.capture_segment_error(segment) do
                log_without_newrelic_instrumentation(*args, &block)
              end
            ensure
              ::NewRelic::Agent::Transaction::Segment.finish(segment)
            end
          end
        else
          def log_with_newrelic_instrumentation(*args, **kwargs, &block)
            state = NewRelic::Agent::Tracer.state

            if !state.is_execution_traced?
              return log_without_newrelic_instrumentation(*args, **kwargs, &block)
            end

            sql, name, _ = args

            product, operation, collection = ActiveRecordHelper.product_operation_collection_for(
              NewRelic::Helper.correctly_encoded(name),
              NewRelic::Helper.correctly_encoded(sql),
              @config && @config[:adapter]
            )

            host = nil
            port_path_or_id = nil
            database = nil

            if ActiveRecordHelper::InstanceIdentification.supported_adapter?(@config)
              host = ActiveRecordHelper::InstanceIdentification.host(@config)
              port_path_or_id = ActiveRecordHelper::InstanceIdentification.port_path_or_id(@config)
              database = @config && @config[:database]
            end

            segment = NewRelic::Agent::Tracer.start_datastore_segment(
              product: product,
              operation: operation,
              collection: collection,
              host: host,
              port_path_or_id: port_path_or_id,
              database_name: database
            )
            segment._notice_sql(sql, @config, EXPLAINER)

            begin
              NewRelic::Agent::Tracer.capture_segment_error(segment) do
                log_without_newrelic_instrumentation(*args, **kwargs, &block)
              end
            ensure
              ::NewRelic::Agent::Transaction::Segment.finish(segment)
            end
          end
        end
      end
    end
  end
end

DependencyDetection.defer do
  @name = :active_record

  depends_on do
    defined?(ActiveRecord) && defined?(ActiveRecord::Base) &&
      (!defined?(ActiveRecord::VERSION) ||
        ActiveRecord::VERSION::MAJOR.to_i <= 3)
  end

  depends_on do
    !NewRelic::Agent.config[:disable_active_record_instrumentation]
  end

  executes do
    NewRelic::Agent.logger.info('Installing ActiveRecord instrumentation')
  end

  executes do
    require 'new_relic/agent/instrumentation/active_record_helper'

    if defined?(Rails::VERSION::MAJOR) && Rails::VERSION::MAJOR.to_i == 3
      ActiveSupport.on_load(:active_record) do
        NewRelic::Agent::Instrumentation::ActiveRecord.insert_instrumentation
      end
    else
      NewRelic::Agent::Instrumentation::ActiveRecord.insert_instrumentation
    end
  end
end
