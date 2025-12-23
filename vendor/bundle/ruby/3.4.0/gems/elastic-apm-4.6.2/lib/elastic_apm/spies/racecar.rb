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

begin
require 'active_support/notifications'
require 'active_support/subscriber'

  # frozen_string_literal: true
  module ElasticAPM
    # @api private
    module Spies
      # @api private
      class RacecarSpy
        TYPE = 'kafka'
        SUBTYPE = 'racecar'

        # @api private
        class ConsumerSubscriber < ActiveSupport::Subscriber
          def start_process_message(event)
            start_process_transaction(event: event, kind: 'process_message')
          end
          def process_message(_event)
            ElasticAPM.end_transaction
          end

          def start_process_batch(event)
            start_process_transaction(event: event, kind: 'process_batch')
          end
          def process_batch(_event)
            ElasticAPM.end_transaction
          end

          private # only public methods will be subscribed

          def start_process_transaction(event:, kind:)
            ElasticAPM.start_transaction(kind, TYPE)
            ElasticAPM.current_transaction.context.set_service(framework_name: 'racecar', framework_version: Racecar::VERSION)
          end
        end

        class ProducerSubscriber < ActiveSupport::Subscriber
          def start_deliver_message(event)
            ElasticAPM.start_transaction('deliver_message',TYPE)
            ElasticAPM.current_transaction.context.set_service(framework_name: 'racecar', framework_version: Racecar::VERSION)
          end

          def deliver_message(_event)
            ElasticAPM.end_transaction
          end
        end

        def install
          ConsumerSubscriber.attach_to(:racecar)
          ProducerSubscriber.attach_to(:racecar)
        end
      end
      register 'Racecar', 'racecar', RacecarSpy.new
    end
  end

rescue LoadError
  # no active support available
end
