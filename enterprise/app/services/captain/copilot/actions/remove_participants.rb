# Takes the same arguments as AddParticipants and checks them the same way.
class Captain::Copilot::Actions::RemoveParticipants < Captain::Copilot::Actions::AddParticipants
  NAME = 'remove_participants'.freeze
  DESCRIPTION = 'Remove agents as participants of each conversation. Arguments: user_ids, user IDs from get_account_directory.'.freeze

  def perform(conversation)
    participants = conversation.conversation_participants.where(user_id: user_ids)
    return :skipped if participants.none?

    participants.destroy_all
    :applied
  end
end
