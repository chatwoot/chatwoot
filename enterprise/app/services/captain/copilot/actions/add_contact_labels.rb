# Adds labels to contacts the same way AddLabels adds them to conversations.
class Captain::Copilot::Actions::AddContactLabels < Captain::Copilot::Actions::AddLabels
  NAME = 'add_contact_labels'.freeze
  RESOURCE = 'contacts'.freeze
  DESCRIPTION = 'Add existing account labels to each contact. Arguments: labels, an array of label titles.'.freeze
end
