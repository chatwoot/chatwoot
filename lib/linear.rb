require 'graphlient'

require_relative 'linear_queries'
require_relative 'linear_mutations'

class Linear
  BASE_URL = 'https://api.linear.app/graphql'.freeze
  PRIORITY_LEVELS = (0..4).to_a

  def initialize(api_key)
    raise ArgumentError, 'Missing Credentials' if api_key.blank?

    @client = Graphlient::Client.new(
      BASE_URL,
      headers: {
        'Authorization' => api_key,
        'Content-Type' => 'application/json'
      }
    )
  end

  def teams
    execute_query(LinearQueries::TEAMS_QUERY)
  end

  def team_entities(team_id)
    raise ArgumentError, 'Missing team id' if team_id.blank?

    execute_query(LinearQueries.team_entities_query(team_id))
  end

  def search_issue(term)
    raise ArgumentError, 'Missing search term' if term.blank?

    execute_query(LinearQueries.search_issue(term))
  end

  def linked_issue(url)
    raise ArgumentError, 'Missing link' if url.blank?

    execute_query(LinearQueries.linked_issue(url))
  end

  def create_issue(params)
    validate_team_and_title(params)
    validate_priority(params[:priority])
    validate_label_ids(params[:label_ids])

    variables = {
      title: params[:title],
      teamId: params[:team_id],
      description: params[:description],
      assigneeId: params[:assignee_id],
      priority: params[:priority],
      labelIds: params[:label_ids]
    }.compact

    execute_mutation(LinearMutations.issue_create(variables))
  end

  def link_issue(link, issue_id)
    raise ArgumentError, 'Missing link' if link.blank?
    raise ArgumentError, 'Missing issue id' if issue_id.blank?

    execute_mutation(LinearMutations.issue_link(issue_id, link))
  end

  def unlink_issue(link_id)
    raise ArgumentError, 'Missing  link id' if link_id.blank?

    execute_mutation(LinearMutations.unlink_issue(link_id))
  end

  private

  def validate_team_and_title(params)
    raise ArgumentError, 'Missing team id' if params[:team_id].blank?
    raise ArgumentError, 'Missing title' if params[:title].blank?
  end

  def validate_priority(priority)
    return if priority.nil? || PRIORITY_LEVELS.include?(priority)

    raise ArgumentError, 'Invalid priority value. Priority must be 0, 1, 2, 3, or 4.'
  end

  def validate_label_ids(label_ids)
    return if label_ids.nil?
    return if label_ids.is_a?(Array) && label_ids.all?(String)

    raise ArgumentError, 'label_ids must be an array of strings.'
  end

  def execute_query(query)
    response = @client.query(query)
    log_and_return_error("Error retrieving data: #{response.errors.messages}") if response.data.nil? && response.errors.any?
    response.data.to_h
  rescue StandardError => e
    log_and_return_error("Error: #{e.message}")
  end

  def execute_mutation(query)
    response = @client.query(query)
    log_and_return_error("Error creating issue: #{response.errors.messages}") if response.data.nil? && response.errors.any?
    response.data.to_h
  rescue StandardError => e
    log_and_return_error("Error: #{e.message}")
  end

  def log_and_return_error(message)
    Rails.logger.error message
    { error: message }
  end
end
