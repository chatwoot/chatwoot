class Api::V1::Accounts::Autonomia::Agents::BuildThreadsController < Api::V1::Accounts::Autonomia::BaseController
  before_action :fetch_thread, only: [:show, :messages, :retry_build]

  def show; end

  # Abre a conversa do Construtor e dispara a geração assíncrona em job (begin_build! gera o build_token;
  # o SubmitJob roda a chamada SÍNCRONA ao modelo em poucos segundos) e retorna 202. O front faz polling
  # pelo `show` até status ready/failed.
  # IA-FALA-PRIMEIRO (item 3): a abertura pode vir SEM mensagem do usuário (ele só escolheu o `type`); o
  # Builder gera o 1º turno (saudação + 1ª pergunta) guiado pelo esqueleto do tipo. Quando há mensagem,
  # ela é empilhada normalmente. O guard de mensagem em branco fica só no `messages` (continuação).
  def create
    @thread = build_threads_scope.new(thread_params)
    @thread.created_by = Current.user
    @thread.persist_start_options!(type: params[:type], actuation: params[:actuation], with_knowledge: params[:with_knowledge])
    @thread.save!
    append_user_message! if params[:message].present?
    persist_no_materials_flag
    persist_force_close_flag
    claim_build_and_enqueue
  end

  # Continua a conversa: empilha a mensagem do usuário e refaz a geração (novo build_token).
  # E3/T6 — uma geração por vez, decidido ATOMICAMENTE: o claim do begin_build! (UPDATE com WHERE
  # guard no status/janela stale) vem ANTES do append, então requests simultâneos nunca gravam
  # turno duplo nem enfileiram dois SubmitJobs — o perdedor recebe 409 com código estável
  # (`build_in_progress`) e nada é persistido. Stale (job morto além de STALE_PROCESSING_AFTER)
  # destrava o reenvio normalmente.
  def messages
    return render_unprocessable(I18n.t('autonomia.build_thread.message_blank')) if params[:message].blank?
    # T6 — replay do MESMO turno (double-click / retry de rede): o último turno user já foi gravado
    # com este client_message_id, então devolve o estado atual (200) sem novo append nem job. Turnos
    # NOVOS de conteúdo idêntico ganham cid novo no front e nunca são engolidos.
    return render :show, status: :ok if duplicate_client_message?

    token = @thread.begin_build!
    return render_build_in_progress if token.nil?

    append_user_message!
    persist_no_materials_flag
    persist_force_close_flag
    enqueue_submit_job(token)
  end

  # E2 — reexecuta a geração de uma thread `failed` (ou presa em `processing` além da janela stale):
  # mesmo caminho do enqueue normal (begin_build! gera novo token + SubmitJob). Nada é empilhado no
  # histórico — só a geração roda de novo sobre o estado atual. O claim atômico do begin_build!
  # responde 409 quando um build vivo ainda detém o slot (mesma regra do submit). A action chama-se
  # retry_build porque `retry` é palavra reservada do Ruby; a rota expõe POST :retry.
  def retry_build
    return render_unprocessable(I18n.t('autonomia.build_thread.retry_unavailable')) unless @thread.failed? || @thread.processing?

    claim_build_and_enqueue
  end

  private

  # Empilha a mensagem do usuário no turno atual (texto + imagens anexadas). Compartilhado por
  # `create` (abertura com mensagem) e `messages` (continuação).
  def append_user_message!
    @thread.append_message!('user', params[:message], image_signed_ids: image_signed_ids_param,
                                                      client_message_id: params[:client_message_id])
  end

  # Portão de materiais (instrução-mãe §13): o front sinaliza `no_materials: true` quando o usuário
  # avança a etapa de materiais sem subir nada. Persistimos no jsonb `state` para o Builder liberar o
  # fechamento da instrução mesmo sem fontes revisadas. Só grava quando o param vem presente (não
  # sobrescreve a declaração anterior em mensagens subsequentes).
  def persist_no_materials_flag
    return if params[:no_materials].nil?

    @thread.update!(no_materials_declared: ActiveModel::Type::Boolean.new.cast(params[:no_materials]))
  end

  # #3 INSTRUÇÃO VIVA (auto-finalize): o front sinaliza `force_close: true` quando o usuário avança da
  # etapa Conversa/Materiais para a Revisão (completeMaterials). É um gatilho de fechamento
  # DETERMINÍSTICO e INDEPENDENTE DE IDIOMA — o Builder força needs_more_info=false sem depender do
  # match de texto localizado (a frase de fechamento em EN não casava a regex PT-only). Só grava
  # quando o param vem presente; uma vez true, fica true (não desfaz auto-finalize em turnos seguintes).
  def persist_force_close_flag
    return if params[:force_close].nil?

    @thread.update!(force_close: ActiveModel::Type::Boolean.new.cast(params[:force_close]))
  end

  # MULTIMODAL (async): signed_ids das imagens anexadas ao turno atual, emitidos pelo endpoint de upload
  # do builder (agents/builder_images) na conta corrente. Cortado em MAX_IMAGES; o Builder revalida cada
  # blob (content-type imagem + tamanho) antes de ler. Vazio quando não há imagem (turno só-texto).
  def image_signed_ids_param
    Array(params[:image_signed_ids]).map(&:to_s).compact_blank.first(Autonomia::Agents::Config::MAX_IMAGES_PER_MESSAGE)
  end

  def fetch_thread
    @thread = build_threads_scope.find(params[:id])
  end

  # E3 — 409 Conflict com código estável (`build_in_progress`): o front distingue do erro genérico
  # de envio e mostra um alerta amigável em vez de marcar a conversa como falha.
  def render_build_in_progress
    render json: { error: I18n.t('autonomia.build_thread.build_in_progress'), code: 'build_in_progress' },
           status: :conflict
  end

  # T6 — claim atômico + enqueue + resposta 202, com 409 quando outro build vivo já detém o slot.
  # Usado pelo create (thread recém-criada, claim sempre vence) e pelo retry.
  def claim_build_and_enqueue
    token = @thread.begin_build!
    return render_build_in_progress if token.nil?

    enqueue_submit_job(token)
  end

  def enqueue_submit_job(token)
    # #18 — o supersede de ajustes concorrentes é decidido no fechamento (apply_builder_config!), pelo
    # id monotônico da thread: uma sessão de ajuste mais nova (id maior) vence a mais antiga. Sem
    # marcação aqui (deadlock-free).
    Autonomia::Agents::Builder::SubmitJob.perform_later(@thread.id, token)
    render :show, status: :accepted
  end

  # T6 — replay idempotente: o último turno user da thread já carrega este client_message_id
  # (double-click / retry de rede do MESMO turno). Sem cid (legado) não deduplica.
  def duplicate_client_message?
    cid = params[:client_message_id].to_s.presence
    return false if cid.blank?

    last_user_turn = Array(@thread.messages).reverse.find { |m| m['role'] == 'user' }
    last_user_turn.present? && last_user_turn['cid'] == cid
  end

  # Resolve o agente SEMPRE dentro do escopo da conta corrente (agents_scope) — nunca aceita o FK
  # cru do params, que permitiria vincular a thread a um agente de OUTRA conta (IDOR: leitura do
  # conhecimento + escrita de config cross-account). Sem agente = construtor cria um rascunho depois.
  def thread_params
    agent_id = params.dig(:build_thread, :autonomia_agent_id).presence || params[:autonomia_agent_id].presence
    return {} if agent_id.blank?

    { agent: agents_scope.find(agent_id) }
  end
end
