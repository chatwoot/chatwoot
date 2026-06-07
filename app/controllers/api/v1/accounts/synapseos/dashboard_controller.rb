class Api::V1::Accounts::Synapseos::DashboardController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def summary
    @summary = ::Synapseos::DashboardSummaryService.new(Current.account, period_days: period_days).call
  end

  # Forecast estratégico: leads de compra futura (coluna 'futuro' OU com
  # horizonte_compra capturado no metadata) com modelo + horizonte. O painel
  # agentic faz o join de preço (audi_modelos) e agrega receita futura/estoque.
  def forecast
    acc = Current.account.id
    futuro_stage = ::Synapseos::PipelineStage.find_by(account_id: acc, slug: 'futuro')
    leads = ::Synapseos::Lead
            .where(account_id: acc)
            .where("metadata->>'horizonte_compra' IS NOT NULL OR pipeline_stage_id = ?", futuro_stage&.id)
    futuro_leads = leads.map do |l|
      md = l.metadata || {}
      { modelo_interesse: md['modelo_interesse'], horizonte_compra: md['horizonte_compra'] }
    end
    render json: { count: futuro_leads.size, futuro_leads: futuro_leads }
  end

  private

  def period_days
    days = params[:days].to_i
    days.positive? ? days : 30
  end

  def check_authorization
    authorize(User, :index?)
  end
end
