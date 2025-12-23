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
  module Transport
    module Serializers
      # @api private
      class SpanSerializer < Serializer
        def initialize(config)
          super

          @context_serializer = ContextSerializer.new(config)
        end

        attr_reader :context_serializer

        def build(span)
          {
            span: {
              id: span.id,
              transaction_id: span.transaction.id,
              parent_id: span.parent_id,
              name: keyword_field(span.name),
              type: join_type(span),
              duration: ms(span.duration),
              context: context_serializer.build(span.context),
              stacktrace: span.stacktrace.to_a,
              timestamp: span.timestamp,
              trace_id: span.trace_id,
              sample_rate: span.sample_rate,
              outcome: keyword_field(span.outcome)
            }
          }
        end

        # @api private
        class ContextSerializer < Serializer
          def build(context)
            return unless context

            base = {}

            base[:tags] = mixed_object(context.labels) if context.labels.any?
            base[:sync] = context.sync unless context.sync.nil?
            base[:db] = build_db(context.db) if context.db
            base[:http] = build_http(context.http) if context.http

            if context.destination
              base[:destination] = build_destination(context.destination)
            end

            if context.message
              base[:message] = build_message(context.message)
            end

            if context.service
              base[:service] = build_service(context.service)
            end

            if context.links && !context.links.empty?
              base[:links] = build_links(context.links)
            end

            base
          end

          private

          def build_db(db)
            {
              instance: db.instance,
              statement: Util.truncate(db.statement, max_length: 10_000),
              type: db.type,
              user: db.user,
              rows_affected: db.rows_affected
            }
          end

          def build_http(http)
            {
              url: http.url,
              status_code: http.status_code.to_i,
              method: keyword_field(http.method)
            }
          end

          def build_destination(destination)
            return unless destination

            base = {
              address: keyword_field(destination.address),
              port: destination.port
            }

            if (service = destination.service) && !service.empty?
              base[:service] = service.to_h
            end

            if (cloud = destination.cloud) && !cloud.empty?
              base[:cloud] = cloud.to_h
            end

            base
          end

          def build_message(message)
            {
              queue: {
                name: keyword_field(message.queue_name)
              },
              age: {
                ms: message.age_ms.to_i
              }
            }
          end

          def build_service(service)
            {
              target: {
                name: keyword_field(service.target&.name),
                type: keyword_field(service.target&.type)
              }
            }
          end

          def build_links(links)
            {
              links: links.map do |link|
                {"trace_id" => link.trace_id, "span_id" => link.span_id}
              end
            }
          end
        end

        private

        def join_type(span)
          combined = [span.type, span.subtype, span.action]
          combined.compact!
          combined.join '.'
        end
      end
    end
  end
end
