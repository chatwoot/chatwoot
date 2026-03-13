class Captain::Tools::Copilot::SearchLinearIssuesService < Captain::Tools::BaseTool
  def self.name
    'search_linear_issues'
  end

  description 'Search Linear issues based on a search term'
  param :term, type: :string, desc: 'The search term to find Linear issues', required: true

  def execute(term:)
    return 'Linear integration is not enabled' unless active?

    linear_service = Integrations::Linear::ProcessorService.new(account: @assistant.account)
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

  def active?
    @user.present? && @assistant.account.hooks.exists?(app_id: 'linear')
  end

  private

  def format_issue(issue)
    <<~ISSUE
      Title: #{issue['title']}
      ID: #{issue['id']}
      State: #{issue['state']['name']}
      Priority: #{format_priority(issue['priority'])}
      #{issue['assignee'] ? "Assignee: #{issue['assignee']['name']}" : 'Assignee: Unassigned'}
      #{issue['description'].present? ? "\nDescription: #{issue['description']}" : ''}
    ISSUE
  end

  def format_priority(priority)
    return 'No priority' if priority.nil?

    case priority
    when 0 then 'No priority'
    when 1 then 'Urgent'
    when 2 then 'High'
    when 3 then 'Medium'
    when 4 then 'Low'
    else 'Unknown'
    end
  end
end
