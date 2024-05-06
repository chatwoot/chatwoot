require 'graphlient'

require_relative 'linear_queries'
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

  def teams
    execute_query(LinearQueries::TEAMS_QUERY)
  end

  def team_entites(team_id)
    raise ArgumentError, 'Missing team id' if team_id.blank?

    execute_query(LinearQueries.team_entites_query(team_id))
  end

  private

  def execute_query(query)
    response = @client.query(query)
    unless response.data
      raise StandardError, "Error retrieving data: #{response.errors.messages}" if response.errors.any?

      return { error: 'No data returned' }
    end
    response.data.to_h
  rescue Graphlient::Errors::GraphQLError => e
    { error: "GraphQL Error: #{e.message}" }
  rescue Graphlient::Errors::ServerError => e
    { error: "Server Error: #{e.message}" }
  rescue StandardError => e
    { error: "Unexpected Error: #{e.message}" }
  end
end
