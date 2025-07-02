class Captain::Tools::SearchDocumentationTool < BaseAgentTool
  description 'Search documentation and help docs'
  param :query, type: 'string', desc: 'Search query for documentation'

  def perform(_tool_context, query:)
    log_tool_usage('search_documentation', { query: query })

    return 'Missing required parameters' if query.blank?

    # Call the existing search documentation service
    Captain::Tools::SearchDocumentationService.new(@assistant, user: @user).execute({
                                                                                      'query' => query
                                                                                    })
  end

  def active?
    true # Documentation search is available to all users
  end
end