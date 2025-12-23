# frozen_string_literal: true

module Lograge
  module Formatters
    class Graylog2
      include Lograge::Formatters::Helpers::MethodAndPath

      def call(data)
        # Add underscore to every key to follow GELF additional field syntax.
        data.transform_keys { |k| underscore_prefix(k) }.merge(
          short_message: short_message(data)
        )
      end

      def underscore_prefix(key)
        "_#{key}".to_sym
      end

      def short_message(data)
        "[#{data[:status]}]#{method_and_path_string(data)}(#{data[:controller]}##{data[:action]})"
      end
    end
  end
end
