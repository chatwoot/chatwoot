module Filters::CustomAttributeFilterHelper
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
    filter_operator_value = filter_operation(query_hash, current_index)
    query_operator = query_hash[:query_operator]
    table_name = attribute_model == 'conversation_attribute' ? 'conversations' : 'contacts'

    query = if attribute_data_type == 'text'
              ActiveRecord::Base.sanitize_sql_array(
                ["LOWER(#{table_name}.custom_attributes ->> ?)::#{attribute_data_type} #{filter_operator_value} #{query_operator} ", @attribute_key]
              )
            else
              ActiveRecord::Base.sanitize_sql_array(
                ["(#{table_name}.custom_attributes ->> ?)::#{attribute_data_type} #{filter_operator_value} #{query_operator} ", @attribute_key]
              )
            end

    query + not_in_custom_attr_query(table_name, query_hash, attribute_data_type)
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
