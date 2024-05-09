module LinearMutations
  def self.issue_create(input)
    graphql_input = input.map { |key, value| "#{key}: \"#{value}\"" }.join(', ')
    <<~GRAPHQL
      mutation {
        issueCreate(input: { #{graphql_input} }) {
          success
          issue {
            id
            title
          }
        }
      }
    GRAPHQL
  end
end
