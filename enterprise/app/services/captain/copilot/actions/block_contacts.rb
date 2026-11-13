class Captain::Copilot::Actions::BlockContacts < Captain::Copilot::Actions::BaseAction
  NAME = 'block_contacts'.freeze
  RESOURCE = 'contacts'.freeze
  DESCRIPTION = "Block each contact, so the contact's new messages do not notify the team or reopen conversations. " \
                'Arguments: none, pass an empty object.'.freeze
  ARGUMENTS = { type: 'object', additionalProperties: false, properties: {} }.deep_stringify_keys.freeze

  # The same write as the dashboard's block button on the contact page.
  def perform(contact)
    return :skipped if contact.blocked?

    contact.update!(blocked: true)
    :applied
  end

  def card(_ids)
    super.merge(warning: 'BLOCK_CONTACTS')
  end
end
