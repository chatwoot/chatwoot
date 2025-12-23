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
    class ResqueSpy
      TYPE = 'Resque'

      # @api private
      module Ext
        def perform
          name = @payload && @payload['class']&.to_s
          transaction = ElasticAPM.start_transaction(name, TYPE)
          super
          transaction&.done 'success'
          transaction&.outcome = Transaction::Outcome::SUCCESS
        rescue ::Exception => e
          ElasticAPM.report(e, handled: false)
          transaction&.done 'error'
          transaction&.outcome = Transaction::Outcome::FAILURE
          raise
        ensure
          ElasticAPM.end_transaction
        end
      end

      def install
        ::Resque::Job.prepend(Ext)
      end
    end

    register 'Resque', 'resque', ResqueSpy.new
  end
end
