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
    class RakeSpy
      # @api private
      module Ext
        def execute(*args)
          agent = ElasticAPM.start

          unless agent && agent.config.instrumented_rake_tasks.include?(name)
            return super(*args)
          end

          transaction =
            ElasticAPM.start_transaction("Rake::Task[#{name}]", 'Rake')

          begin
            result = super(*args)

            transaction&.result = 'success'
            transaction&.outcome = Transaction::Outcome::SUCCESS
          rescue StandardError => e
            transaction&.result = 'error'
            transaction&.outcome = Transaction::Outcome::FAILURE
            ElasticAPM.report(e)

            raise
          ensure
            ElasticAPM.end_transaction
            ElasticAPM.stop
          end

          result
        end
      end

      def install
        ::Rake::Task.prepend(Ext)
      end
    end

    register 'Rake::Task', 'rake', RakeSpy.new
  end
end
