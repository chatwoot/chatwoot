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
#
# frozen_string_literal: true

module ElasticAPM
  # @api private
  module Spies
    # @api private
    class AzureStorageTableSpy
      TYPE = "storage"
      SUBTYPE = "azuretable"

      module Helpers
        class << self
          def instrument(operation_name, table_name = nil, service:)
            span_name = span_name(operation_name, table_name)
            action = formatted_op_name(operation_name)
            account_name = account_name_from_storage_table_host(service.storage_service_host[:primary])

            destination = ElasticAPM::Span::Context::Destination.from_uri(service.storage_service_host[:primary])
            destination.service.resource = "#{SUBTYPE}/#{account_name}"

            context = ElasticAPM::Span::Context.new(destination: destination)

            ElasticAPM.with_span(span_name, TYPE, subtype: SUBTYPE, action: action, context: context) do
              ElasticAPM::Spies.without_faraday do
                ElasticAPM::Spies.without_net_http do
                  yield
                end
              end
            end
          end

          private

          DEFAULT_OP_NAMES = {
            "create_table" => "Create",
            "delete_table" => "Delete",
            "get_table_acl" => "GetAcl",
            "set_table_acl" => "SetAcl",
            "insert_entity" => "Insert",
            "query_entities" => "Query",
            "update_entity" => "Update",
            "merge_entity" => "Merge",
            "delete_entity" => "Delete"
          }.freeze

          def formatted_op_names
            @formatted_op_names ||= Concurrent::Map.new
          end

          def account_names
            @account_names ||= Concurrent::Map.new
          end

          def span_name(operation_name, table_name = nil)
            base = "AzureTable #{formatted_op_name(operation_name)}"

            return base unless table_name

            "#{base} #{table_name}"
          end

          def formatted_op_name(operation_name)
            formatted_op_names.compute_if_absent(operation_name) do
              DEFAULT_OP_NAMES.fetch(operation_name) do
                operation_name.to_s.split("_").collect(&:capitalize).join
              end
            end
          end

          def account_name_from_storage_table_host(host)
            account_names.compute_if_absent(host) do
              URI(host).host.split(".").first || "unknown"
            end
          rescue Exception
            "unknown"
          end
        end
      end

      # @api private
      module Ext
        # Methods with table_name as first parameter
        %i[
          create_table
          delete_table
          get_table
          get_table_acl
          set_table_acl
          insert_entity
          query_entities
          update_entity
          merge_entity
          delete_entity
        ].each do |method_name|
          define_method(method_name) do |table_name, *args|
            unless (transaction = ElasticAPM.current_transaction)
              return super(table_name, *args)
            end

            ElasticAPM::Spies::AzureStorageTableSpy::Helpers.instrument(
              method_name.to_s, table_name, service: self
            ) do
              super(table_name, *args)
            end
          end
        end

        # Methods WITHOUT table_name as first parameter
        def query_tables(*args)
          unless (transaction = ElasticAPM.current_transaction)
            return super(*args)
          end

          ElasticAPM::Spies::AzureStorageTableSpy::Helpers.instrument("query_tables", service: self) do
            super(*args)
          end
        end
      end

      def install
        ::Azure::Storage::Table::TableService.prepend(Ext)
      end
    end

    register(
      "Azure::Storage::Table::TableService",
      "azure/storage/table",
      AzureStorageTableSpy.new
    )
  end
end
