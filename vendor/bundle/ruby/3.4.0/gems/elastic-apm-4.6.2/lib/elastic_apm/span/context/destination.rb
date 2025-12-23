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
  class Span
    class Context
      # @api private
      class Destination
        include Fields

        field :address
        field :port
        field :service
        field :cloud

        # @api private
        class Service
          include Fields

          field :name, default: ''
          field :type, default: ''
          field :resource
        end

        # @api private
        class Cloud
          include Fields

          field :region
        end

        def initialize(service: nil, cloud: nil, **attrs)
          super(**attrs)

          self.service = build_service(service)
          self.cloud = build_cloud(cloud)
        end

        def self.from_uri(uri_or_str, type: nil, **attrs)
          uri = normalize(uri_or_str)

          service =
            case type
            when 'http' then http_service(uri)
            else nil
            end

          new(
            address: uri.hostname,
            port: uri.port,
            service: service,
            **attrs
          )
        end

        class << self
          private

          def normalize(uri_or_str)
            return uri_or_str.dup if uri_or_str.is_a?(URI)
            URI(uri_or_str)
          end

          def http_service(uri)
            Service.new(resource: "#{uri.host}:#{uri.port}")
          end
        end

        private

        def build_cloud(cloud = nil)
          return Cloud.new unless cloud
          return cloud if cloud.is_a?(Cloud)

          Cloud.new(**cloud)
        end

        def build_service(service = nil)
          return Service.new unless service
          return service if service.is_a?(Service)

          Service.new(**service)
        end
      end
    end
  end
end
