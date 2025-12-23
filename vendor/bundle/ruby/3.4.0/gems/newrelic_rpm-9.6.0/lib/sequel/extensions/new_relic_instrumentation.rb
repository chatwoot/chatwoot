# -*- ruby -*-
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'sequel' unless defined?(Sequel)
require 'newrelic_rpm' unless defined?(NewRelic)
require 'new_relic/agent/instrumentation/sequel_helper'
require 'new_relic/agent/datastores/metric_helper'

module Sequel
  # New Relic's Sequel instrumentation is implemented via a plugin for
  # Sequel::Models, and an extension for Sequel::Databases. Every database
  # handle that Sequel knows about when New Relic is loaded will automatically
  # be instrumented, but if you're using a version of Sequel before 3.47.0,
  # you'll need to add the extension yourself if you create any after the
  # instrumentation is loaded:
  #
  #     db = Sequel.connect( ... )
  #     db.extension :new_relic_instrumentation
  #
  # Versions 3.47.0 and later use `Database.extension` to automatically
  # install the extension for new connections.
  #
  # == Disabling
  #
  # If you don't want your models or database connections to be instrumented,
  # you can disable them by setting `disable_database_instrumentation` in
  # your `newrelic.yml` to `true`. It will also honor the
  # `disable_active_record_instrumentation` setting.
  #
  module NewRelicInstrumentation
    module Naming
      def self.query_method_name
        if Sequel::VERSION >= '4.35.0'
          :log_connection_yield
        else
          :log_yield
        end
      end
    end

    define_method Naming.query_method_name do |*args, &blk| # THREAD_LOCAL_ACCESS
      sql = args.first

      product = NewRelic::Agent::Instrumentation::SequelHelper.product_name_from_adapter(self.class.adapter_scheme)
      operation = NewRelic::Agent::Datastores::MetricHelper.operation_from_sql(sql)
      segment = NewRelic::Agent::Tracer.start_datastore_segment(
        product: product,
        operation: operation
      )

      begin
        super(*args, &blk)
      ensure
        notice_sql(sql)
        ::NewRelic::Agent::Transaction::Segment.finish(segment)
      end
    end

    # We notice sql through the current_segment due to the disable_all_tracing
    # block in the sequel Plugin instrumentation. A simple ORM operation from the Plugin
    # instrumentation may trigger a number of calls to this method. We want to append
    # the statements that come from the disable_all_tracing block into this node's
    # statement, otherwise we would end up overwriting the sql statement with the
    # last one executed.
    def notice_sql(sql)
      return unless txn = NewRelic::Agent::Tracer.current_transaction

      current_segment = txn.current_segment
      return unless current_segment.is_a?(NewRelic::Agent::Transaction::DatastoreSegment)

      if current_segment.sql_statement
        current_segment.sql_statement.append_sql(sql)
      else
        current_segment._notice_sql(sql, self.opts, explainer_for(sql))
      end
    end

    THREAD_SAFE_CONNECTION_POOL_CLASSES = [
      (defined?(::Sequel::ThreadedConnectionPool) && ::Sequel::ThreadedConnectionPool)
    ].freeze

    def explainer_for(sql)
      proc do |*|
        if THREAD_SAFE_CONNECTION_POOL_CLASSES.include?(self.pool.class)
          self[sql].explain
        else
          NewRelic::Agent.logger.log_once(:info, :sequel_explain_skipped, 'Not running SQL explains because Sequel is not in recognized multi-threaded mode')
          nil
        end
      end
    end
  end # module NewRelicInstrumentation

  NewRelic::Agent.logger.debug('Registering the :new_relic_instrumentation extension.')
  Database.register_extension(:new_relic_instrumentation, NewRelicInstrumentation)
end # module Sequel
