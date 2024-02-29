class Contacts::FilterService < FilterService
  ATTRIBUTE_MODEL = 'contact_attribute'.freeze

  def perform
    @contacts = query_builder(@filters['contacts'])

    {
      contacts: @contacts,
      count: @contacts.count
    }
  end

  def build_condition_query_string(current_filter, query_hash, current_index)
    attribute_key = query_hash[:attribute_key]
    query_operator = query_hash[:query_operator]
    filter_operator_value = filter_operation(query_hash, current_index)

    return custom_attribute_query(query_hash, 'contact_attribute', current_index) if current_filter.nil?

    # Handling Additional Attributes Separately
    if current_filter['attribute_type'] == 'additional_attributes'
      return " LOWER(contacts.additional_attributes ->> '#{attribute_key}') #{filter_operator_value} #{query_operator} "
    end

    case current_filter['data_type']
    when 'date'
      " (contacts.#{attribute_key})::#{current_filter['data_type']} #{filter_operator_value}#{current_filter['data_type']} #{query_operator} "
    when 'labels'
      " #{tag_filter_query('Contact', 'contacts', query_hash, current_index)} "
    else
      " LOWER(contacts.#{attribute_key}) #{filter_operator_value} #{query_operator} "
    end
  end

  def filter_values(query_hash)
    current_val = query_hash['values'][0]
    if query_hash['attribute_key'] == 'phone_number'
      "+#{current_val}"
    elsif query_hash['attribute_key'] == 'country_code'
      current_val.downcase
    else
      current_val.is_a?(String) ? current_val.downcase : current_val
    end
  end

  def base_relation
    Current.account.contacts
  end

  private

  def equals_to_filter_string(filter_operator, current_index)
    return "= :value_#{current_index}" if filter_operator == 'equal_to'

    "!= :value_#{current_index}"
  end
end
