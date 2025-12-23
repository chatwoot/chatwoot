# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/parameter_filtering'

module NewRelic::Agent::Instrumentation
  module Grape
    module Instrumentation
      extend self

      INSTRUMENTATION_NAME = NewRelic::Agent.base_name(name)

      # Since 1.2.0, the class `Grape::API` no longer refers to an API instance, rather, what used to be `Grape::API` is `Grape::API::Instance`
      # https://github.com/ruby-grape/grape/blob/c20a73ac1e3f3ba1082005ed61bf69452373ba87/UPGRADING.md#upgrading-to--120
      def instrumented_class
        defined?(::Grape::API::Instance) ? ::Grape::API::Instance : ::Grape::API
      end

      def capture_transaction(env, context)
        begin
          endpoint = env[API_ENDPOINT]
          version = env[API_VERSION]

          api_class = (context.class.respond_to?(:base) && context.class.base) || context.class
          handle_transaction(endpoint, api_class.name, version)
        rescue => e
          ::NewRelic::Agent.logger.warn('Error in Grape instrumentation', e)
        end
      end

      def prepare!
        if defined?(::Grape::VERSION) && Gem::Version.new(::Grape::VERSION) >= Gem::Version.new('0.16.0')
          send(:remove_method, :name_for_transaction_deprecated)
        else
          send(:remove_method, :name_for_transaction)
          send(:alias_method, :name_for_transaction, :name_for_transaction_deprecated)
        end
      end

      API_ENDPOINT = 'api.endpoint'.freeze
      API_VERSION = 'api.version'.freeze
      FORMAT_REGEX = /\(\/?\.[\:\w]*\)/.freeze # either :format (< 0.12.0) or .ext (>= 0.12.0)
      VERSION_REGEX = /:version(\/|$)/.freeze
      MIN_VERSION = Gem::Version.new('0.2.0')
      PIPE_STRING = '|'.freeze

      def handle_transaction(endpoint, class_name, version)
        return unless endpoint && route = endpoint.route

        NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

        name_transaction(route, class_name, version)
        capture_params(endpoint)
      end

      def name_transaction(route, class_name, version)
        txn_name = name_for_transaction(route, class_name, version)
        segment_name = "Middleware/Grape/#{class_name}/call"
        NewRelic::Agent::Transaction.set_default_transaction_name(txn_name, :grape)
        txn = NewRelic::Agent::Transaction.tl_current
        txn.segments.last.name = segment_name
      end

      def name_for_transaction(route, class_name, version)
        action_name = route.path.sub(FORMAT_REGEX, NewRelic::EMPTY_STR)
        method_name = route.request_method
        version ||= route.version

        # defaulting does not set rack.env['api.version'] and route.version may return Array
        #
        version = version.join(PIPE_STRING) if Array === version

        if version
          action_name = action_name.sub(VERSION_REGEX, NewRelic::EMPTY_STR)
          "#{class_name}-#{version}#{action_name} (#{method_name})"
        else
          "#{class_name}#{action_name} (#{method_name})"
        end
      end

      def name_for_transaction_deprecated(route, class_name, version)
        action_name = route.route_path.sub(FORMAT_REGEX, NewRelic::EMPTY_STR)
        method_name = route.route_method
        version ||= route.route_version
        if version
          action_name = action_name.sub(VERSION_REGEX, NewRelic::EMPTY_STR)
          "#{class_name}-#{version}#{action_name} (#{method_name})"
        else
          "#{class_name}#{action_name} (#{method_name})"
        end
      end

      def capture_params(endpoint)
        txn = ::NewRelic::Agent::Transaction.tl_current
        env = endpoint.request.env
        params = ::NewRelic::Agent::ParameterFiltering::apply_filters(env, endpoint.params)
        params.delete('route_info')
        txn.filtered_params = params
        txn.merge_request_parameters(params)
      end
    end
  end
end
