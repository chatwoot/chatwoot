class Api::V1::Accounts::Autonomia::Agents::InstructionVersionsController < Api::V1::Accounts::Autonomia::BaseController
  before_action :fetch_agent

  # Cap defensivo: o histórico é um safety net, não uma auditoria infinita — as 50 versões mais
  # recentes bastam para a UI de rollback e mantêm o payload previsível.
  MAX_VERSIONS = 50

  def index
    @versions = @agent.instruction_versions
                      .includes(:created_by)
                      .order(created_at: :desc, id: :desc)
                      .limit(MAX_VERSIONS)
  end

  # Rollback atômico. A versão é buscada SEMPRE dentro de @agent.instruction_versions (agent já
  # escopado à conta pelo base controller) → ids cross-agent/cross-account dão 404.
  def restore
    version = @agent.instruction_versions.find(params[:version_id])
    @agent.restore_instruction!(version, created_by: Current.user)
    render 'api/v1/accounts/autonomia/agents/show'
  end

  private

  def fetch_agent
    @agent = agents_scope.find(params[:agent_id])
  end
end
