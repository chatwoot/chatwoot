class Api::V1::Accounts::Integrations::LinearController < Api::V1::Accounts::BaseController
  before_action :fetch_conversation, only: [:link_issue, :linked_issue]

  def teams
    teams = linear_processor_service.teams
    if teams.is_a?(Hash) && teams[:error]
      render json: { error: teams[:error] }, status: :unprocessable_entity
    else
      render json: teams, status: :ok
    end
  end

  def team_entities
    team_id = params[:team_id]
    entites = linear_processor_service.team_entities(team_id)
    if entites.is_a?(Hash) && entites[:error]
      render json: { error: entites[:error] }, status: :unprocessable_entity
    else
      render json: entites, status: :ok
    end
  end

  def create_issue
    issue = linear_processor_service.create_issue(permitted_params)
    if issue.is_a?(Hash) && issue[:error]
      render json: { error: issue[:error] }, status: :unprocessable_entity
    else
      render json: issue, status: :ok
    end
  end

  def link_issue
    issue_id = params[:issue_id]
    issue = linear_processor_service.link_issue(conversation_link, issue_id)
    if issue.is_a?(Hash) && issue[:error]
      render json: { error: issue[:error] }, status: :unprocessable_entity
    else
      render json: issue, status: :ok
    end
  end

  def unlink_issue
    link_id = params[:link_id]
    issue = linear_processor_service.unlink_issue(link_id)

    if issue.is_a?(Hash) && issue[:error]
      render json: { error: issue[:error] }, status: :unprocessable_entity
    else
      render json: issue, status: :ok
    end
  end

  def linked_issue
    issues = linear_processor_service.linked_issue(conversation_link)

    if issues.is_a?(Hash) && issues[:error]
      render json: { error: issues[:error] }, status: :unprocessable_entity
    else
      render json: issues, status: :ok
    end
  end

  def search_issue
    render json: { error: 'Specify search string with parameter q' }, status: :unprocessable_entity if params[:q].blank? && return

    term = params[:q]
    issues = linear_processor_service.search_issue(term)
    if issues.is_a?(Hash) && issues[:error]
      render json: { error: issues[:error] }, status: :unprocessable_entity
    else
      render json: issues, status: :ok
    end
  end

  private

  def conversation_link
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{Current.account.id}/conversations/#{@conversation.display_id}"
  end

  def fetch_conversation
    @conversation = Current.account.conversations.find_by!(display_id: permitted_params[:conversation_id])
  end

  def linear_processor_service
    Integrations::Linear::ProcessorService.new(account: Current.account)
  end

  def permitted_params
    params.permit(:team_id, :conversation_id, :issue_id, :link_id, :title, :description, :assignee_id, :priority, label_ids: [])
  end
end
