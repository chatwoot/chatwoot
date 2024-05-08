module LinearMutations
  ISSUE_CREATE = <<~GRAPHQL.freeze
    mutation IssueCreate($input: IssueCreateInput!) {
      issueCreate(
        input: $input
      ) {
        success
        issue {
          id
          title
        }
      }
    }
  GRAPHQL
end
