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
    class MongoSpy
      def install
        ::Mongo::Monitoring::Global.subscribe(
          ::Mongo::Monitoring::COMMAND,
          Subscriber.new
        )
      end

      # @api private
      class Subscriber
        TYPE = 'db'
        SUBTYPE = 'mongodb'
        ACTION = 'query'

        EVENT_KEY = :__elastic_instrumenter_mongo_events_key

        def events
          Thread.current[EVENT_KEY] ||= []
        end

        def started(event)
          push_event(event)
        end

        def failed(event)
          if (span = pop_event(event))
            span.outcome = Span::Outcome::FAILURE
          end

          span
        end

        def succeeded(event)
          if span = pop_event(event)
            span.outcome = Span::Outcome::SUCCESS
          end

          span
        end

        private

        def push_event(event)
          return unless ElasticAPM.current_transaction
          # Some MongoDB commands are not on collections but rather are db
          # admin commands. For these commands, the value at the `command_name`
          # key is the integer 1.
          # For getMore commands, the value at `command_name` is the cursor id
          # and the collection name is at the key `collection`
          collection =
            if event.command[event.command_name] == 1 ||
              event.command[event.command_name].is_a?(BSON::Int64)
              event.command[:collection]
            else
              event.command[event.command_name]
            end

          name = [event.database_name,
                  collection,
                  event.command_name].compact.join('.')

          span =
            ElasticAPM.start_span(
              name,
              TYPE,
              subtype: SUBTYPE,
              action: ACTION,
              context: build_context(event)
            )

          events << span
        end

        def pop_event(event)
          return unless (curr = ElasticAPM.current_span)

          curr == events[-1] && ElasticAPM.end_span(events.pop)
        end

        def build_context(event)
          Span::Context.new(
            db: {
              instance: event.database_name,
              statement: event.command.to_s,
              type: 'mongodb',
              user: nil
            },
            destination: {
              service: {
                name: SUBTYPE,
                resource: SUBTYPE,
                type: TYPE
              }
            }
          )
        end
      end
    end

    register 'Mongo', 'mongo', MongoSpy.new
  end
end
