# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module ParameterFiltering
      extend self

      ACTION_DISPATCH_PARAMETER_FILTER ||= 'action_dispatch.parameter_filter'.freeze

      if defined?(Rails) && Gem::Version.new(::Rails::VERSION::STRING) >= Gem::Version.new('5.0.0')
        Rails.application.config.to_prepare do
          RAILS_FILTER_CLASS ||= if defined?(ActiveSupport::ParameterFilter)
            ActiveSupport::ParameterFilter
          elsif defined?(ActionDispatch::Http::ParameterFilter)
            ActionDispatch::Http::ParameterFilter
          end
        end
      else
        RAILS_FILTER_CLASS ||= if defined?(ActiveSupport::ParameterFilter)
          ActiveSupport::ParameterFilter
        elsif defined?(ActionDispatch::Http::ParameterFilter)
          ActionDispatch::Http::ParameterFilter
        end
      end

      def apply_filters(env, params)
        if filters = env[ACTION_DISPATCH_PARAMETER_FILTER]
          params = filter_using_rails(params, filters)
        end
        params = filter_rack_file_data(env, params)
        params
      end

      def filter_using_rails(params, filters)
        return params unless rails_filter_class?

        pre_filtered_params = filter_rails_request_parameters(params)
        RAILS_FILTER_CLASS.new(filters).filter(pre_filtered_params)
      end

      def filter_rack_file_data(env, params)
        content_type = env['CONTENT_TYPE']
        multipart = content_type&.start_with?('multipart')

        params.inject({}) do |memo, (k, v)|
          if multipart && v.is_a?(Hash) && v[:tempfile]
            memo[k] = '[FILE]'
          else
            memo[k] = v
          end
          memo
        end
      end

      def filter_rails_request_parameters(params)
        result = params.dup
        result.delete('controller')
        result.delete('action')
        result
      end

      private

      def rails_filter_class?
        defined?(RAILS_FILTER_CLASS) && !RAILS_FILTER_CLASS.nil?
      end
    end
  end
end
