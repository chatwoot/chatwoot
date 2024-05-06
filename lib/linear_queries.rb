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

  def self.team_entites_query(team_id)
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
end
