class Api::V1::Accounts::Integrations::GithubController < Api::V1::Accounts::BaseController
  before_action :fetch_hook
  before_action :ensure_hook_exists, except: [:destroy]

  def destroy
    @hook.destroy!
    head :ok
  end

  def repositories
    repositories = github_service.repositories
    filtered_repos = repositories.map do |repo|
      {
        full_name: repo[:full_name] || repo.full_name,
        private: repo[:private] || repo.private
      }
    end
    render json: filtered_repos
  end

  def search_repositories
    repositories = github_service.search_repositories(params[:q])
    filtered_repos = repositories.map do |repo|
      {
        full_name: repo[:full_name] || repo.full_name,
        private: repo[:private] || repo.private
      }
    end
    render json: filtered_repos
  end

  def assignees
    assignees = github_service.assignees(repo_full_name)
    filtered_assignees = assignees.map do |assignee|
      {
        login: assignee.login,
        avatar_url: assignee.avatar_url
      }
    end
    render json: filtered_assignees
  end

  def labels
    labels = github_service.labels(repo_full_name)
    filtered_labels = labels.map do |label|
      {
        name: label.name,
        color: label.color
      }
    end
    render json: filtered_labels
  end

  def search_issues
    issues = github_service.search_issues(repo_full_name, params[:q])
    filtered_issues = issues.map do |issue|
      {
        number: issue.number,
        title: issue.title,
        html_url: issue.html_url
      }
    end
    render json: filtered_issues
  end

  def create_issue
    issue_data = github_service.create_issue(
      repo_full_name,
      params[:title],
      params[:body],
      issue_options
    )

    github_issue = create_linked_issue(issue_data)
    render json: issue_response(github_issue), status: :created
  end

  def link_issue
    issue_data = github_service.issue(repo_full_name, params[:issue_number])
    github_issue = create_linked_issue(issue_data)
    render json: issue_response(github_issue), status: :created
  end

  def linked_issues
    issues = GithubIssue.where(conversation_id: params[:conversation_id])

    render json: issues.map do |issue|
      {
        id: issue.id,
        issue_number: issue.issue_number,
        title: issue.issue_title,
        html_url: issue.html_url,
        repo_full_name: issue.repo_full_name,
        linked_by: {
          id: issue.linked_by.id,
          name: issue.linked_by.name
        },
        created_at: issue.created_at
      }
    end
  end

  def unlink_issue
    github_issue = GithubIssue.find(params[:id])
    github_issue.destroy!
    head :ok
  end

  private

  def fetch_hook
    @hook = Integrations::Hook.where(account: Current.account).find_by(app_id: 'github')
  end

  def ensure_hook_exists
    render json: { error: 'GitHub integration not configured' }, status: :unauthorized unless @hook
  end

  def github_service
    @github_service ||= Github::GithubService.new(hook: @hook)
  end

  def repo_full_name
    params[:repo_full_name] || "#{params[:owner]}/#{params[:repo]}"
  end

  def issue_options
    options = {}
    options[:assignees] = params[:assignees] if params[:assignees].present?
    options[:labels] = params[:labels] if params[:labels].present?
    options
  end

  def create_linked_issue(issue_data)
    GithubIssue.create!(
      conversation_id: params[:conversation_id],
      account: Current.account,
      repo_full_name: repo_full_name,
      issue_number: issue_data.number,
      issue_title: issue_data.title,
      html_url: issue_data.html_url,
      linked_by: Current.user
    )
  end

  def issue_response(github_issue)
    {
      id: github_issue.id,
      issue_number: github_issue.issue_number,
      title: github_issue.issue_title,
      html_url: github_issue.html_url,
      repo_full_name: github_issue.repo_full_name
    }
  end
end
