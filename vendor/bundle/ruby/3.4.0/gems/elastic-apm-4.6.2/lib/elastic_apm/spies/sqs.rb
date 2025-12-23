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
    class SQSSpy
      TYPE = 'messaging'
      SUBTYPE = 'sqs'

      REGION_REGEXP = %r{https://sqs\.([a-z0-9-]+)\.amazonaws}

      def self.without_net_http
        return yield unless defined?(NetHTTPSpy)

        # rubocop:disable Style/ExplicitBlockArgument
        ElasticAPM::Spies::NetHTTPSpy.disable_in do
          yield
        end
        # rubocop:enable Style/ExplicitBlockArgument
      end

      def self.queue_name(params)
        if params[:queue_url]
          params[:queue_url].split('/')[-1]
        end
      end

      def self.region_from_url(url)
        if match = REGION_REGEXP.match(url)
          match[1]
        end
      end

      def self.span_context(queue_name, region)
        ElasticAPM::Span::Context.new(
          message: { queue_name: queue_name },
          destination: {
            service: { resource: "#{SUBTYPE}/#{queue_name}" },
            cloud: { region: region }
          }
          # span links added here?
        )
      end

      # @api private
      module Ext
        def self.prepended(mod)
          def send_message(params = {}, options = {})
            unless (transaction = ElasticAPM.current_transaction)
              return super(params, options)
            end

            queue_name = ElasticAPM::Spies::SQSSpy.queue_name(params)
            span_name = queue_name ? "SQS SEND to #{queue_name}" : 'SQS SEND'
            region = ElasticAPM::Spies::SQSSpy.region_from_url(params[:queue_url])
            context = ElasticAPM::Spies::SQSSpy.span_context(
              queue_name,
              region || config.region
            )

            ElasticAPM.with_span(
              span_name,
              TYPE,
              subtype: SUBTYPE,
              action: 'send',
              context: context
            ) do |span|
              trace_context = span&.trace_context || transaction.trace_context
              trace_context.apply_headers do |key, value|
                params[:message_attributes] ||= {}
                params[:message_attributes][key] ||= {}
                params[:message_attributes][key][:string_value] = value
                params[:message_attributes][key][:data_type] = 'String'
              end

              ElasticAPM::Spies::SQSSpy.without_net_http do
                super(params, options)
              end
            end
          end

          def send_message_batch(params = {}, options = {})
            unless (transaction = ElasticAPM.current_transaction)
              return super(params, options)
            end

            queue_name = ElasticAPM::Spies::SQSSpy.queue_name(params)
            span_name =
              queue_name ? "SQS SEND_BATCH to #{queue_name}" : 'SQS SEND_BATCH'
            region = ElasticAPM::Spies::SQSSpy.region_from_url(params[:queue_url])
            context = ElasticAPM::Spies::SQSSpy.span_context(
              queue_name,
              region || config.region
            )

            ElasticAPM.with_span(
              span_name,
              TYPE,
              subtype: SUBTYPE,
              action: 'send_batch',
              context: context
            ) do |span|
              trace_context = span&.trace_context || transaction.trace_context

              trace_context.apply_headers do |key, value|
                params[:entries].each do |message|
                  message[:message_attributes] ||= {}
                  message[:message_attributes][key] ||= {}
                  message[:message_attributes][key][:string_value] = value
                  message[:message_attributes][key][:data_type] = 'String'
                end
              end

              ElasticAPM::Spies::SQSSpy.without_net_http do
                super(params, options)
              end
            end
          end

          def receive_message(params = {}, options = {})
            unless ElasticAPM.current_transaction
              return super(params, options)
            end

            queue_name = ElasticAPM::Spies::SQSSpy.queue_name(params)
            span_name =
              queue_name ? "SQS RECEIVE from #{queue_name}" : 'SQS RECEIVE'
            region = ElasticAPM::Spies::SQSSpy.region_from_url(params[:queue_url])
            context = ElasticAPM::Spies::SQSSpy.span_context(
              queue_name,
              region || config.region
            )

            ElasticAPM.with_span(
              span_name,
              TYPE,
              subtype: SUBTYPE,
              action: 'receive',
              context: context
            ) do
              ElasticAPM::Spies::SQSSpy.without_net_http do
                super(params, options)
              end
            end
          end

          def delete_message(params = {}, options = {})
            unless ElasticAPM.current_transaction
              return super(params, options)
            end

            queue_name = ElasticAPM::Spies::SQSSpy.queue_name(params)
            span_name = queue_name ? "SQS DELETE from #{queue_name}" : 'SQS DELETE'
            region = ElasticAPM::Spies::SQSSpy.region_from_url(params[:queue_url])
            context = ElasticAPM::Spies::SQSSpy.span_context(
              queue_name,
              region || config.region
            )

            ElasticAPM.with_span(
              span_name,
              TYPE,
              subtype: SUBTYPE,
              action: 'delete',
              context: context
            ) do
              ElasticAPM::Spies::SQSSpy.without_net_http do
                super(params, options)
              end
            end
          end

          def delete_message_batch(params = {}, options = {})
            unless ElasticAPM.current_transaction
              return super(params, options)
            end

            queue_name = ElasticAPM::Spies::SQSSpy.queue_name(params)
            span_name =
              queue_name ? "SQS DELETE_BATCH from #{queue_name}" : 'SQS DELETE_BATCH'
            region = ElasticAPM::Spies::SQSSpy.region_from_url(params[:queue_url])
            context = ElasticAPM::Spies::SQSSpy.span_context(
              queue_name,
              region || config.region
            )

            ElasticAPM.with_span(
              span_name,
              TYPE,
              subtype: SUBTYPE,
              action: 'delete_batch',
              context: context
            ) do
              ElasticAPM::Spies::SQSSpy.without_net_http do
                super(params, options)
              end
            end
          end
        end
      end

      def install
        ::Aws::SQS::Client.prepend(Ext)
      end
    end

    register(
      'Aws::SQS::Client',
      'aws-sdk-sqs',
      SQSSpy.new
    )
  end
end
