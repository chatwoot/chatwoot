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

require 'elastic_apm/stacktrace'
require 'elastic_apm/context'
require 'elastic_apm/error/exception'
require 'elastic_apm/error/log'

module ElasticAPM
  # @api private
  class Error
    def initialize(culprit: nil, context: nil)
      @id = SecureRandom.hex(16)
      @culprit = culprit
      @timestamp = Util.micros
      @context = context
    end

    attr_accessor :id, :culprit, :exception, :log, :transaction_id,
      :transaction_name, :transaction, :context, :parent_id, :trace_id
    attr_reader :timestamp

    def inspect
      "<ElasticAPM::Error id:#{id}" \
        " culprit:#{culprit}" \
        " timestamp:#{timestamp}" \
        " transaction_id:#{transaction_id}" \
        " transaction_name:#{transaction_name}" \
        " trace_id:#{trace_id}" \
        " exception:#{exception.inspect}" \
        '>'
    end
  end
end
