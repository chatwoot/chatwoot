class Captain::Copilot::Actions::UnblockContacts < Captain::Copilot::Actions::BaseAction
  NAME = 'unblock_contacts'.freeze
  RESOURCE = 'contacts'.freeze
  DESCRIPTION = 'Unblock each contact. Arguments: none, pass an empty object.'.freeze
  ARGUMENTS = { type: 'object', additionalProperties: false, properties: {} }.deep_stringify_keys.freeze

  # The same write as the dashboard's unblock button on the contact page.
  def perform(contact)
    return :skipped unless contact.blocked?

    contact.update!(blocked: false)
    :applied
  end
end
