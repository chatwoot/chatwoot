class Captain::Copilot::Resources::Contacts < Captain::Copilot::Resources::BaseResource
  NAME = 'contacts'.freeze
  DATE_FIELDS = %w[last_activity_at created_at].freeze
  FILTERS = {
    search: { type: 'string', minLength: 2, description: 'Matches name, email or phone number' },
    labels: { type: 'array', items: { type: 'string' } }, company_id: { type: %w[integer null], minimum: 1, description: 'null for no company' },
    country_code: { type: 'string' }, blocked: { type: 'boolean' }
  }.freeze
  SOURCES = {
    'contacts' => ->(ids) { Contact.where(id: ids) },
    'conversations' => ->(ids) { Contact.of_conversations(ids) },
    'messages' => ->(ids) { Contact.of_messages(ids) }
  }.freeze
  COLUMNS = %w[Email Phone Company Labels].freeze
  PRELOAD = [:company, :labels].freeze
  GROUPS = %w[label country blocked].freeze

  # Contact details follow the same permission as the contacts page and the get_contact tool.
  def scope
    raise ArgumentError, 'You do not have permission to view contacts' unless permitted?('contact_manage')

    @account.contacts
  end

  # Contacts asked about directly are the ones the contacts page lists, so counts match it. Contacts reached from
  # conversations or messages keep anonymous visitors, because they are the customers in those conversations.
  def matching(filters, as_of:, source: nil)
    relation = super
    source ? relation : relation.resolved_contacts(use_crm_v2: @account.feature_enabled?('crm_v2'))
  end

  def filter(relation, filters)
    relation = relation.where(filters.slice('company_id', 'country_code', 'blocked'))
    relation = relation.tagged_with(filters['labels'], any: true) if filters['labels'].present?
    return relation if filters['search'].blank?

    term = "%#{Contact.sanitize_sql_like(filters['search'])}%"
    relation.where('contacts.name ILIKE :term OR contacts.email ILIKE :term OR contacts.phone_number ILIKE :term', term: term)
  end

  def counts_by(relation, group)
    case group
    when 'label' then label_counts(relation)
    # Contacts saved before country_code was synced from additional_attributes store a missing country as an empty string.
    when 'country' then column_counts(relation, Arel.sql("NULLIF(contacts.country_code, '')"))
    when 'blocked' then column_counts(relation, :blocked)
    end
  end

  def row(contact)
    { label: contact.name.presence || "Contact ##{contact.id}", url: url("contacts/#{contact.id}"),
      values: [contact.email, contact.phone_number, contact.company&.name, contact.labels.map(&:name).join(', ')] }
  end
end
