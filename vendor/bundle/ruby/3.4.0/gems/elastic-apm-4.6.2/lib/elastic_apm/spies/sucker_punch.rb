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
    class SuckerPunchSpy
      TYPE = 'sucker_punch'

      def install
        ::SuckerPunch::Job::ClassMethods.class_eval do
          alias :__run_perform_without_elastic_apm :__run_perform

          def __run_perform(*args)
            # This method is reached via JobClass#async_perform
            # or JobClass#perform_in.
            name = to_s
            transaction = ElasticAPM.start_transaction(name, TYPE)
            __run_perform_without_elastic_apm(*args)
            transaction.done 'success'
            transaction&.outcome = Transaction::Outcome::SUCCESS
          rescue ::Exception => e
            # Note that SuckerPunch by default doesn't raise the errors from
            # the user-defined JobClass#perform method as it uses an error
            # handler, accessed via `SuckerPunch.exception_handler`.
            ElasticAPM.report(e, handled: false)
            transaction.done 'error'
            transaction&.outcome = Transaction::Outcome::FAILURE
            raise
          ensure
            ElasticAPM.end_transaction
          end
        end
      end
    end

    register 'SuckerPunch', 'sucker_punch', SuckerPunchSpy.new
  end
end
