class Captain::Tools::SearchContactsTool < Captain::Tools::BaseAgentTool
  description 'Search contacts based on parameters'
  param :query, type: 'string', desc: 'Search contacts by name, email, phone', required: false
  param :inbox_id, type: 'number', desc: 'Filter contacts by inbox ID', required: false
  param :labels, type: 'string', desc: 'Filter contacts by labels (comma-separated)', required: false

  def perform(_tool_context, query: nil, inbox_id: nil, labels: nil)
    log_tool_usage('search_contacts', { query: query, inbox_id: inbox_id, labels: labels })

    contacts = get_contacts(query, inbox_id, labels)

    return 'No contacts found' unless contacts.exists?

    total_count = contacts.count
    contacts = contacts.limit(100)

    <<~RESPONSE
      #{total_count > 100 ? "Found #{total_count} contacts (showing first 100)" : "Total number of contacts: #{total_count}"}
      #{contacts.map(&:to_llm_text).join("\n---\n")}
    RESPONSE
  end

  protected

  def required_permission
    'contact_manage'
  end

  private

  def get_contacts(query, inbox_id, labels)
    contacts = account_scoped(Contact)

    if query.present?
      contacts = contacts.where(
        'name ILIKE :query OR email ILIKE :query OR phone_number ILIKE :query',
        query: "%#{query}%"
      )
    end

    contacts = contacts.where(inbox_id: inbox_id) if inbox_id.present?
    if labels.present?
      label_array = labels.split(',').map(&:strip)
      contacts = contacts.tagged_with(label_array, any: true)
    end
    contacts
  end
end