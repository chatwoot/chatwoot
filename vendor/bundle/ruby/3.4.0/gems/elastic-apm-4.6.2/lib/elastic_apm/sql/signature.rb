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

require 'elastic_apm/sql/tokenizer'

module ElasticAPM
  module Sql
    # @api private
    class Signature
      include Tokens

      # Mostly here to provide a similar API to new SqlSummarizer for easier
      # swapping out
      #
      # @api private
      class Summarizer
        def summarize(sql)
          Signature.parse(sql)
        end
      end

      def initialize(sql)
        @sql = sql.encode('utf-8', invalid: :replace, undef: :replace)
        @tokenizer = Tokenizer.new(@sql)
      end

      def parse
        @tokenizer.scan # until tokenizer.token != COMMENT

        parsed = parse_tokens
        return parsed if parsed

        # If all else fails, just return the first token of the query.
        parts = @sql.split
        return '' unless parts.any?

        parts.first.upcase
      end

      def self.parse(sql)
        new(sql).parse
      end

      private

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def parse_tokens
        t = @tokenizer

        case t.token

        when CALL
          return unless scan_until IDENT
          "CALL #{t.text}"

        when DELETE
          return unless scan_until FROM
          return unless scan_token IDENT
          table = scan_dotted_identifier
          "DELETE FROM #{table}"

        when INSERT, REPLACE
          action = t.text
          return unless scan_until INTO
          return unless scan_token IDENT
          table = scan_dotted_identifier
          "#{action} INTO #{table}"

        when SELECT
          level = 0
          while t.scan
            case t.token
            when LPAREN then level += 1
            when RPAREN then level -= 1
            when FROM
              next unless level == 0
              break unless scan_token IDENT
              table = scan_dotted_identifier
              return "SELECT FROM #{table}"
            end
          end

        when UPDATE
          # Scan for the table name. Some dialects allow option keywords before
          # the table name.
          return 'UPDATE' unless scan_token IDENT

          table = t.text

          period = false
          first_period = false

          while t.scan
            case t.token
            when IDENT
              if period
                table += t.text
                period = false
              end

              unless first_period
                table = t.text
              end

              # Two adjacent identifiers found after the first period. Ignore
              # the secondary ones, in case they are unknown keywords.
            when PERIOD
              period = true
              first_period = true
              table += '.'
            else
              return "UPDATE #{table}"
            end
          end
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      # Scans until finding token of `kind`
      def scan_until(kind)
        while @tokenizer.scan
          break true if @tokenizer.token == kind
          false
        end
      end

      # Scans next token, ignoring comments
      # Returns whether next token is of `kind`
      def scan_token(kind)
        while @tokenizer.scan
          next if @tokenizer.token == COMMENT
          break
        end

        return true if @tokenizer.token == kind

        false
      end

      def scan_dotted_identifier
        table = @tokenizer.text

        # rubocop:disable Style/WhileUntilModifier
        while scan_token(PERIOD) && scan_token(IDENT)
          table += ".#{@tokenizer.text}"
        end
        # rubocop:enable Style/WhileUntilModifier

        table
      end
    end
  end
end
