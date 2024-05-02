class Api::V1::Accounts::Integrations::LinearController < Api::V1::Accounts::BaseController
  # before_action :fetch_conversation, only: [:list]

  def teams
    teams = linear_processor_service.teams
    if teams.is_a?(Hash) && teams[:error]
      render json: { error: teams[:error] }, status: :unprocessable_entity
    else
      render json: teams, status: :ok
    end
  end

  def labels
    team_id = params[:team_id]
    labels = linear_processor_service.labels(team_id)
    if labels.is_a?(Hash) && labels[:error]
      render json: { error: labels[:error] }, status: :unprocessable_entity
    else
      render json: labels, status: :ok
    end
  end

  private

  def linear_processor_service
    Integrations::Linear::ProcessorService.new(account: Current.account, conversation: @conversation)
  end

  def permitted_params
    params.permit(:conversation_id)
  end

  def fetch_conversation
    @conversation = Current.account.conversations.find_by!(display_id: permitted_params[:conversation_id])
  end
end
