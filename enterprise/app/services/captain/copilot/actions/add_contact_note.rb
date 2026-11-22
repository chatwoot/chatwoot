class Captain::Copilot::Actions::AddContactNote < Captain::Copilot::Actions::BaseAction
  NAME = 'add_contact_note'.freeze
  RESOURCE = 'contacts'.freeze
  DESCRIPTION = 'Add a note to each contact, as the agent. Arguments: content, the note text. The agent reads the note on the ' \
                'approval card before it is added.'.freeze
  ARGUMENTS = {
    type: 'object', additionalProperties: false, required: %w[content],
    properties: { content: { type: 'string', minLength: 1, maxLength: 150_000 } }
  }.deep_stringify_keys.freeze

  # The same write as the notes section of the contact page.
  def perform(contact)
    contact.notes.create!(content: @arguments['content'], user: @user)
    :applied
  end

  def card(_ids)
    super.merge(content: @arguments['content'])
  end
end
