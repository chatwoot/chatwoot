class Github::GithubService
  attr_reader :hook

  def initialize(hook:)
    @hook = hook
  end

  def repositories
    client.repositories(nil, type: 'all')
  rescue Octokit::Error => e
    Rails.logger.error("GitHub API error fetching repositories: #{e.message}")
    raise_api_error(e)
  end

  def assignees(repo_full_name)
    client.repository_assignees(repo_full_name)
  rescue Octokit::Error => e
    Rails.logger.error("GitHub API error fetching assignees for #{repo_full_name}: #{e.message}")
    raise_api_error(e)
  end

  def search_repositories(query)
    return repositories if query.blank?

    # Get all user's repositories first
    user_repos = repositories

    # Filter repositories by query string (case-insensitive)
    user_repos.select do |repo|
      repo.full_name.downcase.include?(query.downcase) ||
        (repo.description&.downcase&.include?(query.downcase))
    end
  rescue Octokit::Error => e
    Rails.logger.error("GitHub API error searching repositories with query '#{query}': #{e.message}")
    raise_api_error(e)
  end

  private

  def client
    @client ||= Octokit::Client.new(
      access_token: hook.access_token,
      auto_paginate: true,
      per_page: 100
    )
  end

  def raise_api_error(error)
    case error.response_status
    when 401
      raise CustomExceptions::Base.new('GitHub authentication failed', 401)
    when 403
      raise CustomExceptions::Base.new('GitHub API rate limit exceeded or insufficient permissions', 403)
    when 404
      raise CustomExceptions::Base.new('GitHub resource not found', 404)
    else
      raise CustomExceptions::Base.new("GitHub API error: #{error.message}", error.response_status || 500)
    end
  end
end