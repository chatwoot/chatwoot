class MockRedis
  module UtilityMethods
    private

    def with_thing_at(key, assertion, empty_thing_generator)
      send(assertion, key)
      data[key] ||= empty_thing_generator.call
      data_key_ref = data[key]
      ret = yield data[key]
      data[key] = data_key_ref if data[key].nil?
      primitive?(ret) ? ret.dup : ret
    ensure
      clean_up_empties_at(key)
    end

    def primitive?(value)
      value.is_a?(::Array) || value.is_a?(::Hash) || value.is_a?(::String)
    end

    def clean_up_empties_at(key)
      if data[key]&.empty? && data[key] != '' && !data[key].is_a?(Stream)
        del(key)
      end
    end

    def common_scan(values, cursor, opts = {})
      count = (opts[:count] || 10).to_i
      cursor = cursor.to_i
      match = opts[:match] || '*'
      key = opts[:key] || lambda { |x| x }
      filtered_values = []

      limit = cursor + count
      next_cursor = limit >= values.length ? '0' : limit.to_s

      unless values[cursor...limit].nil?
        filtered_values = values[cursor...limit].select do |val|
          redis_pattern_to_ruby_regex(match).match(key.call(val))
        end
      end

      [next_cursor, filtered_values]
    end

    def twos_complement_encode(n, size)
      if n < 0
        str = (n + 1).abs.to_s(2)

        binary = left_pad(str, size - 1).chars.map { |c| c == '0' ? 1 : 0 }
        binary.unshift(1)
      else
        binary = left_pad(n.abs.to_s(2), size - 1).chars.map(&:to_i)
        binary.unshift(0)
      end

      binary
    end

    def twos_complement_decode(array)
      total = 0

      array.each.with_index do |bit, index|
        total += 2**(array.length - index - 1) if bit == 1
        total = -total if index == 0
      end

      total
    end

    def left_pad(str, size)
      str = '0' + str while str.length < size

      str
    end
  end
end
