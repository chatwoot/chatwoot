# CUSTOMIZAÇÃO_SYNAPSEOS
# Relatório mensal da Elisa (admin-only).
#   GET    .../synapseos/monthly_reports            -> lista (metadados)
#   POST   .../synapseos/monthly_reports            -> upsert do mês (chamado pelo n8n)
#   GET    .../synapseos/monthly_reports/:id/download -> baixa o HTML renderizado
#
# Contrato do POST (body): { period: "YYYY-MM", title?, data: { ...seções... } }.
# `data` é o payload consumido pelo template ERB (overview, funnel, origens,
# pipeline_potencial, horizonte, demanda_modelo, pipeline_status, voz, etc.).
class Api::V1::Accounts::Synapseos::MonthlyReportsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization

  def index
    reports = ::Synapseos::MonthlyReport.where(account_id: Current.account.id).recent_first
    render json: { data: reports.map { |r| serialize(r) } }
  end

  def create
    period = params[:period].to_s
    return render_could_not_create_error('period obrigatório (YYYY-MM)') if period.blank?

    data = params.require(:data).permit!.to_h
    data = enrich(data, period)

    report = ::Synapseos::MonthlyReport.find_or_initialize_by(account_id: Current.account.id, period: period)
    report.title = params[:title].presence || "Relatório Elisa — #{period}"
    report.data = data
    report.generated_at = Time.current
    report.save!

    render json: { data: serialize(report) }, status: :created
  end

  def download
    report = ::Synapseos::MonthlyReport.find_by!(account_id: Current.account.id, id: params[:id])
    html = ::Synapseos::MonthlyReportRenderer.render(report)
    send_data html, type: 'text/html; charset=utf-8',
                    filename: "relatorio-elisa-#{report.period}.html",
                    disposition: 'attachment'
  end

  private

  # Completa o payload (vindo do painel via n8n) com as 2 seções que só o Chatwoot
  # tem: 1ª-msg-vs-follow-up (efetividade) e leads por estágio (pipeline_status).
  def enrich(data, period)
    extra = ::Synapseos::MonthlyReportEnricher.new(Current.account, period).call
    eff = extra[:efetividade]
    data['efetividade'] = (data['efetividade'] || {}).merge(
      'resp_primeira' => eff[:resp_primeira], 'resp_apos' => eff[:resp_apos]
    )
    data['pipeline_status'] = extra[:pipeline_status].map { |s| { 'estagio' => s[:estagio], 'n' => s[:n] } }
    data
  rescue StandardError => e
    Rails.logger.error("[MonthlyReport] enrich falhou p/ #{period}: #{e.message}")
    data
  end

  def check_admin_authorization
    render_unauthorized('Acesso restrito a administradores') unless Current.account_user&.administrator?
  end

  def serialize(report)
    {
      id: report.id,
      period: report.period,
      title: report.title,
      generated_at: report.generated_at&.iso8601
    }
  end
end
