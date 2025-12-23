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
    class DelayedJobSpy
      CLASS_SEPARATOR = '.'
      METHOD_SEPARATOR = '#'
      TYPE = 'Delayed::Job'

      def install
        ::Delayed::Backend::Base.class_eval do
          alias invoke_job_without_apm invoke_job

          def invoke_job(*args, &block)
            ::ElasticAPM::Spies::DelayedJobSpy
              .invoke_job(self, *args, &block)
          end
        end
      end

      def self.invoke_job(job, *args, &block)
        job_name = job_name(job)
        transaction = ElasticAPM.start_transaction(job_name, TYPE)
        job.invoke_job_without_apm(*args, &block)
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

      def self.job_name(job)
        payload_object = job.payload_object

        if payload_object.is_a?(::Delayed::PerformableMethod)
          performable_method_name(payload_object)
        elsif payload_object.instance_of?(
          ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper
        )
          payload_object.job_data['job_class']
        else
          payload_object.class.name
        end
      rescue
        job.name
      end

      def self.performable_method_name(payload_object)
        class_name = object_name(payload_object)
        separator = name_separator(payload_object)
        method_name = payload_object.method_name
        "#{class_name}#{separator}#{method_name}"
      end

      def self.object_name(payload_object)
        object = payload_object.object
        klass = object.is_a?(Class) ? object : object.class
        klass.name
      end

      def self.name_separator(payload_object)
        payload_object.object.is_a?(Class) ? CLASS_SEPARATOR : METHOD_SEPARATOR
      end
    end

    register(
      'Delayed::Backend::Base',
      'delayed/backend/base',
      DelayedJobSpy.new
    )
  end
end
