require 'mock_redis/assertions'

class MockRedis
  module SortMethod
    include Assertions

    def sort(key, options = {})
      return [] if key.nil?

      enumerable = data[key]

      return [] if enumerable.nil?

      by           = options[:by]
      limit        = options[:limit] || []
      store        = options[:store]
      get_patterns = Array(options[:get])
      order        = options[:order] || 'ASC'
      direction    = order.split.first

      projected = project(enumerable, by, get_patterns)
      sorted    = sort_by(projected, direction)
      sliced    = slice(sorted, limit)

      store ? rpush(store, sliced) : sliced
    end

    private

    ASCENDING_SORT  = proc { |a, b| a.first <=> b.first }
    DESCENDING_SORT = proc { |a, b| b.first <=> a.first }

    def project(enumerable, by, get_patterns)
      enumerable.map do |*elements|
        element = elements.last
        weight  = by ? lookup_from_pattern(by, element) : element
        value   = element

        unless get_patterns.empty?
          value = get_patterns.map do |pattern|
            pattern == '#' ? element : lookup_from_pattern(pattern, element)
          end
          value = value.first if value.length == 1
        end

        [weight, value]
      end
    end

    def sort_by(projected, direction)
      sorter =
        case direction.upcase
        when 'DESC'
          DESCENDING_SORT
        when 'ASC', 'ALPHA'
          ASCENDING_SORT
        else
          raise "Invalid direction '#{direction}'"
        end

      projected.sort(&sorter).map(&:last)
    end

    def slice(sorted, limit)
      skip = limit.first || 0
      take = limit.last || sorted.length

      sorted[skip...(skip + take)] || sorted
    end

    def lookup_from_pattern(pattern, element)
      key = pattern.sub('*', element)

      if (hash_parts = key.split('->')).length > 1
        hget hash_parts.first, hash_parts.last
      else
        get key
      end
    end
  end
end
