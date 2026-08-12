class Captain::Routines::ToolCatalog
  TOOLS = {
    'conversations.search' => {
      kind: 'source',
      description: 'Find conversations using deterministic filters.',
      arguments: {
        status: 'open, resolved, pending, or snoozed',
        waiting_for: 'agent_reply or customer_reply',
        waiting_longer_than: 'duration such as 12h',
        priority: 'low, medium, high, or urgent',
        labels: 'array of label names'
      },
      required: []
    },
    'conversations.set_priority' => {
      kind: 'action',
      description: 'Set the priority of one conversation.',
      arguments: {
        conversation_id: 'conversation ID or reference',
        priority: 'low, medium, high, or urgent'
      },
      required: %w[conversation_id priority]
    },
    'conversations.add_label' => {
      kind: 'action',
      description: 'Add an existing account label to one conversation.',
      arguments: {
        conversation_id: 'conversation ID or reference',
        label: 'label name'
      },
      required: %w[conversation_id label]
    },
    'conversations.assign_agent' => {
      kind: 'action',
      description: 'Assign one conversation to an account agent.',
      arguments: {
        conversation_id: 'conversation ID or reference',
        agent: 'agent name, email, or ID'
      },
      required: %w[conversation_id agent]
    }
  }.freeze

  class << self
    def prompt
      JSON.pretty_generate(TOOLS)
    end

    def include?(name, kind: nil)
      tool = TOOLS[name]
      tool.present? && (kind.nil? || tool[:kind] == kind)
    end

    def fetch(name)
      TOOLS[name]
    end
  end
end
