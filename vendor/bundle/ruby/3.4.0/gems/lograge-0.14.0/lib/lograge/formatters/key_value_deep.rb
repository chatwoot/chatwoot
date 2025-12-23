# frozen_string_literal: true

module Lograge
  module Formatters
    class KeyValueDeep < KeyValue
      def call(data)
        super flatten_keys(data)
      end

      protected

      def flatten_keys(data, prefix = '')
        return flatten_object(data, prefix) if [Hash, Array].include? data.class

        data
      end

      def flatten_object(data, prefix)
        result = {}
        loop_on_object(data) do |key, value|
          key = "#{prefix}_#{key}" unless prefix.empty?
          if [Hash, Array].include? value.class
            result.merge!(flatten_keys(value, key))
          else
            result[key] = value
          end
        end
        result
      end

      def loop_on_object(data, &block)
        if data.instance_of? Array
          data.each_with_index do |value, index|
            yield index, value
          end
          return
        end
        data.each(&block)
      end
    end
  end
end
