# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Datastores
      module MetricHelper
        ROLLUP_METRIC = 'Datastore/all'.freeze
        OTHER = 'Other'.freeze

        ALL = 'all'.freeze
        ALL_WEB = 'allWeb'.freeze
        ALL_OTHER = 'allOther'.freeze

        def self.statement_metric_for(product, collection, operation)
          "Datastore/statement/#{product}/#{collection}/#{operation}"
        end

        def self.operation_metric_for(product, operation)
          "Datastore/operation/#{product}/#{operation}"
        end

        def self.instance_metric_for(product, host, port_path_or_id)
          "Datastore/instance/#{product}/#{host}/#{port_path_or_id}"
        end

        def self.product_suffixed_rollup(product, suffix)
          "Datastore/#{product}/#{suffix}"
        end

        def self.product_rollup(product)
          "Datastore/#{product}/all"
        end

        def self.suffixed_rollup(suffix)
          "Datastore/#{suffix}"
        end

        def self.all_suffix
          if NewRelic::Agent::Transaction.recording_web_transaction?
            ALL_WEB
          else
            ALL_OTHER
          end
        end

        def self.scoped_metric_for(product, operation, collection = nil)
          if collection
            statement_metric_for(product, collection, operation)
          else
            operation_metric_for(product, operation)
          end
        end

        def self.unscoped_metrics_for(product, operation, collection = nil, host = nil, port_path_or_id = nil)
          suffix = all_suffix

          metrics = [
            product_suffixed_rollup(product, suffix),
            product_rollup(product),
            suffixed_rollup(suffix),
            ROLLUP_METRIC
          ]

          if NewRelic::Agent.config[:'datastore_tracer.instance_reporting.enabled'] && host && port_path_or_id
            metrics.unshift(instance_metric_for(product, host, port_path_or_id))
          end
          metrics.unshift(operation_metric_for(product, operation)) if collection

          metrics
        end

        def self.product_operation_collection_for(product, operation, collection = nil, generic_product = nil)
          if overrides = overridden_operation_and_collection
            if should_override?(overrides, product, generic_product)
              operation = overrides[0] || operation
              collection = overrides[1] || collection
            end
          end
          [product, operation, collection]
        end

        def self.metrics_for(product, operation, collection = nil, generic_product = nil, host = nil, port_path_or_id = nil)
          product, operation, collection = product_operation_collection_for(product, operation, collection, generic_product)

          # Order of these metrics matters--the first metric in the list will
          # be treated as the scoped metric in a bunch of different cases.
          metrics = unscoped_metrics_for(product, operation, collection, host, port_path_or_id)
          metrics.unshift(scoped_metric_for(product, operation, collection))

          metrics
        end

        def self.metrics_from_sql(product, sql)
          operation = operation_from_sql(sql)
          metrics_for(product, operation)
        end

        def self.operation_from_sql(sql)
          operation = NewRelic::Agent::Database.parse_operation_from_query(sql)
          operation = OTHER if operation.eql?(NewRelic::Agent::Database::OTHER_OPERATION)
          operation
        end

        # Allow Transaction#with_database_metric_name to override our
        # collection and operation
        def self.overridden_operation_and_collection # THREAD_LOCAL_ACCESS
          txn = Tracer.current_transaction
          txn ? txn.instrumentation_state[:datastore_override] : nil
        end

        # If the override declared a product affiliation, abide by that
        # ActiveRecord has database-specific product names, so we recognize
        # it by the generic_product it passes.
        def self.should_override?(overrides, product, generic_product)
          override_product = overrides[2]

          override_product.nil? ||
            override_product == product ||
            override_product == generic_product
        end
      end
    end
  end
end
