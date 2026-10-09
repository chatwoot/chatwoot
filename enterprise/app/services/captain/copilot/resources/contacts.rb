class Captain::Copilot::Resources::Contacts < Captain::Copilot::Resources::BaseResource
  NAME = 'contacts'.freeze
  DATE_FIELDS = %w[last_activity_at created_at].freeze
  FILTERS = {
    search: { type: 'string', minLength: 2, description: 'Matches name, email or phone number' },
    labels: { type: 'array', items: { type: 'string' } }, company_id: { type: 'integer' },
    country_code: { type: 'string' }, blocked: { type: 'boolean' }
  }.freeze
  SOURCES = {
    'conversations' => ->(ids) { Contact.where(id: Conversation.where(id: ids).select(:contact_id)) },
    'messages' => ->(ids) { Contact.where(id: Conversation.where(id: Message.where(id: ids).select(:conversation_id)).select(:contact_id)) }
  }.freeze
  COLUMNS = %w[Email Phone Company Labels].freeze
  PRELOAD = [:company].freeze

  # Contact details follow the same permission as the contacts page and the get_contact tool.
  def scope
    raise ArgumentError, 'You do not have permission to view contacts' unless permitted?('contact_manage')

    @account.contacts
  end

  def filter(relation, filters)
    relation = relation.where(filters.slice('company_id', 'country_code', 'blocked'))
    relation = relation.tagged_with(filters['labels'], any: true) if filters['labels'].present?
    return relation if filters['search'].blank?

    term = "%#{Contact.sanitize_sql_like(filters['search'])}%"
    relation.where('contacts.name ILIKE :term OR contacts.email ILIKE :term OR contacts.phone_number ILIKE :term', term: term)
  end

  def row(contact)
    { label: contact.name.presence || "Contact ##{contact.id}", url: url("contacts/#{contact.id}"),
      values: [contact.email, contact.phone_number, contact.company&.name, contact.label_list.join(', ')] }
  end
end
