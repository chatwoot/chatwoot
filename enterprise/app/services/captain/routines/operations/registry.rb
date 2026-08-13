class Captain::Routines::Operations::Registry
  OPERATIONS = [
    Captain::Routines::Operations::Queries::ConversationSearch,
    Captain::Routines::Operations::Queries::ConversationFind,
    Captain::Routines::Operations::Queries::ConversationGetMessages,
    Captain::Routines::Operations::Actions::ConversationSetPriority,
    Captain::Routines::Operations::Actions::ConversationAddLabel,
    Captain::Routines::Operations::Actions::ConversationRemoveLabel,
    Captain::Routines::Operations::Actions::ConversationAssignAgent,
    Captain::Routines::Operations::Actions::ConversationAssignTeam,
    Captain::Routines::Operations::Actions::ConversationSetStatus,
    Captain::Routines::Operations::Actions::ConversationSnooze,
    Captain::Routines::Operations::Actions::ConversationAddPrivateNote,
    Captain::Routines::Operations::Actions::ConversationUpdateCustomAttributes,
    Captain::Routines::Operations::Actions::ConversationSendReply,
    Captain::Routines::Operations::Queries::ContactSearch,
    Captain::Routines::Operations::Queries::ContactFind,
    Captain::Routines::Operations::Queries::AgentSearch,
    Captain::Routines::Operations::Queries::AgentListAvailable,
    Captain::Routines::Operations::Queries::AgentGetWorkload,
    Captain::Routines::Operations::Queries::TeamSearch,
    Captain::Routines::Operations::Queries::LabelSearch,
    Captain::Routines::Operations::Queries::InboxSearch,
    Captain::Routines::Operations::Queries::InboxGetAvailability,
    Captain::Routines::Operations::Queries::KnowledgeSearch
  ].index_by(&:operation_name).freeze

  class << self
    def prompt
      JSON.pretty_generate(OPERATIONS.transform_values(&:definition))
    end

    def capabilities_prompt
      capabilities = OPERATIONS.values.map do |operation|
        operation.definition.slice(:kind, :effect, :description, :arguments, :returns).compact
      end
      JSON.pretty_generate(capabilities)
    end

    def include?(name, kind: nil)
      operation = fetch(name)
      operation.present? && (kind.nil? || operation.kind == kind)
    end

    def fetch(name)
      OPERATIONS[name]
    end
  end
end
