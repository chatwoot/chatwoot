module Filters::CustomAttributeFilterHelper
  NUMERIC_FILTER_OPERATORS = %w[equal_to not_equal_to is_present is_not_present is_greater_than is_less_than].freeze

  def custom_attribute_query(query_hash, custom_attribute_type, current_index)
    @attribute_key = query_hash[:attribute_key]
    @custom_attribute_type = custom_attribute_type
    attribute_data_type
    return '' if @custom_attribute.blank?

    build_custom_attr_query(query_hash, current_index)
  end

  private

  def attribute_model
    @attribute_model = @custom_attribute_type.presence || self.class::ATTRIBUTE_MODEL
  end

  def attribute_data_type
    attribute_type = custom_attribute(@attribute_key, @account, attribute_model).try(:attribute_display_type)
    @attribute_data_type = self.class::ATTRIBUTE_TYPES[attribute_type]
  end

  def build_custom_attr_query(query_hash, current_index)
    validate_custom_attribute_values!(query_hash)
    validate_numeric_filter_operator!(query_hash[:filter_operator])
    filter_operator_value = filter_operation(query_hash, current_index)
    data_type = attribute_data_type
    table_name = attribute_model == 'conversation_attribute' ? 'conversations' : 'contacts'
    attribute_expression = data_type == 'text' ? "LOWER(#{table_name}.custom_attributes ->> ?)" : "(#{table_name}.custom_attributes ->> ?)"

    condition = ActiveRecord::Base.sanitize_sql_array(
      ["#{attribute_expression}::#{data_type} #{filter_operator_value}", @attribute_key]
    )
    condition += not_in_custom_attr_query(table_name, query_hash, data_type)

    # The condition is wrapped so the optional `OR ... IS NULL` clause stays scoped to this attribute
    # instead of spilling over the query operator that chains it to the next condition.
    "(#{condition}) #{query_hash[:query_operator]} "
  end

  def validate_numeric_filter_operator!(filter_operator)
    return unless @attribute_data_type == 'numeric'
    return if NUMERIC_FILTER_OPERATORS.include?(filter_operator)

    raise CustomExceptions::CustomFilter::InvalidOperator.new(attribute_name: @attribute_key, allowed_keys: NUMERIC_FILTER_OPERATORS)
  end

  def validate_custom_attribute_values!(query_hash)
    return unless @attribute_data_type.in?(%w[date numeric])
    return if query_hash[:filter_operator].in?(%w[is_present is_not_present])
    return if @attribute_data_type == 'date' && query_hash[:filter_operator] == 'days_before'

    Array(query_hash[:values]).each do |value|
      coerce_lt_gt_value(value, @attribute_data_type, @attribute_key)
    end
  end

  def custom_attribute(attribute_key, account, custom_attribute_type)
    current_account = account || Current.account
    attribute_model = custom_attribute_type.presence || self.class::ATTRIBUTE_MODEL
    @custom_attribute = current_account.custom_attribute_definitions.where(
      attribute_model: attribute_model
    ).find_by(attribute_key: attribute_key)
  end

  def not_in_custom_attr_query(table_name, query_hash, attribute_data_type)
    return '' unless query_hash[:filter_operator] == 'not_equal_to'

    ActiveRecord::Base.sanitize_sql_array(
      [" OR (#{table_name}.custom_attributes ->> ?)::#{attribute_data_type} IS NULL ", @attribute_key]
    )
  end
end
