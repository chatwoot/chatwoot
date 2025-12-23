require 'shoulda/matchers/util/word_wrap'

module Shoulda
  module Matchers
    # @private
    module Util
      MAXIMUM_LENGTH_OF_VALUE_TO_DISPLAY = 500

      def self.deconstantize(path)
        if (
          defined?(ActiveSupport::Inflector) &&
          ActiveSupport::Inflector.respond_to?(:deconstantize)
        )
          ActiveSupport::Inflector.deconstantize(path)
        else
          path.to_s[0...(path.to_s.rindex('::') || 0)]
        end
      end

      def self.safe_constantize(camel_cased_word)
        if (
          defined?(ActiveSupport::Inflector) &&
          ActiveSupport::Inflector.respond_to?(:safe_constantize)
        )
          ActiveSupport::Inflector.safe_constantize(camel_cased_word)
        else
          begin
            camel_cased_word.constantize
          rescue NameError
            nil
          end
        end
      end

      def self.indent(string, width)
        return if !string

        indentation = ' ' * width
        string.split(/[\n\r]/).map { |line| indentation + line }.join("\n")
      end

      def self.a_or_an(next_word)
        if next_word =~ /\A[aeiou]/i && next_word != 'unique'
          "an #{next_word}"
        else
          "a #{next_word}"
        end
      end

      def self.inspect_value(value)
        case value
        when Hash
          inspect_hash(value)
        when Range
          inspect_range(value)
        else
          inspected_value = value.inspect
          if inspected_value.length > MAXIMUM_LENGTH_OF_VALUE_TO_DISPLAY
            "‹#{inspected_value[0, MAXIMUM_LENGTH_OF_VALUE_TO_DISPLAY]}...›"
          else
            "‹#{inspected_value}›"
          end
        end
      end

      def self.inspect_values(values)
        values.map { |value| inspect_value(value) }
      end

      def self.inspect_range(range)
        "#{inspect_value(range.first)} to #{inspect_value(range.last)}"
      end

      def self.inspect_hash(hash)
        output = '‹{'

        output << hash.map { |key, value|
          if key.is_a?(Symbol)
            "#{key}: #{value.inspect}"
          else
            "#{key.inspect} => #{value.inspect}"
          end
        }.join(', ')

        output << '}›'
      end

      def self.dummy_value_for(column_type, array: false)
        if array
          [dummy_value_for(column_type, array: false)]
        else
          case column_type
          when :integer
            0
          when :date
            Date.new(2100, 1, 1)
          when :datetime, :timestamp
            DateTime.new(2100, 1, 1)
          when :time
            Time.new(2000, 1, 1)
          when :uuid
            SecureRandom.uuid
          when :boolean
            true
          else
            'dummy value'
          end
        end
      end
    end
  end
end
