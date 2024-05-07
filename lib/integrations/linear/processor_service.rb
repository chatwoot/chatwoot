class Integrations::Linear::ProcessorService
  pattr_initialize [:account!]

  def teams
    response = linear_client.teams
    return response if response[:error]

    response['teams']['nodes'].map(&:as_json)
  end

  def team_entites(team_id)
    response = linear_client.team_entites(team_id)
    return response if response[:error]

    {
      users: response['users']['nodes'].map(&:as_json),
      projects: response['projects']['nodes'].map(&:as_json),
      workflowStates: response['workflowStates']['nodes'].map(&:as_json),
      issueLabels: response['issueLabels']['nodes'].map(&:as_json)
    }
  end

  private

  def linear_hook
    @linear_hook ||= account.hooks.find_by!(app_id: 'linear')
  end

  def linear_client
    credentials = linear_hook.settings
    @linear_client ||= Linear.new(credentials['api_key'])
  end
end
