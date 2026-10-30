# Takes the same arguments as AddLabels and checks them the same way.
class Captain::Copilot::Actions::RemoveLabels < Captain::Copilot::Actions::AddLabels
  NAME = 'remove_labels'.freeze
  DESCRIPTION = 'Remove account labels from each conversation. Arguments: labels, an array of label titles.'.freeze

  # The same write as the dashboard's bulk label removal.
  def perform(conversation)
    return :skipped unless conversation.label_list.intersect?(labels)

    conversation.update!(label_list: conversation.label_list - labels)
    :applied
  end
end
