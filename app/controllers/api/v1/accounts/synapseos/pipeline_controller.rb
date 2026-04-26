class Api::V1::Accounts::Synapseos::PipelineController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def show
    ensure_default_stages
    @stages = ::Synapseos::PipelineStage.where(account_id: Current.account.id).ordered
    @leads = enriched_leads
  end

  private

  # Tenta seedar. Se persistir vazio depois do seeder, tenta um fallback que
  # cria stages mínimos sem slug/description. Falhas são logadas em ERROR
  # (não warn) pra ficarem visíveis em prod.
  def ensure_default_stages
    ::Synapseos::EnsureDefaultStagesService.new(Current.account).call

    existing_count = ::Synapseos::PipelineStage.where(account_id: Current.account.id).count
    return if existing_count >= ::Synapseos::PipelineStage::DEFAULT_STAGES.size

    Rails.logger.error(
      "[Pipeline] account=#{Current.account.id} ainda tem #{existing_count}/#{::Synapseos::PipelineStage::DEFAULT_STAGES.size} stages após seeder; tentando fallback"
    )

    ::Synapseos::PipelineStage::DEFAULT_STAGES.each do |attrs|
      next if ::Synapseos::PipelineStage.where(account_id: Current.account.id, name: attrs[:name]).exists?

      payload = attrs.merge(account_id: Current.account.id)
      payload = payload.except(:slug) unless ::Synapseos::PipelineStage.column_names.include?('slug')
      payload = payload.except(:description) unless ::Synapseos::PipelineStage.column_names.include?('description')
      ::Synapseos::PipelineStage.create!(payload)
    rescue StandardError => e
      Rails.logger.error("[Pipeline] fallback seed account=#{Current.account.id} stage=#{attrs[:name]} falhou: #{e.class} #{e.message}")
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
