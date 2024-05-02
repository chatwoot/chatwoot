require 'graphlient'

class Linear
  BASE_URL = 'https://api.linear.app/graphql'.freeze

  def initialize(api_key)
    @api_key = api_key
    raise ArgumentError, 'Missing Credentials' if @api_key.blank?

    @client = Graphlient::Client.new(
      BASE_URL,
      headers: {
        'Authorization' => @api_key,
        'Content-Type' => 'application/json'
      }
    )
  end

  def list_issues
    query = <<~GRAPHQL
      query {
        issues(first: 5) {
          nodes {
            id
            title
          }
        }
      }
    GRAPHQL

    begin
      response = @client.query(query)
      response.data.issues.nodes
    rescue StandardError => e
      # return error message
      e.message
    end
  end
end
