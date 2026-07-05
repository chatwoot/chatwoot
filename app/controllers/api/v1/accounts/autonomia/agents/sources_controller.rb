class Api::V1::Accounts::Autonomia::Agents::SourcesController < Api::V1::Accounts::Autonomia::BaseController
  before_action :fetch_agent
  before_action :fetch_source, only: [:destroy, :resync]

  def index
    @sources = @agent.sources.order(created_at: :desc)
  end

  def create
    kind = resolved_kind
    return render_unprocessable(I18n.t('autonomia.source.invalid_kind')) if kind.nil?

    if knowledge_limit_reached?(kind)
      return render_unprocessable(
        I18n.t('autonomia.source.limit_reached', limit: Autonomia::Agents::Source::MAX_KNOWLEDGE_SOURCES)
      )
    end

    @source = @agent.sources.new(source_params)
    @source.account = Current.account
    @source.kind = kind
    attach_file
    @source.save!
    # GAP (A) — pipeline por `kind`. knowledge segue o caminho ATUAL (ingest → embed → revisora).
    # media é caminho NOVO: NÃO enfileira IngestJob (sem embed/revisora); só armazena e marca ready.
    if @source.kind_media?
      @source.mark_media_ready!
    else
      Autonomia::Agents::Knowledge::IngestJob.perform_later(@source.id)
    end
    render :show, status: :created
  end

  # Excluir material: remove a fonte + seus trechos (knowledge_entries dependent: :delete_all) e
  # revalida a confiança geral da base (MAPA DE TEMAS/knowledge_confidence/knowledge_summary), pois
  # o conteúdo aprovado restante mudou. Best-effort assíncrono — a exclusão responde já.
  def destroy
    agent = @source.agent
    @source.destroy!
    Autonomia::Agents::Knowledge::RecomputeOverallJob.perform_later(agent.id)
    head :no_content
  end

  # Re-sincroniza a fonte: novo IngestJob gera novo sync_token que supersede qualquer ingestão em
  # andamento (jobs velhos viram no-op pelo token-guard do model).
  def resync
    Autonomia::Agents::Knowledge::IngestJob.perform_later(@source.id)
    render :show, status: :accepted
  end

  private

  # Anexa o arquivo (quando há) e popula metadata visível (byte_size/mime) a partir do upload.
  def attach_file
    file = params[:file]
    return if file.blank?

    @source.file.attach(file)
    @source.byte_size = file.size if file.respond_to?(:size)
    @source.mime = file.content_type if file.respond_to?(:content_type)
  end

  # GAP (A) — aceita `kind` em `source[:kind]` OU `descriptor[:kind]` (o FE manda no descriptor do
  # upload). Default conservador `knowledge` (caminho atual, inalterado). Retorna o valor válido OU
  # nil quando vier fora do vocabulário do enum (o create responde 422, em vez do ArgumentError 500
  # do enum setter com valor inválido).
  def resolved_kind
    raw = (params.dig(:source, :kind).presence ||
           params.dig(:descriptor, :kind).presence ||
           params[:kind].presence ||
           'knowledge').to_s
    Autonomia::Agents::Source.kinds.key?(raw) ? raw : nil
  end

  # Teto só para CONHECIMENTO (mídia de envio tem pipeline próprio, sem limite). Conta as fontes
  # knowledge já existentes do agente; ao atingir o teto, o create responde 422 (o FE já desabilita
  # o dropzone, isto é a defesa de servidor).
  def knowledge_limit_reached?(kind)
    kind == 'knowledge' &&
      @agent.sources.knowledge_sources.count >= Autonomia::Agents::Source::MAX_KNOWLEDGE_SOURCES
  end

  def fetch_agent
    @agent = agents_scope.find(params[:agent_id])
  end

  def fetch_source
    @source = @agent.sources.find(params[:id])
  end

  def source_params
    params.require(:source).permit(:source_type, :reference, :external_link)
  end
end
