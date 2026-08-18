class Captain::Routines::AgentTools::Registry
  TOOLS = [
    Captain::Routines::AgentTools::GetCurrentConversation,
    Captain::Routines::AgentTools::GetCurrentMessages,
    Captain::Routines::AgentTools::GetCurrentContact,
    Captain::Routines::AgentTools::FindRelatedConversations,
    Captain::Routines::AgentTools::SearchKnowledge,
    Captain::Routines::AgentTools::FindAccountResource,
    Captain::Routines::AgentTools::GetCurrentInboxAvailability,
    Captain::Routines::AgentTools::GetAgentWorkload,
    Captain::Routines::AgentTools::ListAvailableAgents,
    Captain::Routines::AgentTools::LookupStripePayments,
    Captain::Routines::AgentTools::UpdateCurrentConversation,
    Captain::Routines::AgentTools::UpdateCurrentConversationAttributes,
    Captain::Routines::AgentTools::SendCurrentConversationMessage,
    Captain::Routines::AgentTools::CreateStripeRefund
  ].freeze

  class << self
    def tools
      TOOLS.map(&:new)
    end

    def prompt
      TOOLS.map do |tool_class|
        tool = tool_class.new
        "- #{tool.name}: #{tool.description}"
      end.join("\n")
    end
  end
end
