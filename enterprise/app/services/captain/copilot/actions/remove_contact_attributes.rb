# Removes contact attributes the same way RemoveCustomAttributes removes conversation attributes.
class Captain::Copilot::Actions::RemoveContactAttributes < Captain::Copilot::Actions::RemoveCustomAttributes
  NAME = 'remove_contact_attributes'.freeze
  RESOURCE = 'contacts'.freeze
  DESCRIPTION = 'Remove custom attribute values from each contact. Arguments: keys, an array of attribute keys.'.freeze
end
