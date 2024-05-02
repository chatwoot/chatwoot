class Integrations::Linear::ProcessorService
  pattr_initialize [:account!, :conversation!]

  def teams
    response = linear_client.teams
    return response if response[:error]

    response['teams']['nodes'].map(&:as_json)
  end

  # get labels for a team
  def labels(team_id)
    response = linear_client.labels(team_id)
    return response if response[:error]

    response['team']['labels']['nodes'].map(&:as_json)
  end

  private

  def conversation_link
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/conversations/#{conversation.display_id}"
  end

  def linear_hook
    @linear_hook ||= account.hooks.find_by!(app_id: 'linear')
  end

  def linear_client
    credentials = linear_hook.settings
    @linear_client ||= Linear.new(credentials['api_key'])
  end
end
