# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'delayed_job/chain'
require_relative 'delayed_job/prepend'

require 'new_relic/agent/instrumentation/controller_instrumentation'

module NewRelic
  module Agent
    module Instrumentation
      module DelayedJob
        module Naming
          module_function

          CLASS_METHOD_DELIMITER = '.'.freeze
          INSTANCE_METHOD_DELIMITER = '#'.freeze
          LEGACY_DJ_FORMAT_DELIMITER = ';'.freeze
          LEGACY_DJ_FORMAT_PREFIX = 'LOAD'.freeze
          LEGACY_DJ_DEFAULT_CLASS = '(unknown class)'.freeze

          def name_from_payload(payload_object)
            if payload_object.is_a?(::Delayed::PerformableMethod)
              # payload_object contains a reference to an object
              # that received an asynchronous method call via .delay or .handle_asynchronously
              "#{object_name(payload_object)}#{delimiter(payload_object)}#{method_name(payload_object)}"
            else
              # payload_object is a user-defined job enqueued via Delayed::Job.enqueue
              payload_object.class.name
            end
          end

          # Older versions of Delayed Job use a semicolon-delimited string to stash the class name.
          # The format of this string is "LOAD;<class name>;<ORM ID>"
          def legacy_performable_method?(payload_object)
            payload_object.object.is_a?(String) && payload_object.object.start_with?(LEGACY_DJ_FORMAT_PREFIX)
          end

          # If parsing for the class name fails, return a sensible default
          def class_name_from_legacy_performable_method(payload_object)
            payload_object.object.split(LEGACY_DJ_FORMAT_DELIMITER)[1] || LEGACY_DJ_DEFAULT_CLASS
          end

          def object_name(payload_object)
            if payload_object.object.is_a?(Class)
              payload_object.object.to_s
            elsif legacy_performable_method?(payload_object)
              class_name_from_legacy_performable_method(payload_object)
            else
              payload_object.object.class.name
            end
          end

          def delimiter(payload_object)
            if payload_object.object.is_a?(Class)
              CLASS_METHOD_DELIMITER
            else
              INSTANCE_METHOD_DELIMITER
            end
          end

          # DelayedJob's interface for the async method's name varies across the gem's versions
          def method_name(payload_object)
            if payload_object.respond_to?(:method_name)
              payload_object.method_name
            else
              # early versions of Delayed Job override Object#method with the method name
              payload_object.method
            end
          end
        end
      end
    end
  end
end

DependencyDetection.defer do
  @name = :delayed_job

  depends_on do
    defined?(Delayed) && defined?(Delayed::Worker)
  end

  executes do
    NewRelic::Agent.logger.info('Installing DelayedJob instrumentation [part 1/2]')
  end

  executes do
    if use_prepend?
      prepend_instrument Delayed::Worker, NewRelic::Agent::Instrumentation::DelayedJob::Prepend
    else
      chain_instrument NewRelic::Agent::Instrumentation::DelayedJob::Chain
    end
  end

  executes do
    next unless delayed_job_version < Gem::Version.new('4.1.0')

    deprecation_msg = 'Instrumentation for DelayedJob versions below 4.1.0 is deprecated.' \
      'It will stop being monitored in version 9.0.0. ' \
      'Please upgrade your DelayedJob version to continue receiving full support. ' \

    NewRelic::Agent.logger.log_once(
      :warn,
      :deprecated_delayed_job_version,
      deprecation_msg
    )
  end

  def delayed_job_version
    # the following line needs else branch coverage
    Gem.loaded_specs['delayed_job'].version if Gem.loaded_specs['delayed_job'] # rubocop:disable Style/SafeNavigation
  end
end
