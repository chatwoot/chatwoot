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
  module Spies
    # @api private
    class DynamoDBSpy
      TYPE = 'db'
      SUBTYPE = 'dynamodb'
      ACTION = 'query'

      @@formatted_op_names = Concurrent::Map.new

      def self.without_net_http
        return yield unless defined?(NetHTTPSpy)

        # rubocop:disable Style/ExplicitBlockArgument
        ElasticAPM::Spies::NetHTTPSpy.disable_in do
          yield
        end
        # rubocop:enable Style/ExplicitBlockArgument
      end

      def self.span_name(operation_name, params)
        params[:table_name] ?
          "DynamoDB #{formatted_op_name(operation_name)} #{params[:table_name]}" :
          "DynamoDB #{formatted_op_name(operation_name)}"
      end

      def self.formatted_op_name(operation_name)
        @@formatted_op_names.compute_if_absent(operation_name) do
          operation_name.to_s.split('_').collect(&:capitalize).join
        end
      end

      # @api private
      module Ext
        def self.prepended(mod)
          # Alias all available operations
          mod.api.operation_names.each do |operation_name|
            define_method(operation_name) do |params = {}, options = {}|
              context = ElasticAPM::Span::Context.new(
                db: {
                  instance: config.region,
                  type: SUBTYPE,
                  statement: params[:key_condition_expression]
                },
                destination: {
                  address: config.endpoint.host,
                  port: config.endpoint.port,
                  service: {
                      name: SUBTYPE,
                      type: TYPE,
                      resource: SUBTYPE },
                  cloud: { region: config.region }
                }
              )

              ElasticAPM.with_span(
                ElasticAPM::Spies::DynamoDBSpy.span_name(operation_name, params),
                TYPE,
                subtype: SUBTYPE,
                action: ACTION,
                context: context
              ) do
                ElasticAPM::Spies::DynamoDBSpy.without_net_http do
                  super(params, options)
                end
              end
            end
          end
        end
      end

      def install
        ::Aws::DynamoDB::Client.prepend(Ext)
      end
    end

    register(
      'Aws::DynamoDB::Client',
      'aws-sdk-dynamodb',
      DynamoDBSpy.new
    )
  end
end
