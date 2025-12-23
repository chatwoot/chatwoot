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
    class SNSSpy
      TYPE = 'messaging'
      SUBTYPE = 'sns'
      AP_REGEX = /:accesspoint[\/:].*/
      AP_REGION_REGEX = /^(?:[^:]+:){3}([^:]+).*/

      def self.without_net_http
        return yield unless defined?(NetHTTPSpy)

        # rubocop:disable Style/ExplicitBlockArgument
        ElasticAPM::Spies::NetHTTPSpy.disable_in do
          yield
        end
        # rubocop:enable Style/ExplicitBlockArgument
      end

      def self.get_topic(params)
        return '[PHONENUMBER]' if params[:phone_number]

        last_after_slash_or_colon(
          params[:topic_arn] || params[:target_arn]
        )
      end

      def self.last_after_slash_or_colon(arn)
        if index = arn.rindex(AP_REGEX)
          return arn[index+1..-1]
        end

        if arn.include?('/')
          arn.split('/')[-1]
        else
          arn.split(':')[-1]
        end
      end

      def self.arn_region(arn)
        if arn && (match = AP_REGION_REGEX.match(arn))
          match[1]
        end
      end

      def self.span_context(topic, region)
        ElasticAPM::Span::Context.new(
          message: { queue_name: topic },
          destination: {
            service: { resource: "#{SUBTYPE}/#{topic}" },
            cloud: { region: region }
          }
        )
      end

      # @api private
      module Ext
        def publish(params = {}, options = {})
          unless (transaction = ElasticAPM.current_transaction)
            return super(params, options)
          end

          topic = ElasticAPM::Spies::SNSSpy.get_topic(params)
          span_name = topic ? "SNS PUBLISH to #{topic}" : 'SNS PUBLISH'
          region = ElasticAPM::Spies::SNSSpy.arn_region(
            params[:topic_arn] || params[:target_arn]
          )
          context = ElasticAPM::Spies::SNSSpy.span_context(
            topic,
            region || config.region
          )

          ElasticAPM.with_span(
            span_name,
            TYPE,
            subtype: SUBTYPE,
            action: 'publish',
            context: context
          ) do |span|
            trace_context = span&.trace_context || transaction.trace_context
            trace_context.apply_headers do |key, value|
              params[:message_attributes] ||= {}
              params[:message_attributes][key] ||= {}
              params[:message_attributes][key][:string_value] = value
              params[:message_attributes][key][:data_type] = 'String'
            end

            ElasticAPM::Spies::SNSSpy.without_net_http do
              super(params, options)
            end
          end
        end
      end

      def install
        ::Aws::SNS::Client.prepend(Ext)
      end
    end

    register(
      'Aws::SNS::Client',
      'aws-sdk-sns',
      SNSSpy.new
    )
  end
end
