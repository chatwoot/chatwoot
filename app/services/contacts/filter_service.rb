class Contacts::FilterService < FilterService
  ATTRIBUTE_MODEL = 'contact_attribute'.freeze

  def initialize(account, user, params)
    @account = account
    # TODO: Change the order of arguments in FilterService maybe?
    # account, user, params makes more sense
    super(params, user)
  end

  def perform
    validate_query_operator
    @contacts = query_builder(@filters['contacts'])

    {
      contacts: @contacts,
      count: @contacts.count
    }
  end

  def filter_values(query_hash)
    values = Array.wrap(query_hash['values'])
    attribute_key = query_hash['attribute_key']

    case attribute_key
    when 'phone_number'
      values.map { |value| "+#{value.to_s.delete('+')}" }
    when 'country_code'
      values.map { |value| value.to_s.downcase }
    when 'assigned_agent_id'
      values.map { |value| value.to_i }
    else
      values.map { |value| value.is_a?(String) ? value.downcase : value }
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
end
