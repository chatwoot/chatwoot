module LinearQueries
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
          }
        }
      }
    GRAPHQL
  end

  def self.linked_issue(url)
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
              state {
                name
              }
              state {
                name
              }
              assignee {
                name
              }
              labels {
                nodes{
                  id
                  name
                }
              }
            }
          }
        }
      }
    GRAPHQL
  end
end
