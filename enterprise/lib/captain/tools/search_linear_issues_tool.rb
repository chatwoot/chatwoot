class Captain::Tools::SearchLinearIssuesTool < BaseAgentTool
  description 'Search Linear issues and development context'
  param :query, type: 'string', desc: 'Search query for Linear issues'

  def perform(_tool_context, query:)
    log_tool_usage('search_linear_issues', { query: query })

    return 'Missing required parameters' if query.blank?

    # Call the existing search linear issues service
    Captain::Tools::Copilot::SearchLinearIssuesService.new(@assistant, user: @user).execute({
                                                                                              'query' => query
                                                                                            })
  end

  protected

  def required_permission
    'conversation_manage' # Basic permission check for technical context
  end
end
