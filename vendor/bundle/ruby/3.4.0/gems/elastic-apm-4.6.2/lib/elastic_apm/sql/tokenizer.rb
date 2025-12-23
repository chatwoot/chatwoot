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

require 'strscan'
require 'elastic_apm/sql/tokens'

module ElasticAPM
  module Sql
    # @api private
    class Tokenizer
      include Tokens

      ALPHA = /[[:alpha:]]/.freeze
      DIGIT = /[[:digit:]]/.freeze
      SPACE = /[[:space:]]+/.freeze

      def initialize(input)
        @input = input

        @scanner = StringScanner.new(input)
        @byte_start = 0
      end

      attr_reader :input, :scanner, :token

      def text
        @input.byteslice(@byte_start, @byte_end - @byte_start)
      end

      def scan
        scanner.skip(SPACE)

        @byte_start = scanner.pos
        char = next_char

        return false unless char

        @token = next_token(char)

        true
      end

      private

      # rubocop:disable Metrics/CyclomaticComplexity
      def next_token(char)
        case char
        when '_'   then scan_keyword_or_identifier(possible_keyword: false)
        when '.'   then PERIOD
        when '$'   then scan_dollar_sign
        when '`'   then scan_quoted_indentifier('`')
        when '"'   then scan_quoted_indentifier('"')
        when '['   then scan_quoted_indentifier(']')
        when '('   then LPAREN
        when ')'   then RPAREN
        when '/'   then scan_bracketed_or_cql_comment
        when '-'   then scan_simple_comment
        when "'"   then scan_string_literal
        when ALPHA then scan_keyword_or_identifier(possible_keyword: true)
        when DIGIT then scan_numeric_literal
        else            OTHER
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def next_char
        char = @scanner.getch
        @byte_end = @scanner.pos
        char
      end

      # StringScanner#peek returns next byte which could be an incomplete utf
      # multi-byte character
      def peek_char(length = 1)
        # The maximum byte count of utf chars is 4:
        # > In UTF-8, characters from the U+0000..U+10FFFF range (the UTF-16
        #   accessible range) are encoded using sequences of 1 to 4 octets.
        # # https://tools.ietf.org/html/rfc3629
        return nil if length > 4

        char = @scanner.peek(length)

        return nil if char.empty?
        return char if char.valid_encoding?

        peek_char(length + 1)
      end

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def scan_keyword_or_identifier(possible_keyword:)
        while (peek = peek_char)
          if peek == '_' || peek == '$' || peek =~ DIGIT
            possible_keyword = false
            next next_char
          end

          next next_char if ALPHA.match?(peek)

          break
        end

        return IDENT unless possible_keyword

        snap = text

        if snap.length < KEYWORD_MIN_LENGTH || snap.length > KEYWORD_MAX_LENGTH
          return IDENT
        end

        keyword = KEYWORDS[snap.length].find { |kw| snap.upcase == kw.to_s }
        return keyword if keyword

        IDENT
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      # rubocop:disable Metrics/CyclomaticComplexity
      def scan_dollar_sign
        while (peek = peek_char)
          case peek
          when DIGIT
            next_char while peek_char =~ DIGIT
          when '$', '_', ALPHA, SPACE
            # PostgreSQL supports dollar-quoted string literal syntax,
            # like $foo$...$foo$. The tag (foo in this case) is optional,
            # and if present follows identifier rules.
            while (char = next_char)
              case char
              when '$'
                # This marks the end of the initial $foo$.
                snap = text
                slice = input.slice(scanner.pos, input.length)
                index = slice.index(snap)
                next unless index && index >= 0

                delta = index + snap.bytesize
                @byte_end += delta
                scanner.pos += delta
                return STRING
              when SPACE
                # Unknown token starting with $, consume chars until space.
                @byte_end -= char.bytesize
                return OTHER
              end
            end
          else break
          end
        end

        OTHER
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def scan_quoted_indentifier(delimiter)
        while (char = next_char)
          next unless char == delimiter

          if delimiter == '"' && peek_char == delimiter
            next next_char
          end

          break
        end

        # Remove quotes from identifier
        @byte_start += char.bytesize
        @byte_end -= char.bytesize

        IDENT
      end

      def scan_bracketed_or_cql_comment
        case peek_char
        when '*' then scan_bracketed_comment
        when '/' then scan_cql_comment
        else OTHER
        end
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def scan_bracketed_comment
        nesting = 1

        while (char = next_char)
          case char
          when '/'
            next unless peek_char == '*'
            next_char
            nesting += 1
          when '*'
            next unless peek_char == '/'
            next_char
            nesting -= 1
            return COMMENT if nesting == 0
          end
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def scan_cql_comment
        return OTHER unless peek_char == '/'

        while (char = next_char)
          break if char == "\n"
        end

        COMMENT
      end

      def scan_simple_comment
        return OTHER unless peek_char == '-'

        while (char = next_char)
          break if char == "\n"
        end

        COMMENT
      end

      def scan_string_literal
        delimiter = "'"

        while (char = next_char)
          if char == '\\'
            # Skip escaped character, e.g. 'what\'s up?'
            next_char
            next
          end

          next unless char == delimiter

          return STRING unless peek_char
          return STRING if peek_char != delimiter

          next_char
        end
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def scan_numeric_literal
        period = false
        exponent = false

        while (peek = peek_char)
          case peek
          when DIGIT then next_char
          when '.'
            return NUMBER if period
            next_char
            period = true
          when 'e', 'E'
            return NUMBER if exponent
            next_char
            next_char if /[+-]/.match?(peek_char)
          else break
          end
        end

        NUMBER
      end
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
