class Captain::Tools::Copilot::CreateLinearTicketsOnUiService < Captain::Tools::BaseService
  def name
    'create_linear_tickets_on_ui'
  end

  def description
    'Create linear tickets'
  end

  def parameters
    {
      type: 'object',
      properties: {
        account_id: {
          type: 'number',
          description: 'The ID of the account to create Linear tickets in'
        },
        title: {
          type: 'string',
          description: 'Title of the Linear ticket'
        },
        description: {
          type: 'string',
          description: 'Description of the Linear ticket'
        },
        priority: {
          type: 'number',
          description: 'Priority of the ticket (0-4)',
          enum: [0, 1, 2, 3, 4]
        }
      },
      required: %w[account_id title description]
    }
  end

  def execute(arguments)
    account_id = arguments['account_id']
    title = arguments['title']
    description = arguments['description']
    priority = arguments['priority']
    user_id = arguments['user_id']

    Rails.logger.info do
      "[CAPTAIN][CreateLinearTickets] account_id: #{account_id}, title: #{title}, description: #{description}, priority: #{priority}, user_id: #{user_id}"
    end

    return 'Missing required parameters' if account_id.blank? || title.blank? || description.blank?

    account = Account.find_by(id: account_id)
    return 'Account not found' unless account

    Rails.logger.info do
      "[CAPTAIN][CreateLinearTickets] Sent action cable message to copilot_#{account_id}_#{user_id}"
    end

    # Send ActionCable message
    ActionCable.server.broadcast(
      "copilot_#{account_id}_#{user_id}",
      {
        event: 'copilot.response',
        data: {
          response: {
            account_id: account_id,
            title: title,
            description: description,
            priority: priority
          },
          event: 'ui:linear_ticket_create',
          type: 'ui_event'
        }
      }
    )

    'The suggestion for the ticket is sent successfully to the agent. The agent can now create the ticket.'
  end

  private

  def format_issue(issue)
    {
      id: issue['id'],
      title: issue['title'],
      state: issue['state']['name'],
      priority: format_priority(issue['priority']),
      assignee: issue['assignee'] ? issue['assignee']['name'] : nil,
      description: issue['description'],
      url: issue['url']
    }
  end

  def format_priority(priority)
    return 'No priority' if priority.nil?

    case priority
    when 0 then 'No priority'
    when 1 then 'Low'
    when 2 then 'Medium'
    when 3 then 'High'
    when 4 then 'Urgent'
    else 'Unknown'
    end
  end
end
