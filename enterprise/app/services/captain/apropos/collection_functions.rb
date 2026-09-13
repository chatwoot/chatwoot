module Captain::Apropos::CollectionFunctions
  private

  def install_ranking
    register('count-by') do |items, function|
      validate_collection_call!(function, items)
      items.each_with_object(Hash.new(0)) { |item, counts| counts[invoke(function, [item])] += 1 }
           .map { |key, count| { 'key' => key, 'count' => count } }
    end
    register('sort-by') { |items, key, direction = 'asc'| sort_records(items, key, direction) }
    register('take') do |items, count|
      raise Captain::Apropos::Error, 'take expects a nonnegative integer' unless count.is_a?(Integer) && count >= 0

      items.take(count)
    end
  end

  def sort_records(items, key, direction)
    validate_sort!(items, key, direction)

    items.each_with_index.sort do |(left, left_index), (right, right_index)|
      comparison = left.fetch(key.to_s) <=> right.fetch(key.to_s)
      raise Captain::Apropos::Error, 'Sort values must be comparable' if comparison.nil?

      comparison = -comparison if direction == 'desc'
      comparison.zero? ? left_index <=> right_index : comparison
    end.map(&:first)
  end

  def validate_sort!(items, key, direction)
    unless items.is_a?(Array) && key.is_a?(String)
      raise Captain::Apropos::Error, 'Expected a list, a field-name string, and optional direction; not a key function'
    end
    raise Captain::Apropos::Error, 'Sort direction must be asc or desc' unless %w[asc desc].include?(direction)
  end

  def validate_collection_call!(function, items)
    return if items.is_a?(Array) && (function.is_a?(Proc) || function.is_a?(self.class::Closure))

    raise Captain::Apropos::Error, 'Expected a function and a list; inspect the contract for their argument order'
  end
end
