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
    class SneakersSpy
      include Logging

      def self.supported_version?
        Gem.loaded_specs['sneakers'].version >= Gem::Version.create('2.12.0')
      end

      def install
        unless SneakersSpy.supported_version?
          warn(
            'Sneakers version is below 2.12.0. Sneakers spy installation failed'
          )
          return
        end

        Sneakers.middleware.use(Middleware, nil)
      end

      # @api private
      class Middleware
        def initialize(app, *args)
          @app = app
          @args = args
        end

        def call(deserialized_msg, delivery_info, metadata, handler)
          transaction =
            ElasticAPM.start_transaction(
              delivery_info.consumer.queue.name,
              'Sneakers'
            )

          ElasticAPM.set_label(:routing_key, delivery_info.routing_key)

          res = @app.call(deserialized_msg, delivery_info, metadata, handler)
          transaction&.done(:success)
          transaction&.outcome = Transaction::Outcome::SUCCESS

          res
        rescue ::Exception => e
          ElasticAPM.report(e, handled: false)
          transaction&.done(:error)
          transaction&.outcome = Transaction::Outcome::FAILURE
          raise
        ensure
          ElasticAPM.end_transaction
        end
      end
    end

    register 'Sneakers', 'sneakers', SneakersSpy.new
  end
end
