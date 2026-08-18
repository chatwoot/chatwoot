class Captain::Routines::AgentTools::GetCurrentInboxAvailability < Captain::Routines::AgentTools::Base
  description 'Evaluate the current conversation inbox business-hours status at the frozen Routine execution start time'

  def name = 'get_current_inbox_availability'

  def perform(tool_context)
    perform_operation(tool_context, 'inboxes.get_availability', inbox_id: current_conversation(tool_context).inbox_id)
  end
end
