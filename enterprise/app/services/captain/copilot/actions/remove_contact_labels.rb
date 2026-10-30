# Removes labels from contacts the same way RemoveLabels removes them from conversations.
class Captain::Copilot::Actions::RemoveContactLabels < Captain::Copilot::Actions::RemoveLabels
  NAME = 'remove_contact_labels'.freeze
  RESOURCE = 'contacts'.freeze
  DESCRIPTION = 'Remove account labels from each contact. Arguments: labels, an array of label titles.'.freeze
end
