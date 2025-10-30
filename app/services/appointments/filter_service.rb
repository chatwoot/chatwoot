class Appointments::FilterService < FilterService
  ATTRIBUTE_MODEL = 'appointment_attribute'.freeze

  def initialize(account, user, params)
    @account = account
    super(params, user)
  end

  def perform
    validate_query_operator
    @appointments = query_builder(@filters['appointments'])

    {
      appointments: @appointments,
      count: @appointments.count
    }
  end

  def filter_values(query_hash)
    attribute_key = query_hash['attribute_key']
    current_val = query_hash['values'][0]

    # Handle boolean values for assisted field
    return current_val == 'true' || current_val == true if attribute_key == 'assisted'

    current_val.is_a?(String) ? current_val.downcase : current_val
  end

  def base_relation
    @account.appointments.left_joins(:contact)
  end

  def filter_config
    {
      entity: 'Appointment',
      table_name: 'appointments'
    }
  end

  def build_condition_query_string(current_filter, query_hash, current_index)
    # Handle contact attributes
    if current_filter && current_filter['attribute_type'] == 'contact'
      attribute_key = query_hash[:attribute_key]
      contact_field = attribute_key == 'contact_name' ? 'name' : 'email'
      return build_contact_query(contact_field, query_hash, current_index)
    end

    # Handle standard appointment attributes
    super
  end

  private

  def build_contact_query(contact_field, query_hash, current_index)
    filter_operator = query_hash[:filter_operator]
    query_operator = query_hash[:query_operator]

    case filter_operator
    when 'equal_to', 'not_equal_to'
      value = query_hash['values'][0]
      @filter_values["value_#{current_index}"] = value.is_a?(String) ? value.downcase : value
      operator = filter_operator == 'equal_to' ? '=' : '!='
      "LOWER(contacts.#{contact_field}) #{operator} :value_#{current_index} #{query_operator || ''}"
    when 'contains', 'does_not_contain'
      value = query_hash['values'][0] || ''
      @filter_values["value_#{current_index}"] = "%#{value.to_s.downcase}%"
      operator = filter_operator == 'contains' ? 'ILIKE' : 'NOT ILIKE'
      "contacts.#{contact_field} #{operator} :value_#{current_index} #{query_operator || ''}"
    end
  end

  def equals_to_filter_string(filter_operator, current_index)
    return "= :value_#{current_index}" if filter_operator == 'equal_to'

    "!= :value_#{current_index}"
  end
end
