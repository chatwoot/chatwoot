# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/active_record_helper'
require 'new_relic/agent/instrumentation/notifications_subscriber'

# Listen for ActiveSupport::Notifications events for ActiveRecord query
# events.  Write metric data, transaction trace nodes and slow sql
# nodes for each event.
module NewRelic
  module Agent
    module Instrumentation
      class ActiveRecordSubscriber < NotificationsSubscriber
        CACHED_QUERY_NAME = 'CACHE'.freeze

        def initialize
          define_cachedp_method
          # We cache this in an instance variable to avoid re-calling method
          # on each query.
          @explainer = method(:get_explain_plan)
          super
        end

        # The cached? method is dynamically defined based on ActiveRecord version.
        # This file can and often is required before ActiveRecord is loaded. For
        # that reason we define the cache? method in initialize. The behavior
        # difference is that AR 5.1 includes a key in the payload to check,
        # where older versions set the :name to CACHE.

        def define_cachedp_method
          # we don't expect this to be called more than once, but we're being
          # defensive.
          return if defined?(cached?)

          if defined?(::ActiveRecord) && ::ActiveRecord::VERSION::STRING >= '5.1.0'
            def cached?(payload)
              payload.fetch(:cached, false)
            end
          else
            def cached?(payload)
              payload[:name] == CACHED_QUERY_NAME
            end
          end
        end

        def start(name, id, payload) # THREAD_LOCAL_ACCESS
          return if cached?(payload)
          return unless NewRelic::Agent.tl_is_execution_traced?

          config = active_record_config(payload)
          segment = start_segment(config, payload)
          push_segment(id, segment)
        rescue => e
          log_notification_error(e, name, 'start')
        end

        def finish(name, id, payload) # THREAD_LOCAL_ACCESS
          return if cached?(payload)
          return unless state.is_execution_traced?

          if segment = pop_segment(id)
            if exception = exception_object(payload)
              segment.notice_error(exception)
            end
            segment.finish
          end
        rescue => e
          log_notification_error(e, name, 'finish')
        end

        def get_explain_plan(statement)
          connection = NewRelic::Agent::Database.get_connection(statement.config) do
            ::ActiveRecord::Base.send("#{statement.config[:adapter]}_connection",
              statement.config)
          end
          # the following line needs else branch coverage
          if connection && connection.respond_to?(:exec_query) # rubocop:disable Style/SafeNavigation
            return connection.exec_query("EXPLAIN #{statement.sql}",
              "Explain #{statement.name}",
              statement.binds)
          end
        rescue => e
          NewRelic::Agent.logger.debug("Couldn't fetch the explain plan for #{statement} due to #{e}")
        end

        def active_record_config(payload)
          # handle if the notification payload provides the AR connection
          # available in Rails 6+ & our ActiveRecordNotifications#log extension
          if payload[:connection]
            connection_config = payload[:connection].instance_variable_get(:@config)
            return connection_config if connection_config
          end

          return unless connection_id = payload[:connection_id]

          ::ActiveRecord::Base.connection_handler.connection_pool_list.each do |handler|
            connection = handler.connections.detect { |conn| conn.object_id == connection_id }
            return connection.instance_variable_get(:@config) if connection

            # when using makara, handler.connections will be empty, so use the
            # spec config instead.
            # https://github.com/newrelic/newrelic-ruby-agent/issues/507
            # thank you @lucasklaassen
            return handler.spec.config if use_spec_config?(handler)
          end

          nil
        end

        def use_spec_config?(handler)
          handler.respond_to?(:spec) &&
            handler.spec &&
            handler.spec.config &&
            handler.spec.config[:adapter].end_with?('makara')
        end

        def start_segment(config, payload)
          sql = Helper.correctly_encoded(payload[:sql])
          product, operation, collection = ActiveRecordHelper.product_operation_collection_for(
            payload[:name],
            sql,
            config && config[:adapter]
          )

          host = nil
          port_path_or_id = nil
          database = nil

          if ActiveRecordHelper::InstanceIdentification.supported_adapter?(config)
            host = ActiveRecordHelper::InstanceIdentification.host(config)
            port_path_or_id = ActiveRecordHelper::InstanceIdentification.port_path_or_id(config)
            database = config && config[:database]
          end

          segment = Tracer.start_datastore_segment(product: product,
            operation: operation,
            collection: collection,
            host: host,
            port_path_or_id: port_path_or_id,
            database_name: database)

          segment._notice_sql(sql, config, @explainer, payload[:binds], payload[:name])
          segment
        end
      end
    end
  end
end
