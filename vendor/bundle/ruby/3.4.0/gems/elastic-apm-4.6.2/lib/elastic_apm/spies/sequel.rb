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
  # @api private
  module Spies
    # @api private
    class SequelSpy
      TYPE = 'db'
      ACTION = 'query'

      def self.summarizer
        @summarizer ||= Sql::Signature::Summarizer.new
      end

      # @api private
      module Ext
        # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        def log_connection_yield(sql, connection, args = nil, &block)
          unless ElasticAPM.current_transaction
            return super(sql, connection, args, &block)
          end

          subtype = database_type.to_s

          name =
            ElasticAPM::Spies::SequelSpy.summarizer.summarize sql

          db_name = ''
          # postgresql shows current database
          db_name = connection&.db.to_s if connection.respond_to?(:db)
          # sqlite may expose a filename
          db_name = connection&.filename.to_s if db_name == '' && connection.respond_to?(:filename)
          # fall back to adapter class name
          db_name = connection.class.to_s if db_name == ''

          context = ElasticAPM::Span::Context.new(
            db: { statement: sql, type: 'sql', user: opts[:user] },
            service: {target: {type: subtype, name: db_name }},
            destination: { service: { resource: subtype } }
          )

          span = ElasticAPM.start_span(
            name,
            TYPE,
            subtype: subtype,
            action: ACTION,
            context: context
          )
          super(sql, connection, args, &block).tap do |result|
            if /^(UPDATE|DELETE)/.match?(name)
              if connection.respond_to?(:changes)
                span.context.db.rows_affected = connection.changes
              elsif result.is_a?(Integer)
                span.context.db.rows_affected = result
              end
            end
          end
        rescue
          span&.outcome = Span::Outcome::FAILURE
          raise
        ensure
          span&.outcome ||= Span::Outcome::SUCCESS
          ElasticAPM.end_span
        end
        # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      end

      def install
        require 'sequel/database/logging'

        ::Sequel::Database.prepend(Ext)
      end
    end

    register 'Sequel', 'sequel', SequelSpy.new
  end
end
