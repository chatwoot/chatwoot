class Api::V1::Accounts::Synapseos::LeadsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_lead, only: [:show, :update]

  def index
    @leads = scope.includes(:conversation).order(created_at: :desc).limit(params[:limit].to_i.positive? ? params[:limit].to_i : 100)
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
    conv = resolve_conversation(params[:conversation_id])
    @lead = conv && scope.find_by(conversation_id: conv.id)
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

    conv = resolve_conversation(conv_id)
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

  # POST /synapseos/leads/transition
  # ADR-003: único ponto de entrada pra mudar estado de lead. Recebe um sinal e
  # delega pra Synapseos::LeadLifecycle.transition (função total + idempotente).
  # Resolve conversation_id por display_id OU id interno (igual upsert_by_conversation).
  #
  #   conversation_id: integer (required)
  #   signal:          string (required) — quer|quer_depois|nao_quer|
  #                                        sem_resposta_toque|sem_resposta_esgotou
  #   motivo:          string (obrigatório p/ nao_quer)
  #   horizonte_compra:string opcional (balde de retomada p/ quer_depois)
  #   cadence_touch:   integer opcional (override do contador de toque)
  #   next_action_at:  timestamp opcional (override do próximo toque)
  #   fields:          { modelo_interesse, tem_troca, forma_pagamento, urgencia }
  #   source:          string opcional pra novos leads (default 'n8n')
  #
  # NOTA: o upsert_by_conversation existente segue intacto; o n8n só passa a
  # chamar este endpoint num corte posterior.
  def transition
    return render(json: { error: 'conversation_id is required' }, status: :unprocessable_entity) if params[:conversation_id].blank?
    return render(json: { error: 'signal is required' }, status: :unprocessable_entity) if params[:signal].blank?

    conv = resolve_conversation(params[:conversation_id])
    return render(json: { error: 'conversation not found' }, status: :not_found) if conv.nil?

    @lead = find_or_create_lead(conv)
    ::Synapseos::LeadLifecycle.transition(lead: @lead, signal: params[:signal], **transition_attrs)
    render :show
  rescue ::Synapseos::LeadLifecycle::InvalidSignal,
         ::Synapseos::LeadLifecycle::MotivoRequired,
         ActiveRecord::RecordInvalid => e
    render(json: { error: e.message }, status: :unprocessable_entity)
  end

  private

  def find_or_create_lead(conv)
    lead = scope.find_or_initialize_by(conversation_id: conv.id) do |l|
      l.contact_id = conv.contact_id
      l.status = :open
      l.source = params[:source].presence || 'n8n'
    end
    lead.save! if lead.new_record?
    lead
  end

  # Achata o payload de transição nos attrs que LeadLifecycle.transition espera.
  def transition_attrs
    fields = params[:fields].respond_to?(:to_unsafe_h) ? params[:fields].to_unsafe_h.symbolize_keys : {}
    {
      motivo: params[:motivo].presence,
      horizonte_compra: params[:horizonte_compra].presence,
      cadence_touch: params[:cadence_touch].presence,
      next_action_at: params[:next_action_at].presence,
      modelo_interesse: fields[:modelo_interesse],
      tem_troca: fields.key?(:tem_troca) ? ActiveModel::Type::Boolean.new.cast(fields[:tem_troca]) : nil,
      forma_pagamento: fields[:forma_pagamento],
      urgencia: fields[:urgencia]
    }.compact
  end

  # n8n/Chatwoot webhooks sempre passam display_id (convenção pública do
  # Chatwoot). Resolvemos display_id PRIMEIRO; fallback p/ id interno só pra
  # chamadas legadas. Evita a colisão display×interno (ex: display 336 do
  # Marco batia no interno 336 do Almir).
  def resolve_conversation(id)
    return nil if id.blank?

    ::Conversation.find_by(account_id: Current.account.id, display_id: id) ||
      ::Conversation.find_by(account_id: Current.account.id, id: id)
  end

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
