class Api::V1::Accounts::Synapseos::PipelineController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def show
    ensure_default_stages
    @stages = ::Synapseos::PipelineStage.where(account_id: Current.account.id).ordered
    @leads = enriched_leads
  end

  private

  # Tenta seedar. Se persistir vazio (coluna slug faltando, falha de save,
  # etc.), garante ao menos que a UI receba os 5 stages default em memória —
  # assim a experiência não depende de migration estar aplicada em prod.
  def ensure_default_stages
    ::Synapseos::EnsureDefaultStagesService.new(Current.account).call
    return if ::Synapseos::PipelineStage.where(account_id: Current.account.id).exists?

    # Último recurso: cria sem slug se a coluna não suporta.
    ::Synapseos::PipelineStage::DEFAULT_STAGES.each do |attrs|
      payload = attrs.merge(account_id: Current.account.id)
      payload = payload.except(:slug) unless ::Synapseos::PipelineStage.column_names.include?('slug')
      ::Synapseos::PipelineStage.create!(payload)
    rescue StandardError => e
      Rails.logger.warn("[Pipeline] fallback seed falhou: #{e.message}")
    end
  end

  def enriched_leads
    leads = ::Synapseos::Lead
            .where(account_id: Current.account.id)
            .includes(:conversation, :contact, :pipeline_stage)
    leads = leads.where(pipeline_stage_id: params[:stage_id]) if params[:stage_id].present?
    leads.order(updated_at: :desc).limit(500)
  end

  def check_authorization
    authorize(User, :index?)
  end
end
