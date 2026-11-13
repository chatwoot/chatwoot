# Sets contact attributes the same way SetCustomAttributes sets conversation attributes.
class Captain::Copilot::Actions::SetContactAttributes < Captain::Copilot::Actions::SetCustomAttributes
  NAME = 'set_contact_attributes'.freeze
  RESOURCE = 'contacts'.freeze
  ATTRIBUTE_MODEL = 'contact_attribute'.freeze
  DESCRIPTION = 'Set custom attributes on each contact. Arguments: attributes, an object from attribute keys defined in the ' \
                'account to their values.'.freeze
end
