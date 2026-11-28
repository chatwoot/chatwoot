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
    else
      current_val.is_a?(String) ? current_val.downcase : current_val
    end
  end

  def build_condition_query_string(current_filter, query_hash, current_index)
    return super unless query_hash[:attribute_key] == 'country_code'

    key = "country_predicate_#{current_index}"
    @filter_values[key] = country_predicate(query_hash)
    ":#{key} #{query_hash[:query_operator]}"
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

  def country_predicate(query_hash)
    value = query_hash['values'][0]
    code = CountryCodeNormalizer.normalize(value) || value.to_s.strip.upcase
    expression = canonical_country_expression
    query_hash[:filter_operator] == 'equal_to' ? expression.eq(code) : expression.not_eq(code)
  end

  def canonical_country_expression
    table = Contact.arel_table
    attributes = table[:additional_attributes]
    codes = table.cast(Arel::Nodes.build_quoted(CountryCodeNormalizer.country_codes_by_value.to_json), 'jsonb')
    sources = [table[:country_code], json_text(attributes, 'country_code'), json_text(attributes, 'country')]
    normalized = sources.map do |source|
      trimmed = Arel::Nodes::NamedFunction.new('BTRIM', [source])
      json_text(codes, table.lower(trimmed))
    end
    table.coalesce(*normalized)
  end

  def json_text(source, key)
    Arel::Nodes::InfixOperation.new('->>', source, Arel::Nodes.build_quoted(key))
  end

  def equals_to_filter_string(filter_operator, current_index)
    return "= :value_#{current_index}" if filter_operator == 'equal_to'

    "!= :value_#{current_index}"
  end
end
