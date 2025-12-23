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
  module Sql
    # @api private
    module Tokens
      OTHER = :OTHER
      COMMENT = :COMMENT
      IDENT = :IDENT
      NUMBER = :NUMBER
      STRING = :STRING

      PERIOD = :PERIOD
      COMMA = :COMMA
      LPAREN = :LPAREN
      RPAREN = :RPAREN

      AS = :AS
      CALL = :CALL
      DELETE = :DELETE
      FROM = :FROM
      INSERT = :INSERT
      INTO = :INTO
      OR = :OR
      REPLACE = :REPLACE
      SELECT = :SELECT
      SET = :SET
      TABLE = :TABLE
      TRUNCATE = :TRUNCATE
      UPDATE = :UPDATE

      KEYWORDS = {
        2 => [AS, OR],
        3 => [SET],
        4 => [CALL, FROM, INTO],
        5 => [TABLE],
        6 => [DELETE, INSERT, SELECT, UPDATE],
        7 => [REPLACE],
        8 => [TRUNCATE]
      }.freeze

      KEYWORD_MIN_LENGTH = KEYWORDS.keys.first
      KEYWORD_MAX_LENGTH = KEYWORDS.keys.last
    end
  end
end
