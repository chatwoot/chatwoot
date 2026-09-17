class Captain::Apropos::SchemeExtensions
  def self.install(scheme)
    scheme.register('filter') do |function, items|
      Captain::Apropos::CoreFunctions.typed(items, Array).reject { |item| scheme.call(function, [item]) == false }
    end
    scheme.register('fold') do |function, initial, items|
      Captain::Apropos::CoreFunctions.typed(items, Array).reduce(initial) { |accumulator, item| scheme.call(function, [accumulator, item]) }
    end
    scheme.register('group-by') do |items, function|
      Captain::Apropos::CoreFunctions.typed(items, Array).group_by { |item| scheme.call(function, [item]) }
                                     .map { |key, group| { 'key' => key, 'items' => group } }
    end
    scheme.register('count-by') do |items, function|
      Captain::Apropos::CoreFunctions.typed(items, Array).each_with_object(Hash.new(0)) { |item, counts| counts[scheme.call(function, [item])] += 1 }
                                     .map { |key, count| { 'key' => key, 'count' => count } }
    end
    scheme.register('sort-by') { |items, key, direction = 'asc'| sort(items, key, direction) }
    scheme.register('take') do |items, count|
      raise Captain::Apropos::Error, 'take expects a list and nonnegative integer' unless items.is_a?(Array) && count.is_a?(Integer) && count >= 0

      items.take(count)
    end
    scheme.register('batches') { |items, size| batches(items, size) }
  end

  def self.batches(items, size)
    unless items.is_a?(Array) && size.is_a?(Integer) && size.positive?
      raise Captain::Apropos::Error, 'batches expects a list and a positive integer batch size'
    end

    limit = Captain::Apropos::ContextLimits::REASON_INPUT_BYTES
    items.each_slice(size).flat_map do |slice|
      bytes = 1
      slice.slice_before do |item|
        item_bytes = JSON.generate(item).bytesize + 1
        if item_bytes + 1 > limit
          raise Captain::Apropos::Error,
                "A batch item exceeds #{limit} bytes. Return fewer fields or delegate it by reference."
        end

        new_batch = bytes + item_bytes > limit
        bytes = new_batch ? 1 + item_bytes : bytes + item_bytes
        new_batch
      end.to_a
    end
  end

  def self.sort(items, key, direction)
    unless items.is_a?(Array) && key.is_a?(String) && %w[asc desc].include?(direction)
      raise Captain::Apropos::Error, 'sort-by expects a list, field-name string, and asc or desc'
    end

    items.each_with_index.sort do |(left, left_index), (right, right_index)|
      comparison = left.fetch(key) <=> right.fetch(key)
      raise Captain::Apropos::Error, 'Sort values must be comparable' if comparison.nil?

      comparison = -comparison if direction == 'desc'
      comparison.zero? ? left_index <=> right_index : comparison
    end.map(&:first)
  end
end
