# The changes Copilot can propose. Each one runs only after the agent approves it in the Copilot panel.
module Captain::Copilot::Actions
  def self.all
    [Captain::Copilot::Actions::AddLabels, Captain::Copilot::Actions::RemoveLabels, Captain::Copilot::Actions::AssignAgent,
     Captain::Copilot::Actions::AssignTeam, Captain::Copilot::Actions::SetStatus, Captain::Copilot::Actions::SetPriority,
     Captain::Copilot::Actions::AddPrivateNote, Captain::Copilot::Actions::SendReply, Captain::Copilot::Actions::SetCustomAttributes,
     Captain::Copilot::Actions::RemoveCustomAttributes, Captain::Copilot::Actions::AddParticipants,
     Captain::Copilot::Actions::RemoveParticipants, Captain::Copilot::Actions::ApplySla, Captain::Copilot::Actions::Mute,
     Captain::Copilot::Actions::Unmute]
  end

  def self.build(name, account:, user:, arguments:, proposal_values: {})
    action = all.find { |candidate| name == candidate::NAME }
    raise ArgumentError, "Unknown action #{name}. Available actions: #{all.map { |candidate| candidate::NAME }.join(', ')}" unless action

    action.new(account: account, user: user, arguments: arguments, proposal_values: proposal_values)
  end
end
