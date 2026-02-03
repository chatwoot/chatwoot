# frozen_string_literal: true

module Agents
  module Helpers
    module Headers
      module_function

      def normalize(headers, freeze_result: false)
        return freeze_result ? {}.freeze : {} if headers.nil? || (headers.respond_to?(:empty?) && headers.empty?)

        hash = headers.respond_to?(:to_h) ? headers.to_h : headers
        raise ArgumentError, "headers must be a Hash or respond to #to_h" unless hash.is_a?(Hash)

        result = symbolize_keys(hash)
        freeze_result ? result.freeze : result
      end

      def merge(agent_headers, runtime_headers)
        return runtime_headers if agent_headers.empty?
        return agent_headers if runtime_headers.empty?

        agent_headers.merge(runtime_headers) { |_key, _agent_value, runtime_value| runtime_value }
      end

      def symbolize_keys(hash)
        hash.transform_keys do |key|
          key.is_a?(Symbol) ? key : key.to_sym
        end
      end
      private_class_method :symbolize_keys
    end
  end
end
