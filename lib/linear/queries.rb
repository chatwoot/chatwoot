module Linear::Queries
  TEAMS_QUERY = <<~GRAPHQL.freeze
    query {
      teams {
        nodes {
          id
          name
        }
      }
    }
  GRAPHQL

  def self.team_entities_query(team_id)
    <<~GRAPHQL
      query {
        users {
          nodes {
            id
            name
          }
        }
        projects {
          nodes {
            id
            name
          }
        }
        workflowStates(
          filter: { team: { id: { eq: "#{team_id}" } } }
        ) {
          nodes {
            id
            name
          }
        }
        issueLabels(
          filter: { team: { id: { eq: "#{team_id}" } } }
        ) {
          nodes {
            id
            name
          }
        }
      }
    GRAPHQL
  end

  def self.search_issue(term)
    <<~GRAPHQL
      query {
        searchIssues(term: "#{term}") {
          nodes {
            id
            title
            description
            identifier
            state {
              name
              color
            }
          }
        }
      }
    GRAPHQL
  end

  def self.linked_issues(url)
    <<~GRAPHQL
      query {
        attachmentsForURL(url: "#{url}") {
          nodes {
            id
            title
            issue {
              id
              identifier
              title
              description
              priority
              createdAt
              url
              assignee {
                name
                avatarUrl
              }
              state {
                name
                color
              }
              labels {
                nodes{
                  id
                  name
                  color
                  description
                }
              }
            }
          }
        }
      }
    GRAPHQL
  end
end
