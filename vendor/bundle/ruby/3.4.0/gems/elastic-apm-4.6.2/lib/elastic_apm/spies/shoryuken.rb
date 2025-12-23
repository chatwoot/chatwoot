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
    class ShoryukenSpy
      # @api private
      class Middleware
        def call(worker_instance, queue, sqs_msg, body)
          transaction =
            ElasticAPM.start_transaction(
              job_class(worker_instance, body),
              'shoryuken.job'
            )

          ElasticAPM.set_label('shoryuken.id', sqs_msg.message_id)
          ElasticAPM.set_label('shoryuken.queue', queue)

          yield

          transaction&.done :success
          transaction&.outcome = Transaction::Outcome::SUCCESS
        rescue ::Exception => e
          ElasticAPM.report(e, handled: false)
          transaction&.done :error
          transaction&.outcome = Transaction::Outcome::FAILURE
          raise
        ensure
          ElasticAPM.end_transaction
        end

        private

        def job_class(worker_instance, body)
          klass = body['job_class'] if body.is_a?(Hash)
          klass || worker_instance.class.name
        end
      end

      def install
        ::Shoryuken.server_middleware do |chain|
          chain.add Middleware
        end
      end
    end

    register 'Shoryuken', 'shoryuken', ShoryukenSpy.new
  end
end
