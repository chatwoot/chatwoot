class AutomationRules::BaseConditionsBuilder
  def initialize(query_hash:, current_index:, filter_values:)
    @query_hash = query_hash.with_indifferent_access
    @current_index = current_index
    @filter_values = filter_values
  end

  def build
    raise NotImplementedError, "#{self.class} must implement #build"
  end

  private

  attr_reader :query_hash, :current_index, :filter_values

  def filter_operator
    query_hash[:filter_operator]
  end

  def values
    @values ||= Array(query_hash[:values]).compact.uniq
  end

  def bind(value, prefix: 'value')
    placeholder = "#{prefix}_#{current_index}"
    filter_values[placeholder] = value
    ":#{placeholder}"
  end

  def condition(query)
    " #{query} #{query_hash[:query_operator]} "
  end
end
