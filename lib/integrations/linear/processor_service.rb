class Integrations::Linear::ProcessorService
  pattr_initialize [:account!]

  def teams
    response = linear_client.teams
    return { error: response[:error] } if response[:error]

    { data: response['teams']['nodes'].map(&:as_json) }
  end

  def team_entities(team_id)
    response = linear_client.team_entities(team_id)
    return response if response[:error]

    {
      data: {
        users: response['users']['nodes'].map(&:as_json),
        projects: response['projects']['nodes'].map(&:as_json),
        states: response['workflowStates']['nodes'].map(&:as_json),
        labels: response['issueLabels']['nodes'].map(&:as_json)
      }
    }
  end

  def create_issue(params)
    response = linear_client.create_issue(params)
    return response if response[:error]

    {
      data: { id: response['issueCreate']['issue']['id'],
              title: response['issueCreate']['issue']['title'] }
    }
  end

  def link_issue(link, issue_id, title)
    response = linear_client.link_issue(link, issue_id, title)
    return response if response[:error]

    {
      data: {
        id: issue_id,
        link: link,
        link_id: response.with_indifferent_access[:attachmentLinkURL][:attachment][:id]
      }
    }
  end

  def unlink_issue(link_id)
    response = linear_client.unlink_issue(link_id)
    return response if response[:error]

    {
      data: { link_id: link_id }
    }
  end

  def search_issue(term)
    response = linear_client.search_issue(term)

    return response if response[:error]

    { data: response['searchIssues']['nodes'].map(&:as_json) }
  end

  def linked_issues(url)
    response = linear_client.linked_issues(url)
    return response if response[:error]

    { data: response['attachmentsForURL']['nodes'].map(&:as_json) }
  end

  private

  def linear_hook
    @linear_hook ||= account.hooks.find_by!(app_id: 'linear')
  end

  def linear_client
    @linear_client ||= Linear.new(linear_hook.access_token)
  end
end
