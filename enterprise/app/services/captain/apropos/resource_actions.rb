class Captain::Apropos::ResourceActions
  OPERATIONS = %w[create-conversation create-contact update-contact update-label remove-label update-custom-attributes
                  unassign-agent unassign-team snooze-conversation create-contact-note update-contact-note].freeze
  CONTACT_FIELDS = { 'name' => :string, 'email' => :nullable_string, 'phone_number' => :nullable_string,
                     'identifier' => :nullable_string, 'custom_attributes' => :object }.freeze
  LABEL_FIELDS = { 'title' => :string, 'description' => :nullable_string, 'color' => :string, 'show_on_sidebar' => :boolean }.freeze
  TYPES = { string: ->(v) { v.is_a?(String) }, nullable_string: ->(v) { v.nil? || v.is_a?(String) },
            boolean: ->(v) { v == true || v == false }, object: ->(v) { v.is_a?(Hash) && v.keys.all?(String) } }.freeze

  def initialize(account:, user:)
    @account = account
    @user = user
  end

  def perform(name, record, arguments)
    raise Captain::Apropos::Error, 'Unknown resource action' unless OPERATIONS.include?(name)

    send(name.tr('-', '_'), record, arguments)
  end

  private

  def create_contact_note(contact, arguments)
    content = note_content!(arguments)
    note = contact.notes.create!(content: content, user: @user)
    { 'ref' => { 'type' => 'contact_notes', 'id' => note.id }, 'contact_id' => contact.id, 'content' => note.content, 'user_id' => note.user_id }
  end

  def update_contact_note(note, arguments)
    note.update!(content: note_content!(arguments), user: @user)
    { 'ref' => { 'type' => 'contact_notes', 'id' => note.id }, 'contact_id' => note.contact_id, 'content' => note.content, 'user_id' => note.user_id }
  end

  def note_content!(arguments)
    content = arguments.fetch('content')
    raise Captain::Apropos::Error, 'content must be a nonblank string' unless content.is_a?(String) && content.strip.present?

    content
  end

  def update_label(record, arguments)
    record.update!(attributes!(arguments.fetch('attributes'), LABEL_FIELDS))
    record.reload.attributes.slice(*LABEL_FIELDS.keys).merge('id' => record.id)
  end

  def remove_label(record, arguments)
    label = arguments.fetch('label')
    raise Captain::Apropos::Error, 'label must be a string' unless label.is_a?(String)

    record.update_labels(record.label_list - [label])
    { 'labels' => record.reload.label_list }
  end

  def update_custom_attributes(record, arguments)
    attributes = attributes!(arguments.fetch('attributes'))
    record.update!(custom_attributes: record.custom_attributes.merge(attributes))
    { 'custom_attributes' => record.reload.custom_attributes }
  end

  def unassign_agent(record, _arguments)
    record.update!(assignee: nil)
    { 'agent_id' => record.reload.assignee_id, 'team_id' => record.team_id }
  end

  def unassign_team(record, _arguments)
    record.update!(team: nil)
    { 'agent_id' => record.reload.assignee_id, 'team_id' => record.team_id }
  end

  def attributes!(value, fields = nil)
    raise Captain::Apropos::Error, 'attributes must be an object with string keys' unless TYPES.fetch(:object).call(value)
    return value unless fields

    raise Captain::Apropos::Error, "Allowed attributes: #{fields.keys.join(', ')}" unless (value.keys - fields.keys).empty?

    value.each do |key, item|
      valid = TYPES.fetch(fields.fetch(key)).call(item)
      raise Captain::Apropos::Error, "Invalid type for #{key}: expected #{fields.fetch(key)}" unless valid
    end
    value
  end

  def create_contact(_record, arguments)
    contact = @account.contacts.create!(attributes!(arguments.fetch('attributes'), CONTACT_FIELDS))
    { 'ref' => { 'type' => 'contacts', 'id' => contact.id }, 'created' => true }
  end

  def update_contact(contact, arguments)
    attributes = attributes!(arguments.fetch('attributes'), CONTACT_FIELDS).dup
    attributes['custom_attributes'] = contact.custom_attributes.merge(attributes.fetch('custom_attributes')) if attributes.key?('custom_attributes')
    contact.update!(attributes)
    contact.reload.attributes.slice(*CONTACT_FIELDS.keys).merge('ref' => { 'type' => 'contacts', 'id' => contact.id })
  end

  def create_conversation(inbox, arguments)
    id = arguments.fetch('contact_id')
    raise Captain::Apropos::Error, 'contact_id must be an integer' unless id.is_a?(Integer)

    contact = @account.contacts.find(id)
    Conversation.transaction do
      contact_inbox = contact.contact_inboxes.find_by(inbox: inbox) ||
                      ContactInboxBuilder.new(contact: contact, inbox: inbox, source_id: nil).perform
      raise Captain::Apropos::Error, 'Could not establish a contact inbox for this channel' unless contact_inbox

      conversation = ConversationBuilder.new(params: ActionController::Parameters.new, contact_inbox: contact_inbox).perform
      { 'ref' => { 'type' => 'conversations', 'id' => conversation.id }, 'display_id' => conversation.display_id,
        'created' => conversation.previously_new_record?, 'status' => conversation.status, 'inbox_id' => inbox.id, 'contact_id' => contact.id }
    end
  end

  def snooze_conversation(conversation, arguments)
    value = arguments.fetch('until')
    unless value.is_a?(String) && value.match?(/(?:Z|[+-]\d{2}:\d{2})\z/)
      raise Captain::Apropos::Error, 'until must be an ISO 8601 timestamp with a timezone'
    end

    until_time = Time.iso8601(value)
    raise Captain::Apropos::Error, 'until must be in the future' unless until_time > Time.current

    conversation.update!(status: :snoozed, snoozed_until: until_time)
    { 'status' => conversation.status, 'snoozed_until' => conversation.snoozed_until.iso8601 }
  rescue ArgumentError
    raise Captain::Apropos::Error, 'until must be an ISO 8601 timestamp with a timezone'
  end
end
