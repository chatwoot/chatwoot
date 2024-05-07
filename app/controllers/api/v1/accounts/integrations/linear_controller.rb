class Api::V1::Accounts::Integrations::LinearController < Api::V1::Accounts::BaseController
  def teams
    teams = linear_processor_service.teams
    if teams.is_a?(Hash) && teams[:error]
      render json: { error: teams[:error] }, status: :unprocessable_entity
    else
      render json: teams, status: :ok
    end
  end

  def team_entites
    team_id = params[:team_id]
    entites = linear_processor_service.team_entites(team_id)
    if entites.is_a?(Hash) && entites[:error]
      render json: { error: entites[:error] }, status: :unprocessable_entity
    else
      render json: entites, status: :ok
    end
  end

  private

  def linear_processor_service
    Integrations::Linear::ProcessorService.new(account: Current.account)
  end
end
