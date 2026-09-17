class Contacts::FilterService < FilterService
  ATTRIBUTE_MODEL = 'contact_attribute'.freeze

  def initialize(account, user, params)
    @account = account
    # TODO: Change the order of arguments in FilterService maybe?
    # account, user, params makes more sense
    super(params, user)
  end

  def perform(count: true)
    validate_query_operator
    @contacts = query_builder(@filters['contacts'])

    {
      contacts: @contacts,
      count: count ? @contacts.count : nil
    }
  end

  def filter_values(query_hash)
    current_val = query_hash['values'][0]
    if query_hash['attribute_key'] == 'phone_number'
      "+#{current_val&.delete('+')}"
    elsif query_hash['attribute_key'] == 'country_code'
      current_val.downcase
    else
      current_val.is_a?(String) ? current_val.downcase : current_val
    end
  end

  def base_relation
    @account.contacts.resolved_contacts(use_crm_v2: @account.feature_enabled?('crm_v2'))
  end

  def filter_config
    {
      entity: 'Contact',
      table_name: 'contacts'
    }
  end

  private

  def validate_string_values(query_hash)
    data_type = @filters.dig('contacts', query_hash['attribute_key'], 'data_type')
    string_values = %w[text text_case_insensitive labels].include?(data_type) ||
                    %w[contains does_not_contain].include?(query_hash['filter_operator'])
    return super unless string_values

    values = query_hash['values']
    return if values.is_a?(String) || (values.is_a?(Array) && values.all?(String))

    raise CustomExceptions::CustomFilter::InvalidValue.new(attribute_name: query_hash['attribute_key'])
  end

  def equals_to_filter_string(filter_operator, current_index)
    return "= :value_#{current_index}" if filter_operator == 'equal_to'

    "!= :value_#{current_index}"
  end
end
