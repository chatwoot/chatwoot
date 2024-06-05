module FilterHelper
  def build_condition_query(model_filters, query_hash, current_index)
    current_filter = model_filters[query_hash['attribute_key']]

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

    condition_query = build_condition_query_string(current_filter, query_hash, current_index)
    # The query becomes empty only when it doesn't match to any supported
    # standard attribute or custom attribute defined in the account.
    if condition_query.empty?
      raise CustomExceptions::CustomFilter::InvalidAttribute.new(key: query_hash['attribute_key'],
                                                                 allowed_keys: model_filters.keys)
    end

    condition_query
  end

  def build_condition_query_string(current_filter, query_hash, current_index)
    filter_operator_value = filter_operation(query_hash, current_index)

    return handle_nil_filter(query_hash, current_index) if current_filter.nil?

    case current_filter['attribute_type']
    when 'additional_attributes'
      handle_additional_attributes(query_hash, filter_operator_value, current_filter['data_type'])
    else
      handle_standard_attributes(current_filter, query_hash, current_index, filter_operator_value)
    end
  end

  def handle_nil_filter(query_hash, current_index)
    attribute_type = "#{filter_config[:entity].downcase}_attribute"
    custom_attribute_query(query_hash, attribute_type, current_index)
  end

  def handle_additional_attributes(query_hash, filter_operator_value, data_type)
    if data_type == 'text_case_insensitive'
      "LOWER(#{filter_config[:table_name]}.additional_attributes ->> '#{query_hash[:attribute_key]}') " \
        "#{filter_operator_value} #{query_hash[:query_operator]}"
    else
      "#{filter_config[:table_name]}.additional_attributes ->> '#{query_hash[:attribute_key]}' " \
        "#{filter_operator_value} #{query_hash[:query_operator]} "
    end
  end

  def handle_standard_attributes(current_filter, query_hash, current_index, filter_operator_value)
    case current_filter['data_type']
    when 'date'
      date_filter(current_filter, query_hash, filter_operator_value)
    when 'labels'
      tag_filter_query(query_hash, current_index)
    when 'text_case_insensitive'
      text_case_insensitive_filter(query_hash, filter_operator_value)
    else
      default_filter(query_hash, filter_operator_value)
    end
  end

  def date_filter(current_filter, query_hash, filter_operator_value)
    "(#{filter_config[:table_name]}.#{query_hash[:attribute_key]})::#{current_filter['data_type']} " \
      "#{filter_operator_value}#{current_filter['data_type']} #{query_hash[:query_operator]}"
  end

  def text_case_insensitive_filter(query_hash, filter_operator_value)
    "LOWER(#{filter_config[:table_name]}.#{query_hash[:attribute_key]}) " \
      "#{filter_operator_value} #{query_hash[:query_operator]}"
  end

  def default_filter(query_hash, filter_operator_value)
    "#{filter_config[:table_name]}.#{query_hash[:attribute_key]} #{filter_operator_value} #{query_hash[:query_operator]}"
  end
end
