class Api::V1::Accounts::Synapseos::LeadsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_lead, only: [:show, :update]

  def index
    @leads = scope.order(created_at: :desc).limit(params[:limit].to_i.positive? ? params[:limit].to_i : 100)
  end

  def show; end

  def create
    @lead = scope.new(lead_params)
    @lead.save!
  end

  def update
    @lead.update!(lead_params)
  end

  # GET /synapseos/leads/by_conversation/:conversation_id
  # Atalho pra N8N: dado o conversation_id que vem no webhook do Chatwoot,
  # retorna o lead com o pipeline_stage atual. Evita uma chamada extra na
  # listagem + filtro client-side.
  def by_conversation
    @lead = scope.find_by(conversation_id: params[:conversation_id])
    return render(json: { error: 'lead not found for conversation' }, status: :not_found) unless @lead

    render :show
  end

  # POST /synapseos/leads/upsert_by_conversation
  # Atalho pra N8N mover leads entre stages sem resolver stage_id manualmente.
  #   conversation_id: integer (required)
  #   stage_slug:      string opcional — ex 'aguardando_atendimento', 'encerrado'
  #   metadata:        hash opcional (loss_reason, modelo, etc.)
  #   source:          string opcional pra novos leads (default 'n8n')
  # Find-or-create lead por conv_id; resolve stage por slug; deep-merge metadata.
  def upsert_by_conversation
    conv_id = params[:conversation_id]
    return render(json: { error: 'conversation_id is required' }, status: :unprocessable_entity) if conv_id.blank?

    conv = ::Conversation.find_by(account_id: Current.account.id, id: conv_id) ||
           ::Conversation.find_by(account_id: Current.account.id, display_id: conv_id)
    return render(json: { error: 'conversation not found' }, status: :not_found) if conv.nil?

    stage = nil
    if params[:stage_slug].present?
      unless ::Synapseos::PipelineStage.column_names.include?('slug')
        return render(json: { error: 'pipeline_stage has no slug column on this deployment' }, status: :unprocessable_entity)
      end
      stage = ::Synapseos::PipelineStage.find_by(account_id: Current.account.id, slug: params[:stage_slug])
      return render(json: { error: "stage '#{params[:stage_slug]}' not found" }, status: :not_found) if stage.nil?
    end

    @lead = scope.find_or_initialize_by(conversation_id: conv.id) do |l|
      l.contact_id = conv.contact_id
      l.status = :open
      l.source = params[:source].presence || 'n8n'
    end
    @lead.pipeline_stage_id = stage.id if stage
    if params[:metadata].respond_to?(:to_unsafe_h)
      @lead.metadata = (@lead.metadata || {}).deep_merge(params[:metadata].to_unsafe_h)
    end
    @lead.save!
    render :show
  end

  private

  def scope
    ::Synapseos::Lead.where(account_id: Current.account.id)
  end

  def fetch_lead
    @lead = scope.find(params[:id])
  end

  def lead_params
    params.require(:lead).permit(:conversation_id, :contact_id, :assignee_id, :status, :source, :pipeline_stage_id, metadata: {})
  end

  def check_authorization
    authorize(User, :index?)
  end
end
