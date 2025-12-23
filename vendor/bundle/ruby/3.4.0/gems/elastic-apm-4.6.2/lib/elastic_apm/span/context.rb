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
  class Span
    # @api private
    class Context
      def initialize(
        db: nil,
        destination: nil,
        http: nil,
        labels: {},
        sync: nil,
        message: nil,
        service: nil,
        links: nil
      )
        @sync = sync
        @db = db && Db.new(**db)
        @http = http && Http.new(**http)
        @destination =
          case destination
          when Destination then destination
          when Hash then Destination.new(**destination)
          end
        @message =
          case message
          when Message then message
          when Hash then Message.new(**message)
          end
        @labels = labels
        @service =
          case service
          when Service then service
          when Hash then Service.new(**service)
          end
        @links =
          case links
          when Links then links
          when Array then Links.new(links)
          end
      end

      attr_reader(
        :db,
        :http,
        :labels,
        :sync,
        :message,
        :links
      )

      attr_accessor :destination, :service
    end
  end
end

require 'elastic_apm/span/context/db'
require 'elastic_apm/span/context/http'
require 'elastic_apm/span/context/destination'
require 'elastic_apm/span/context/message'
require 'elastic_apm/span/context/service'
require 'elastic_apm/span/context/links'

