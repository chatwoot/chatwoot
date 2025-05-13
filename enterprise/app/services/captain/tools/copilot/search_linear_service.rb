class Captain::Tools::Copilot::SearchLinearService < Captain::Tools::BaseService
  def name
    'search_linear'
  end

  def description
    'Search for Linear issues based on a search term'
  end

  def parameters
    {
      type: 'object',
      properties: {
        account_id: {
          type: 'number',
          description: 'The ID of the account to search Linear issues in'
        },
        term: {
          type: 'string',
          description: 'The search term to find Linear issues'
        }
      },
      required: %w[account_id term]
    }
  end

  def execute(arguments)
    account_id = arguments['account_id']
    term = arguments['term']

    Rails.logger.info do
      "[CAPTAIN][SearchLinear] account_id: #{account_id}, term: #{term}"
    end

    return 'Missing required parameters' if account_id.blank? || term.blank?

    account = Account.find_by(id: account_id)
    return 'Account not found' unless account

    linear_service = Integrations::Linear::ProcessorService.new(account: account)
    result = linear_service.search_issue(term)

    return result[:error] if result[:error]

    issues = result[:data]
    return 'No issues found, I should try another similar search term' if issues.blank?

    total_count = issues.length

    <<~RESPONSE
      Total number of issues: #{total_count}
      #{issues.map { |issue| format_issue(issue) }.join("\n---\n")}
    RESPONSE
  end

  private

  def format_issue(issue)
    <<~ISSUE
      Title: #{issue['title']}
      ID: #{issue['id']}
      State: #{issue['state']['name']}
      Priority: #{format_priority(issue['priority'])}
      #{issue['assignee'] ? "Assignee: #{issue['assignee']['name']}" : 'Assignee: Unassigned'}
      #{issue['description'].present? ? "\nDescription:\n#{issue['description']}" : ''}
    ISSUE
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
