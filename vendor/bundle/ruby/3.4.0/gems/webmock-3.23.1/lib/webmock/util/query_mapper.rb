# frozen_string_literal: true

module WebMock::Util
  class QueryMapper
    class << self
      #This class is based on Addressable::URI pre 2.3.0

      ##
      # Converts the query component to a Hash value.
      #
      # @option [Symbol] notation
      #   May be one of <code>:flat</code>, <code>:dot</code>, or
      #   <code>:subscript</code>. The <code>:dot</code> notation is not
      #   supported for assignment. Default value is <code>:subscript</code>.
      #
      # @return [Hash, Array] The query string parsed as a Hash or Array object.
      #
      # @example
      #   WebMock::Util::QueryMapper.query_to_values("?one=1&two=2&three=3")
      #   #=> {"one" => "1", "two" => "2", "three" => "3"}
      #   WebMock::Util::QueryMapper("?one[two][three]=four").query_values
      #   #=> {"one" => {"two" => {"three" => "four"}}}
      #   WebMock::Util::QueryMapper.query_to_values("?one.two.three=four",
      #     :notation => :dot
      #   )
      #   #=> {"one" => {"two" => {"three" => "four"}}}
      #   WebMock::Util::QueryMapper.query_to_values("?one[two][three]=four",
      #     :notation => :flat
      #   )
      #   #=> {"one[two][three]" => "four"}
      #   WebMock::Util::QueryMapper.query_to_values("?one.two.three=four",
      #     :notation => :flat
      #   )
      #   #=> {"one.two.three" => "four"}
      #   WebMock::Util::QueryMapper(
      #     "?one[two][three][]=four&one[two][three][]=five"
      #   )
      #   #=> {"one" => {"two" => {"three" => ["four", "five"]}}}
      #   WebMock::Util::QueryMapper.query_to_values(
      #     "?one=two&one=three").query_values(:notation => :flat_array)
      #   #=> [['one', 'two'], ['one', 'three']]
      def query_to_values(query, options={})
        return nil if query.nil?
        query = query.dup.force_encoding('utf-8') if query.respond_to?(:force_encoding)

        options[:notation] ||= :subscript

        if ![:flat, :dot, :subscript, :flat_array].include?(options[:notation])
          raise ArgumentError,
                'Invalid notation. Must be one of: ' +
                '[:flat, :dot, :subscript, :flat_array].'
        end

        empty_accumulator = :flat_array == options[:notation] ? [] : {}

        query_array = collect_query_parts(query)

        query_hash = collect_query_hash(query_array, empty_accumulator, options)

        normalize_query_hash(query_hash, empty_accumulator, options)
      end

      def normalize_query_hash(query_hash, empty_accumulator, options)
        query_hash.inject(empty_accumulator.dup) do |accumulator, (key, value)|
          if options[:notation] == :flat_array
            accumulator << [key, value]
          else
            accumulator[key] = value.kind_of?(Hash) ? dehash(value) : value
          end
          accumulator
        end
      end

      def collect_query_parts(query)
        query_parts = query.split('&').map do |pair|
          pair.split('=', 2) if pair && !pair.empty?
        end
        query_parts.compact
      end

      def collect_query_hash(query_array, empty_accumulator, options)
        query_array.compact.inject(empty_accumulator.dup) do |accumulator, (key, value)|
          value = if value.nil?
                    nil
                  else
                    ::Addressable::URI.unencode_component(value.tr('+', ' '))
                  end
          key = Addressable::URI.unencode_component(key)
          key = key.dup.force_encoding(Encoding::ASCII_8BIT) if key.respond_to?(:force_encoding)
          self.__send__("fill_accumulator_for_#{options[:notation]}", accumulator, key, value)
          accumulator
        end
      end

      def fill_accumulator_for_flat(accumulator, key, value)
        if accumulator[key]
          raise ArgumentError, "Key was repeated: #{key.inspect}"
        end
        accumulator[key] = value
      end

      def fill_accumulator_for_flat_array(accumulator, key, value)
        accumulator << [key, value]
      end

      def fill_accumulator_for_dot(accumulator, key, value)
        array_value = false
        subkeys = key.split(".")
        current_hash = accumulator
        subkeys[0..-2].each do |subkey|
          current_hash[subkey] = {} unless current_hash[subkey]
          current_hash = current_hash[subkey]
        end
        if array_value
          if current_hash[subkeys.last] && !current_hash[subkeys.last].is_a?(Array)
            current_hash[subkeys.last] = [current_hash[subkeys.last]]
          end
          current_hash[subkeys.last] = [] unless current_hash[subkeys.last]
          current_hash[subkeys.last] << value
        else
          current_hash[subkeys.last] = value
        end
      end

      def fill_accumulator_for_subscript(accumulator, key, value)
        current_node = accumulator
        subkeys = key.split(/(?=\[[^\[\]]+)/)
        subkeys[0..-2].each do |subkey|
          node = subkey =~ /\[\]\z/ ? [] : {}
          subkey = subkey.gsub(/[\[\]]/, '')
          if current_node.is_a? Array
            container = current_node.find { |n| n.is_a?(Hash) && n.has_key?(subkey) }
            if container
              current_node = container[subkey]
            else
              current_node << {subkey => node}
              current_node = node
            end
          else
            current_node[subkey] = node unless current_node[subkey]
            current_node = current_node[subkey]
          end
        end
        last_key = subkeys.last
        array_value = !!(last_key =~ /\[\]$/)
        last_key = last_key.gsub(/[\[\]]/, '')
        if current_node.is_a? Array
          last_container = current_node.select { |n| n.is_a?(Hash) }.last
          if last_container && !last_container.has_key?(last_key)
            if array_value
              last_container[last_key] ||= []
              last_container[last_key] << value
            else
              last_container[last_key] = value
            end
          else
            if array_value
              current_node << {last_key => [value]}
            else
              current_node << {last_key => value}
            end
          end
        else
          if array_value
            current_node[last_key] ||= []
            current_node[last_key] << value unless value.nil?
          else
            current_node[last_key] = value
          end
        end
      end

      ##
      # Sets the query component for this URI from a Hash object.
      # This method produces a query string using the :subscript notation.
      # An empty Hash will result in a nil query.
      #
      # @param [Hash, #to_hash, Array] new_query_values The new query values.
      def values_to_query(new_query_values, options = {})
        options[:notation] ||= :subscript
        return if new_query_values.nil?

        unless new_query_values.is_a?(Array)
          unless new_query_values.respond_to?(:to_hash)
            raise TypeError,
                  "Can't convert #{new_query_values.class} into Hash."
          end
          new_query_values = new_query_values.to_hash
          new_query_values = new_query_values.inject([]) do |object, (key, value)|
            key = key.to_s if key.is_a?(::Symbol) || key.nil?
            if value.is_a?(Array) && value.empty?
              object << [key.to_s + '[]']
            elsif value.is_a?(Array)
              value.each { |v| object << [key.to_s + '[]', v] }
            elsif value.is_a?(Hash)
              value.each { |k, v| object << ["#{key.to_s}[#{k}]", v]}
            else
              object << [key.to_s, value]
            end
            object
          end
          # Useful default for OAuth and caching.
          # Only to be used for non-Array inputs. Arrays should preserve order.
          begin
            new_query_values.sort! # may raise for non-comparable values
          rescue NoMethodError, ArgumentError
            # ignore
          end
        end

        buffer = ''.dup
        new_query_values.each do |parent, value|
          encoded_parent = ::Addressable::URI.encode_component(
              parent.dup, ::Addressable::URI::CharacterClasses::UNRESERVED
          )
          buffer << "#{to_query(encoded_parent, value, options)}&"
        end
        buffer.chop
      end

      def dehash(hash)
        hash.each do |(key, value)|
          if value.is_a?(::Hash)
            hash[key] = self.dehash(value)
          end
        end
        if hash != {} && hash.keys.all? { |key| key =~ /^\d+$/ }
          hash.sort.inject([]) do |accu, (_, value)|
            accu << value; accu
          end
        else
          hash
        end
      end

      ##
      # Joins and converts parent and value into a properly encoded and
      # ordered URL query.
      #
      # @private
      # @param [String] parent an URI encoded component.
      # @param [Array, Hash, Symbol, #to_str] value
      #
      # @return [String] a properly escaped and ordered URL query.

      # new_query_values have form [['key1', 'value1'], ['key2', 'value2']]
      def to_query(parent, value, options = {})
        options[:notation] ||= :subscript
        case value
        when ::Hash
          value = value.map do |key, val|
            [
              ::Addressable::URI.encode_component(key.to_s.dup, ::Addressable::URI::CharacterClasses::UNRESERVED),
              val
            ]
          end
          value.sort!
          buffer = ''.dup
          value.each do |key, val|
            new_parent = options[:notation] != :flat_array ? "#{parent}[#{key}]" : parent
            buffer << "#{to_query(new_parent, val, options)}&"
          end
          buffer.chop
        when ::Array
          buffer = ''.dup
          value.each_with_index do |val, i|
            new_parent = options[:notation] != :flat_array ? "#{parent}[#{i}]" : parent
            buffer << "#{to_query(new_parent, val, options)}&"
          end
          buffer.chop
        when NilClass
          parent
        else
          encoded_value = Addressable::URI.encode_component(
            value.to_s.dup, Addressable::URI::CharacterClasses::UNRESERVED
          )
          "#{parent}=#{encoded_value}"
        end
      end
    end

  end
end
