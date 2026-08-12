class Captain::Routines::ToolCatalog
  TOOLS = {
    'conversations.search' => {
      kind: 'source',
      effect: 'read',
      approval: 'never',
      description: 'Find conversations using deterministic filters.',
      arguments: {
        status: 'open, resolved, pending, or snoozed',
        inbox: 'inbox name or ID',
        assignee: 'agent name, email, ID, or unassigned',
        team: 'team name, ID, or unassigned',
        waiting_for: 'agent_reply or customer_reply',
        waiting_longer_than: 'duration such as 12h',
        snooze_due: 'relative date such as today; evaluated in the account timezone against the conversation snoozed_until value',
        priority: 'low, medium, high, or urgent',
        labels: 'array of label names',
        created: 'relative date or range',
        last_activity: 'relative date or range'
      },
      required: []
    },
    'conversations.set_priority' => {
      kind: 'action',
      effect: 'internal_write',
      approval: 'workspace_policy',
      description: 'Set the priority of one conversation.',
      arguments: {
        conversation_id: 'conversation ID or reference',
        priority: 'low, medium, high, or urgent'
      },
      required: %w[conversation_id priority]
    },
    'conversations.add_label' => {
      kind: 'action',
      effect: 'internal_write',
      approval: 'workspace_policy',
      description: 'Add an existing account label to one conversation.',
      arguments: {
        conversation_id: 'conversation ID or reference',
        label: 'label name'
      },
      required: %w[conversation_id label]
    },
    'conversations.remove_label' => {
      kind: 'action',
      effect: 'internal_write',
      approval: 'workspace_policy',
      description: 'Remove a label from one conversation.',
      arguments: {
        conversation_id: 'conversation ID or reference',
        label: 'label name'
      },
      required: %w[conversation_id label]
    },
    'conversations.assign_agent' => {
      kind: 'action',
      effect: 'internal_write',
      approval: 'workspace_policy',
      description: 'Assign one conversation to an account agent.',
      arguments: {
        conversation_id: 'conversation ID or reference',
        agent: 'agent name, email, or ID'
      },
      required: %w[conversation_id agent]
    },
    'conversations.assign_team' => {
      kind: 'action',
      effect: 'internal_write',
      approval: 'workspace_policy',
      description: 'Assign one conversation to an account team.',
      arguments: {
        conversation_id: 'conversation ID or reference',
        team: 'team name or ID'
      },
      required: %w[conversation_id team]
    },
    'conversations.set_status' => {
      kind: 'action',
      effect: 'internal_write',
      approval: 'workspace_policy',
      description: 'Change one conversation to open, pending, or resolved.',
      arguments: {
        conversation_id: 'conversation ID or reference',
        status: 'open, pending, or resolved'
      },
      required: %w[conversation_id status]
    },
    'conversations.snooze' => {
      kind: 'action',
      effect: 'internal_write',
      approval: 'workspace_policy',
      description: 'Snooze one conversation until a specified time.',
      arguments: {
        conversation_id: 'conversation ID or reference',
        until: 'absolute or relative date and time'
      },
      required: %w[conversation_id until]
    },
    'conversations.add_private_note' => {
      kind: 'action',
      effect: 'internal_write',
      approval: 'workspace_policy',
      description: 'Add an internal note to one conversation.',
      arguments: {
        conversation_id: 'conversation ID or reference',
        content: 'note content'
      },
      required: %w[conversation_id content]
    },
    'conversations.send_reply' => {
      kind: 'action',
      effect: 'customer_visible_write',
      approval: 'required',
      description: 'Send a customer-visible reply in one conversation.',
      arguments: {
        conversation_id: 'conversation ID or reference',
        content: 'reply content'
      },
      required: %w[conversation_id content]
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
