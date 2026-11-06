class Captain::Copilot::Resources::Contacts < Captain::Copilot::Resources::BaseResource
  NAME = 'contacts'.freeze
  MODEL = Contact
  DATE_FIELDS = %w[last_activity_at created_at].freeze
  FILTERS = {
    search: { type: 'string', minLength: 2, description: 'Matches name, email or phone number' },
    labels: { type: 'array', minItems: 1, items: { type: 'string' }, description: 'Contacts with any of these labels' }
  }.freeze
  # A message's sender is polymorphic, so the customers of messages are reached through their conversations.
  SOURCES = { 'messages' => ->(messages) { Contact.of_conversations(messages.select(:conversation_id)) } }.freeze
  COLUMNS = %w[Email Phone Company Labels].freeze
  PRELOAD = [:company, :labels].freeze
  GROUPS = %w[label country].freeze

  # Contact details follow the same permission as the contacts page and the get_contact tool.
  def readable?
    permitted?('contact_manage')
  end

  def scope
    raise ArgumentError, 'You do not have permission to view contacts' unless readable?

    @account.contacts
  end

  # Contacts asked about directly are the ones the contacts page lists, so counts match it. Contacts reached from
  # conversations or messages keep anonymous visitors, because they are the customers in those conversations.
  def matching(filters, as_of:, source: nil, **)
    relation = super
    source ? relation : relation.resolved_contacts(use_crm_v2: @account.feature_enabled?('crm_v2'))
  end

  def filter(relation, filters)
    relation = relation.tagged_with(filters['labels'], any: true) if filters['labels'].present?
    return relation if filters['search'].blank?

    term = "%#{Contact.sanitize_sql_like(filters['search'])}%"
    table = Contact.arel_table
    relation.where(table[:name].matches(term).or(table[:email].matches(term)).or(table[:phone_number].matches(term)))
  end

  # Contacts saved before country_code was synced from additional_attributes store a missing country as an empty string.
  def group_field(name)
    return unless name == 'country'

    country_code = Contact.arel_table[:country_code]
    { expression: Arel::Nodes::Case.new.when(country_code.not_eq('')).then(country_code) }
  end

  def row(contact)
    { label: contact.name.presence || "Contact ##{contact.id}", url: url("contacts/#{contact.id}"),
      values: [contact.email, contact.phone_number, contact.company&.name, contact.labels.map(&:name).join(', ')] }
  end
end
