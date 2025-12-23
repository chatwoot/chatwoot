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
    class S3Spy
      TYPE = 'storage'
      SUBTYPE = 's3'
      AP_REGION_REGEX = /^(?:[^:]+:){3}([^:]+).*/
      AP_REGEX = /:accesspoint.*/
      MUTEX = Mutex.new

      @@formatted_op_names = {}

      def self.without_net_http
        return yield unless defined?(NetHTTPSpy)

        # rubocop:disable Style/ExplicitBlockArgument
        ElasticAPM::Spies::NetHTTPSpy.disable_in do
          yield
        end
        # rubocop:enable Style/ExplicitBlockArgument
      end

      def self.bucket_name(params)
        return unless (bucket = params[:bucket]&.to_s)
        return bucket unless (index = bucket.rindex(AP_REGEX))

        bucket[index+1..-1]
      end

      def self.accesspoint_region(params)
        if params[:bucket] && (match = AP_REGION_REGEX.match(params[:bucket]))
          match[1]
        end
      end

      def self.span_name(operation_name, bucket_name)
        bucket_name ? "S3 #{formatted_op_name(operation_name)} #{bucket_name}" :
          "S3 #{formatted_op_name(operation_name)}"
      end

      def self.formatted_op_name(operation_name)
        if @@formatted_op_names[operation_name]
          return @@formatted_op_names[operation_name]
        end

        MUTEX.synchronize do
          if @@formatted_op_names[operation_name]
            return @@formatted_op_names[operation_name]
          end

          @@formatted_op_names[operation_name] =
            operation_name.to_s.split('_').collect(&:capitalize).join
        end

        @@formatted_op_names[operation_name]
      end


      # @api private
      module Ext
        def self.prepended(mod)
          # Alias all available operations
          mod.api.operation_names.each do |operation_name|
            define_method(operation_name) do |params = {}, options = {}, &block|
              bucket_name = ElasticAPM::Spies::S3Spy.bucket_name(params)
              region = ElasticAPM::Spies::S3Spy.accesspoint_region(params) || config.region

              resource = "#{SUBTYPE}/#{bucket_name || 'unknown-bucket'}"
              context = ElasticAPM::Span::Context.new(
                db: {
                  instance: config.region,
                  type: SUBTYPE
                },
                destination: {
                  address: config.endpoint.host,
                  port: config.endpoint.port,
                  service: {
                    name: SUBTYPE,
                    type: TYPE,
                    resource: resource },
                  cloud: { region: region }
                }
              )

              ElasticAPM.with_span(
                ElasticAPM::Spies::S3Spy.span_name(operation_name, bucket_name),
                TYPE,
                subtype: SUBTYPE,
                action: ElasticAPM::Spies::S3Spy.formatted_op_name(operation_name),
                context: context
              ) do
                ElasticAPM::Spies::S3Spy.without_net_http do
                  super(params, options, &block)
                end
              end
            end
          end
        end
      end

      def install
        ::Aws::S3::Client.prepend(Ext)
      end
    end

    register(
      'Aws::S3::Client',
      'aws-sdk-s3',
      S3Spy.new
    )
  end
end
