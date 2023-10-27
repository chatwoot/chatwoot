module FilterHelper
  def build_condition_query(current_filter, query_hash, current_index)
    # Throw InvalidOperator Error if the attribute is a standard attribute
    # and the operator is not allowed in the config
    if current_filter.present? && current_filter['filter_operators'].exclude?(query_hash[:filter_operator])
      raise CustomExceptions::CustomFilter::InvalidOperator.new(
        attribute_name: query_hash['attribute_key'],
        allowed_keys: current_filter['filter_operators']
      )
    end

    # Every other filter expects a value to be present
    if %w[is_present is_not_present].exclude?(query_hash[:filter_operator]) && query_hash['values'].blank?
      raise CustomExceptions::CustomFilter::InvalidValue.new(attribute_name: query_hash['attribute_key'])
    end

    condition_query = build_query_string(current_filter, query_hash, current_index)
    # The query becomes empty only when it doesn't match to any supported
    # standard attribute or custom attribute defined in the account.
    raise CustomExceptions::CustomFilter::InvalidAttribute.new(allowed_keys: model_filters.keys) if condition_query.empty?

    condition_query
  end
end
