class Captain::Apropos::Actions
  def initialize(account:, user:, data:, record:)
    @account = account
    @user = user
    @data = data
    @record = record
  end

  def call(name, reference, arguments)
    definition = Captain::Apropos::Catalog::ACTIONS.fetch(name.to_s)
    raise Captain::Apropos::Error, 'Wrong operation target' unless reference.fetch('type') == definition.fetch(:target)

    validate_arguments!(definition, arguments)

    conversation = @data.resolve(reference)
    result = if Captain::Apropos::ResourceActions::OPERATIONS.include?(name.to_s)
               Captain::Apropos::ResourceActions.new(account: @account, user: @user).perform(name.to_s, conversation, arguments)
             else
               perform(name.to_s, conversation, arguments)
             end
    receipt = { 'operation' => name.to_s, 'target' => reference, 'status' => 'completed', 'result' => result,
                'effect' => definition.fetch(:effect), 'at' => Time.current.iso8601 }
    @record.call('action', receipt)
    receipt
  rescue StandardError => e
    @record.call('action', { 'operation' => name.to_s, 'target' => reference, 'status' => 'failed', 'error' => e.message })
    raise
  end

  private

  def validate_arguments!(definition, arguments)
    expected = definition.fetch(:arguments).keys.map(&:to_s)
    raise Captain::Apropos::Error, "Expected arguments: #{expected.join(', ')}" unless arguments.keys.sort == expected.sort
  end

  def perform(name, conversation, arguments)
    case name
    when 'add-private-note', 'send-reply'
      send_message(name, conversation, arguments)
    when 'set-status'
      set_status(conversation, arguments.fetch('status'))
    when 'set-priority'
      conversation.update!(priority: arguments.fetch('priority'))
      { 'priority' => conversation.priority }
    when 'assign-team'
      team = @account.teams.find(arguments.fetch('team_id'))
      conversation.update!(team: team)
      { 'team_id' => team.id }
    when 'assign-agent'
      assign_agent(conversation, arguments.fetch('agent_id'))
    when 'add-label'
      label = @account.labels.find_by!(title: arguments.fetch('label'))
      conversation.add_labels([label.title])
      { 'labels' => conversation.reload.label_list }
    end
  end

  def send_message(name, conversation, arguments)
    message = Messages::MessageBuilder.new(@user, conversation, content: arguments.fetch('content'),
                                                                private: name == 'add-private-note', message_type: 'outgoing').perform
    { 'message_id' => message.id, 'private' => message.private?, 'conversation_id' => conversation.id }
  end

  def set_status(conversation, status)
    raise Captain::Apropos::Error, 'Status must be open, resolved, or pending' unless %w[open resolved pending].include?(status)

    conversation.update!(status: status)
    { 'status' => conversation.status }
  end

  def assign_agent(conversation, id)
    agent = @account.users.find(id)
    raise Captain::Apropos::Error, 'Agent is not assignable to this inbox' unless conversation.inbox.assignable_agents.include?(agent)

    conversation.update!(assignee: agent)
    { 'agent_id' => conversation.assignee_id }
  end
end
