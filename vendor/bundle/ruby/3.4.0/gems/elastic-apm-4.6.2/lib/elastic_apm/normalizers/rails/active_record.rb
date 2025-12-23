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

require 'elastic_apm/sql/signature'

module ElasticAPM
  module Normalizers
    module ActiveRecord
      # @api private
      class SqlNormalizer < Normalizer
        register 'sql.active_record'

        TYPE = 'db'
        ACTION = 'sql'
        SKIP_NAMES = %w[SCHEMA CACHE].freeze
        UNKNOWN = 'unknown'

        def initialize(*args)
          super

          @summarizer = Sql::Signature::Summarizer.new

          @adapters = {}
        end

        def normalize(_transaction, _name, payload)
          return :skip if SKIP_NAMES.include?(payload[:name])

          name = summarize(payload[:sql]) || payload[:name]
          subtype = subtype_for(payload)

          context =
            Span::Context.new(
              db: { statement: payload[:sql], type: 'sql' },
              destination: { service: { name: subtype, resource: subtype, type: TYPE } }
            )

          [name, TYPE, subtype, ACTION, context]
        end

        private

        def subtype_for(payload)
          if payload[:connection]
            return cached_adapter_name(payload[:connection].adapter_name)
          end

          if can_attempt_connection_id_lookup?(payload)
            begin
              loaded_object = ObjectSpace._id2ref(payload[:connection_id])
              if loaded_object.respond_to?(:adapter_name)
                return cached_adapter_name(loaded_object.adapter_name)
              end
            rescue RangeError # if connection object has somehow been garbage collected
            end
          end

          cached_adapter_name(::ActiveRecord::Base.connection_config[:adapter])
        end

        def summarize(sql)
          @summarizer.summarize(sql)
        end

        def cached_adapter_name(adapter_name)
          return UNKNOWN if adapter_name.nil? || adapter_name.empty?

          @adapters[adapter_name] ||
            (@adapters[adapter_name] = adapter_name.downcase)
        rescue StandardError
          nil
        end

        def can_attempt_connection_id_lookup?(payload)
          RUBY_ENGINE == "ruby" &&
            payload[:connection_id] &&
            ObjectSpace.respond_to?(:_id2ref)
        end
      end
    end
  end
end
