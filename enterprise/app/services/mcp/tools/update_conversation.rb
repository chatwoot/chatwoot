class Mcp::Tools::UpdateConversation < Mcp::Tools::Base
  NO_PRIORITY = 'none'.freeze
  ASSIGN_TO_USER = 'me'.freeze
  UNASSIGN = 'none'.freeze

  tool_name 'update_conversation'
  description 'Change the status, priority, labels or assignee of a conversation. Only the fields you pass are changed. ' \
              'Returns the conversation after the change.'
  scope 'conversations:write'
  annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: true, open_world_hint: false)
  input_schema(
    properties: {
      conversation_id: { type: 'integer', description: 'The conversation id from list_conversations.' },
      status: { type: 'string', enum: Conversation.statuses.keys,
                description: 'snoozed lasts until the customer replies. An agent who sets open is also assigned the conversation.' },
      priority: { type: 'string', enum: Conversation.priorities.keys + [NO_PRIORITY], description: "#{NO_PRIORITY} clears the priority." },
      labels: { type: 'array', items: { type: 'string' },
                description: 'Replaces every label on the conversation, so include the ones to keep. Only labels of the account are accepted.' },
      assignee: { type: 'string', enum: [ASSIGN_TO_USER, UNASSIGN],
                  description: "#{ASSIGN_TO_USER} assigns the conversation to the user. #{UNASSIGN} removes the assignee." }
    },
    required: ['conversation_id']
  )

  def self.perform(conversation_id:, status: nil, priority: nil, labels: nil, assignee: nil)
    conversation = find_conversation(conversation_id)
    # A model may invent a label. Saving it would create a tag that no label in the account matches.
    account_labels = Current.account.labels.pluck(:title)
    unknown_labels = labels.to_a - account_labels
    return error_response("Unknown labels: #{unknown_labels.join(', ')}. Labels of the account: #{account_labels.join(', ')}") if unknown_labels.any?

    conversation.update_labels(labels) if labels
    conversation.update!(priority: priority == NO_PRIORITY ? nil : priority) if priority
    assign(conversation, assignee) if assignee
    change_status(conversation, status) if status

    respond(conversation_summary(conversation.reload))
  end

  def self.assign(conversation, assignee)
    assignee_id = Current.user.id if assignee == ASSIGN_TO_USER
    Conversations::AssignmentService.new(conversation: conversation, assignee_id: assignee_id).perform
  end
  private_class_method :assign

  def self.change_status(conversation, status)
    conversation.update!(status: status)
    return unless conversation.open?

    # Same as the dashboard: a person who opens a conversation takes it over from the AI assignee.
    conversation.with_lock do
      conversation.ai_assignee = nil
      conversation.assignee = Current.user if Current.user.agent?
      conversation.save!
    end
  end
  private_class_method :change_status
end
