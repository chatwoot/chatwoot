module Autonomia
  module Agents
    class Agent < ApplicationRecord
      self.table_name = 'autonomia_agents'

      include Avatarable

      belongs_to :account
      belongs_to :created_by, class_name: 'User', optional: true
      has_many :sources, class_name: 'Autonomia::Agents::Source',
                         foreign_key: :autonomia_agent_id, dependent: :destroy
      has_many :knowledge_entries, class_name: 'Autonomia::Agents::KnowledgeEntry',
                                   foreign_key: :autonomia_agent_id, dependent: :destroy
      has_many :build_threads, class_name: 'Autonomia::Agents::BuildThread',
                               foreign_key: :autonomia_agent_id, dependent: :nullify
      has_many :agent_inboxes, class_name: 'Autonomia::Agents::AgentInbox',
                               foreign_key: :autonomia_agent_id, dependent: :destroy
      has_many :inboxes, through: :agent_inboxes
      # Revisor v2: só as fontes APROVADAS pela IA Revisora alimentam o Construtor (resumos) e o
      # retrieval do Testar/Operar. needs_resend/needs_review ficam de fora.
      has_many :accepted_sources, -> { accepted }, class_name: 'Autonomia::Agents::Source',
                                  foreign_key: :autonomia_agent_id
      # Fase F: eventos de operação (replied/handed_off). delete_all = limpeza barata e
      # imutável ao destruir o agente; o Analytics consulta por autonomia_agent_id direto.
      has_many :events, class_name: 'Autonomia::Agents::AgentEvent',
                        foreign_key: :autonomia_agent_id, dependent: :delete_all

      enum status: { draft: 0, active: 1, paused: 2 }
      enum mode:   { guided: 0, manual: 1 }
      # V2.1 — onde o agente atua. external (atende clientes, comportamento atual) /
      # internal (copiloto da equipe, nunca fala com cliente) / both. Default external.
      enum actuation: { external: 0, internal: 1, both: 2 }, _prefix: :actuation

      AGENT_TYPES = %w[support sdr reception onboarding scheduler reactivation custom].freeze
      validates :name, presence: true
      validates :agent_type, inclusion: { in: AGENT_TYPES }

      store_accessor :config, :model, :temperature, :business_hours, :max_turns, :guardrails
      # V2.1 — hint de construção: o dono declarou que o agente terá (ou não) base de conhecimento.
      # Reflexo no jsonb `config` (sem migração); o Construtor já lê via with_knowledge?.
      store_accessor :config, :with_knowledge
      store_accessor :config, :confidence_threshold # Fase B: portão de confiança (lido no Answerer)
      # Fase D: handoff real configurável por agente (jsonb `config`, sem migração).
      # handoff_strategy ∈ Operate::HANDOFF_STRATEGIES; default conservador = 'none'
      # (comportamento da Fase C: só mensagem graciosa + bot_handoff!, conversa fica unassigned).
      # handoff_target_id = id do User (assign_member) ou Team (assign_team) alvo.
      store_accessor :config, :handoff_strategy, :handoff_target_id
      # Revisor v2: MAPA DE TEMAS + confiança geral da base, gravados por Reviewer.recompute_overall!
      # no jsonb `config` (sem migração). Alimentam a UI de Conhecimento e o Construtor (NÃO o
      # jbuilder do agente expõe instruction/scaffold; estes 3 são seguros de expor).
      store_accessor :config, :topic_map, :knowledge_confidence, :knowledge_summary
      # #3 INSTRUÇÃO VIVA (B): token de coalescência do refresh debounced da instrução. Uma rajada de
      # uploads grava tokens sucessivos; só o ÚLTIMO RefreshInstructionJob enfileirado (token corrente)
      # roda — os anteriores viram no-op. Vive no jsonb `config` (sem migração); NÃO é exposto pelo
      # jbuilder (não está na lista de campos seguros do serializer) e nunca vaza a instrução.
      store_accessor :config, :knowledge_refresh_token

      # C3 (custo): agente declarado SEM base de conhecimento. ATENÇÃO ao default histórico: a
      # AUSÊNCIA da chave `with_knowledge` significa COM base (true) — só o `false` explícito
      # (boolean ou a string 'false', como o jsonb pode guardar) desliga. Usado p/ pular o
      # retrieval/embedding no Answerer (agente sem base não paga embedding por mensagem nem
      # usa entries residuais). Mesmo contrato do jbuilder (`with_knowledge != false`).
      def knowledge_disabled?
        [false, 'false'].include?(config.to_h['with_knowledge'])
      end

      # Aplica config gerada pelo Construtor (token-guarded — análogo a ai_guarded_update do
      # EmailCampaign). `build_token` é o token ativo do BuildThread; a escrita só vence se este
      # ainda for o token da geração corrente (idempotência anti-supersede). `attrs` já vem mapeado
      # do schema do Builder para colunas (incluindo instruction/scaffold ocultos). Retorna true se
      # esta geração ganhou a escrita.
      def apply_builder_config!(build_token, attrs)
        return false if build_token.blank?

        transaction do
          thread = build_threads.where(build_token: build_token).lock.first
          next false if thread.nil? || !thread.processing?

          # #18 — AJUSTES CONCORRENTES (deadlock-free): o id da BuildThread é monotônico (sessão de
          # ajuste mais nova = id maior). Se existe QUALQUER thread mais nova deste agente, esta é stale
          # → no-op (o ajuste mais NOVO vence). É só um SELECT escopado ao agente (sem lock do agente,
          # sem marcação, sem ordem de lock invertida) → não há deadlock com este `lock` na própria
          # thread. Criação (thread única) nunca tem uma mais nova → aplica normal.
          next false if build_threads.where('id > ?', thread.id).exists?

          # Merge no jsonb `config` em vez de substituí-lo: preserva model/temperature/business_hours/
          # max_turns já setados (o Construtor só gera `guardrails`). Substituir zeraria a config a
          # cada "Ajustar com IA".
          merged = attrs.dup
          merged[:config] = config.to_h.merge(attrs[:config] || {}) if attrs.key?(:config)
          update!(merged)
          true
        end
      end

      # #3 INSTRUÇÃO VIVA — Atualiza a instrução fora do fluxo do Construtor (a KB mudou, não há
      # BuildThread em geração). Escrita CONDICIONAL ATÔMICA (G1, anti-corrida check→write): só
      # vence se o agente CONTINUA `guided` (modo manual = instrução escrita à mão pelo usuário,
      # intocável pelo refresh automático) E a instrução no banco ainda é a que o refresh fotografou
      # (`expected_instruction` — uma edição concorrente do painel perde de propósito). Toca SÓ a
      # coluna `instruction` (oculta); `config` — topic_map/knowledge_summary/confidence — acabou de
      # ser gravado por recompute_overall! no mesmo agente, então NÃO é tocado (preservado por
      # omissão). Não dispara recompute_overall! de volta (não mexe em config/sources): sem loop.
      # Agent não tem callbacks → update_all é seguro. Retorna true se ganhou a escrita.
      def refresh_instruction!(new_instruction, expected_instruction:)
        rows = self.class.where(id: id, mode: self.class.modes[:guided], instruction: expected_instruction)
                   .update_all(instruction: new_instruction, updated_at: Time.current)
        reload if rows.positive?
        rows.positive?
      end

      # #3 INSTRUÇÃO VIVA (B): grava um token de coalescência novo no jsonb `config` e o retorna.
      # Usado por RefreshInstructionJob.enqueue p/ deduplicar a rajada de uploads. P2 (Onda 6) —
      # escrita ATÔMICA por chave (jsonb_set): toca SÓ `knowledge_refresh_token`, sem read-modify-write,
      # fechando a corrida de config end-to-end (não clobbera topic_map/knowledge_* nem um save do
      # PanelTune que ocorra entre o reload e o write). Agent não tem callbacks → update_all é seguro.
      def bump_knowledge_refresh_token!
        token = SecureRandom.hex(8)
        self.class.where(id: id).update_all(
          ['config = jsonb_set(COALESCE(config, \'{}\'::jsonb), \'{knowledge_refresh_token}\', ?::jsonb, true), updated_at = ?',
           token.to_json, Time.current]
        )
        token
      end
    end
  end
end
