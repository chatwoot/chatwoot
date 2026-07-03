module Autonomia
  module Agents
    class Config
      BOOLEAN = ActiveModel::Type::Boolean.new

      BUILDER_MODEL = Crm::Ai::Config::MODEL_EMAIL # gpt-5.4
      # Construtor é um CHAT: chamada SÍNCRONA (ResponsesClient#create). O reasoning é ESCOLHIDO POR
      # FASE (Builder#run! decide) para atacar a latência (~24s/turno na campanha real):
      #   - COLETA (turnos de entrevista): 'low'. São perguntas curtas, sem geração da instruction
      #     final; reasoning baixo derruba a latência da maioria dos turnos sem perder qualidade.
      #   - FECHAMENTO (needs_more_info=false): 'medium'. Aqui se REDIGE a instruction completa do
      #     agente (escopo ancorado, blindagens, mapa de conhecimento) — vale o reasoning maior.
      # 'high' (herdado do gerador de e-mail) fazia a entrevista demorar ~25s; aposentado aqui.
      # Fase 1 tuning: coleta sobe p/ 'medium' (qualidade da entrevista) — antes 'low' por latência.
      BUILDER_REASONING_EFFORT_COLLECT = 'medium'.freeze
      BUILDER_REASONING_EFFORT_FINAL = 'medium'.freeze
      # Compat: call-sites/specs antigos que referenciam o nome único caem no efforte de fechamento
      # (comportamento conservador — qualidade sobre latência quando a fase é desconhecida).
      BUILDER_REASONING_EFFORT = BUILDER_REASONING_EFFORT_FINAL
      # Memória de sessão do Construtor (decisão do PO §4): janela rolante das últimas N mensagens
      # enviadas ao modelo. Tudo é guardado no jsonb `messages` (histórico completo), mas só a janela
      # vai ao input — controla custo/latência sem perder o registro.
      BUILDER_HISTORY_WINDOW = 30

      # Revisor v2 — IA Revisora de Qualidade (structured output por fonte + agregação da base).
      # Chamada SÍNCRONA dentro do ProcessJob (após embed). 'low' basta: structured output objetivo
      # sobre trechos curtos; mantém a ingestão rápida.
      REVIEWER_MODEL = Crm::Ai::Config::MODEL_EMAIL # gpt-5.4
      # Fase 1 tuning: revisor sobe p/ 'medium' (julgamento de qualidade mais firme).
      REVIEWER_REASONING_EFFORT = 'medium'.freeze

      # #3 INSTRUÇÃO VIVA — Refresh automático da instrução quando a KB muda (add/remove). Reusa o
      # modelo do Construtor (redação de instrução, como o fechamento) com effort 'medium'. NÃO é
      # entrevista: só reescreve o bloco de escopo/conhecimento da instrução de agentes JÁ FECHADOS.
      INSTRUCTION_REFRESH_MODEL = BUILDER_MODEL # gpt-5.4
      INSTRUCTION_REFRESH_REASONING_EFFORT = BUILDER_REASONING_EFFORT_FINAL # 'medium'

      # KILL-SWITCH do refresh automático da instrução (#3). Default LIGADO; desligar via ENV
      # AI_INSTRUCTION_AUTO_REFRESH=false trava o disparo em recompute_overall! sem tocar código.
      def self.instruction_auto_refresh?
        BOOLEAN.cast(ENV.fetch('AI_INSTRUCTION_AUTO_REFRESH', true))
      end

      # CHUNKING ESTRUTURADO (P1.1a) — re-chunk por fronteira estrutural (parágrafo / linha-registro de
      # JSON|XLSX / item de lista), 1 chunk por unidade; unidades curtas demais (< Chunker::MERGE_FLOOR)
      # são coladas na vizinha e unidades acima de CHUNK_MAX caem na janela deslizante (fallback).
      # Antes era uma janela deslizante única de CHUNK_SIZE=1000: como os KBs reais têm <1000 chars,
      # cada arquivo virava 1 ÚNICO chunk multi-tópico → o embedding diluía fatos pontuais e o cutoff
      # de cosseno descartava o único chunk relevante (S01/S12/S15). Agora geram vários chunks
      # mono-tópico ("frete grátis…", "troca…", "Notebook Pro 15 R$4999") recuperáveis isoladamente.
      CHUNK_MAX = 600          # chars-teto: unidade única acima disso cai na janela deslizante (fallback)
      CHUNK_OVERLAP = 80       # overlap (chars) usado SÓ no fallback de janela p/ unidade longa
      # Compat: specs/call-sites legados que referenciam CHUNK_SIZE caem no teto estrutural.
      CHUNK_SIZE = CHUNK_MAX

      # EMBEDDING (B1 Onda 6) — upgrade text-embedding-3-small (1536) -> 3-large (3072), SEM regressão,
      # via DUAS colunas + cutover por config. FONTE ÚNICA da resolução de modelo (EmbeddingService,
      # Ingestor e Retriever leem DAQUI p/ query e base ficarem sempre no mesmo modelo/coluna):
      #   - modelo ativo = InstallationConfig AUTONOMIA_EMBEDDING_MODEL (default 3-small do LlmConstants).
      #   - 3-small -> coluna :embedding (vector 1536, gem neighbor). 3-large -> :embedding_large
      #     (halfvec 3072, NN por SQL cru no Retriever — a gem não conhece halfvec).
      # Cutover: o backfill preenche :embedding_large em TODA a base ANTES de a config virar 3-large;
      # até lá o Retriever consulta :embedding (populada) e não há janela de retrieval vazio.
      # ISOLAMENTO cross-feature (CRÍTICO, regra 2): chave PRÓPRIA `AUTONOMIA_EMBEDDING_MODEL`, NÃO a
      # `CAPTAIN_EMBEDDING_MODEL` — esta é compartilhada com o Captain/Help Center (colunas vector(1536)
      # da gem neighbor). Virar 3-large aqui NÃO pode gerar 3072 dims contra as colunas 1536 do Captain.
      EMBEDDING_MODEL_KEY = 'AUTONOMIA_EMBEDDING_MODEL'.freeze
      EMBEDDING_MODEL_SMALL = 'text-embedding-3-small'.freeze
      EMBEDDING_MODEL_LARGE = 'text-embedding-3-large'.freeze
      EMBEDDING_LARGE_COLUMN = :embedding_large
      EMBEDDING_SMALL_COLUMN = :embedding

      def self.active_embedding_model
        InstallationConfig.find_by(name: EMBEDDING_MODEL_KEY)&.value.presence ||
          LlmConstants::DEFAULT_EMBEDDING_MODEL
      end

      # 3-large (3072) é detectado por substring p/ tolerar variações de nome (ex.: dated snapshots).
      def self.embedding_large?(model = active_embedding_model)
        model.to_s.include?('3-large')
      end

      # Coluna de embedding ativa (símbolo) p/ leitura/escrita coerentes com o modelo ativo.
      def self.embedding_column(model = active_embedding_model)
        embedding_large?(model) ? EMBEDDING_LARGE_COLUMN : EMBEDDING_SMALL_COLUMN
      end

      # KB-quality Bloco B / B2.1 — CHUNKING ADAPTATIVO por TIPO/ESTILO do material (decisão do PO:
      # qualidade sobre custo). O CHUNK_MAX=600 default é bom p/ tabular/registro, mas fragmenta
      # PROSA (política/PDF contínuo) no meio de uma seção coerente. Cada PERFIL escolhe o teto de
      # janela do fallback de acordo com a ASSINATURA do conteúdo (barata, determinística):
      #   - tabular : 1 registro/linha por chunk (XLSX/JSON). Teto baixo — registro é curto.
      #   - faq     : 1 par Pergunta+Resposta por chunk (janela média p/ caber P+R).
      #   - list    : 1 passo/item por chunk (procedimento). Teto baixo.
      #   - prose   : janela GRANDE p/ não picar uma seção contínua de política/PDF em micro-chunks.
      # O overlap acompanha o teto (proporcional ao fallback de janela). O piso de merge muda pouco:
      # tabular/list querem registros isolados (piso baixo), prosa cola parágrafos curtos (piso alto).
      CHUNK_PROFILES = {
        tabular: { max: 300, overlap: 60,  merge_floor: 20 },
        faq: { max: 700, overlap: 120, merge_floor: 45 },
        list: { max: 300, overlap: 60,  merge_floor: 30 },
        prose: { max: 900, overlap: 140, merge_floor: 80 }
      }.freeze
      # Perfil default quando não há assinatura clara / chamada sem source_type (retrocompat do
      # Chunker.new(text) sem kwargs → mantém CHUNK_MAX/CHUNK_OVERLAP históricos, specs antigos passam).
      DEFAULT_CHUNK_PROFILE = { max: CHUNK_MAX, overlap: CHUNK_OVERLAP, merge_floor: 45 }.freeze

      # KB-quality Bloco B / B2.3 — CLASSIFICADOR de documento (1 chamada LLM por FONTE, não por chunk).
      # Reusa o modelo/effort do Revisor (gpt-5.4, structured output) p/ extrair topics/entities/style do
      # documento inteiro e carimbar em TODO chunk (metadata.doc) — mais recall por termo de negócio.
      # Best-effort: erro/credential ausente → classificação vazia, NUNCA derruba a ingestão.
      DOCUMENT_CLASSIFIER_MODEL = REVIEWER_MODEL # gpt-5.4
      DOCUMENT_CLASSIFIER_REASONING_EFFORT = 'medium'.freeze
      # Teto do texto enviado ao classificador (custo/latência): amostra o começo do documento; o
      # objetivo é rotular o material, não lê-lo inteiro (o Revisor já faz amostra estratificada).
      DOCUMENT_CLASSIFIER_MAX_CHARS = 8_000
      # KB-quality Bloco A (2026-07-03): qualidade sobre custo (decisão do PO — quem paga é o cliente e
      # quer resposta correta). top_k 8→12 dá mais opções de fundamento ao Answerer (o dedup por fonte
      # continua, então mais fontes distintas chegam). Custo por resposta sobe (mais tokens no prompt).
      RETRIEVER_TOP_K = 12

      # MULTIMODAL (leitura de imagens inline no builder): imagens anexadas à mensagem ATUAL são lidas
      # pelo modelo como input_image (não viram conhecimento). Limites próprios do builder (produto pediu
      # 5MB/imagem, máx 4) — independentes de Crm::Ai::Config::IMAGE_BYTE_LIMIT (18MB, da campanha).
      # Allowlist espelha EmailCampaigns::Ai::Generator::IMAGE_TYPES (mesma do gerador de campanha); cópia
      # literal p/ não acoplar a ordem de carga entre namespaces distintos.
      IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
      MAX_IMAGE_BYTES = 5.megabytes
      MAX_IMAGES_PER_MESSAGE = 4
      # Onda 2 / Track B: teto de áudios transcritos por turno (limita custo/latência da transcrição).
      MAX_AUDIO_PER_MESSAGE = 2

      # Fase B — motor de resposta (RAG + portão de confiança / Testar / Copiloto)
      # Modelo fixado em gpt-5.4 (desacoplado de MODEL_AUTO_MOVE, que foi p/ mini na Fase 1 — o
      # Answerer fala com o cliente e mantém o modelo forte).
      ANSWERER_MODEL = 'gpt-5.4'.freeze
      # Fase 1 tuning: answerer sobe p/ 'medium' (resposta ao cliente com mais raciocínio).
      ANSWERER_REASONING_EFFORT = 'medium'.freeze
      DEFAULT_CONFIDENCE_THRESHOLD = 0.55
      ANSWER_TOP_K = 12 # KB-quality Bloco A: acompanha RETRIEVER_TOP_K (mais fundamento por resposta)
      # Retrieval (P1.1b) — DOIS patamares de distância de cosseno, substituindo o cutoff ABSOLUTO
      # único de 0.45 que zerava o [CONTEXTO] (probe real: "frete grátis"=0.5038, "notebooks"=0.478,
      # "parcela"=0.7382 — todos >0.45, descartados, mesmo com o fato na KB):
      #   - RETRIEVAL_HARD_CEILING = teto FROUXO de segurança. Acima disso é lixo de outro tópico
      #     (genuíno fora-de-escopo: "cardápio de pizza" num salão) e é descartado. Mantém o
      #     isolamento que o 0.45 fazia por acidente, sem matar o recall do chunk certo.
      #   - RETRIEVAL_STRONG_MATCH = NÃO filtra nada; é só um RÓTULO de força (strong/weak) que o
      #     Answerer usa p/ ancorar confiança e o gate NOKB (P2.1/P2.2). O Retriever sempre devolve
      #     os melhores top_k abaixo do teto frouxo — nunca mais zera tudo a 0.45.
      RETRIEVAL_HARD_CEILING = 0.75
      RETRIEVAL_STRONG_MATCH = 0.45
      # Compat: specs/call-sites legados que referenciam SIMILARITY_MAX_DISTANCE passam a ler o
      # patamar de match forte (rótulo), NÃO um cutoff que descarta.
      SIMILARITY_MAX_DISTANCE = RETRIEVAL_STRONG_MATCH
      HISTORY_MAX_TURNS = 16 # pares user/assistant no prompt (Bloco A: 10→16, mais contexto de conversa)

      # TETOS DE CARACTERES (C1 — custo de IA). Sem teto, um texto colado gigante do usuário ou um
      # histórico de mensagens enormes infla o input do LLM a cada turno (tokens = custo). Valores com
      # folga generosa p/ conversa legítima de atendimento; cortam só o desperdício/abuso:
      #   - MAX_QUERY_CHARS: entrada AUTORAL do usuário (mensagem do widget do copiloto, draft e
      #     instrução de refino). ~1.5k tokens; nenhuma pergunta/rascunho legítimo passa disso.
      #   - MAX_COMPOSED_QUERY_CHARS: teto FINAL da query no PromptBuilder. Maior que o de cima porque
      #     a query composta pode embutir a transcrição da conversa + moldura de segurança do copiloto
      #     (transcrição já capada em 8k + pedido em 6k) — 16k nunca clipa esse caminho legítimo.
      #   - MAX_HISTORY_ITEM_CHARS: cada mensagem do histórico enviada ao modelo.
      #   - MAX_HISTORY_TOTAL_CHARS: orçamento TOTAL do histórico; preserva as mensagens MAIS RECENTES
      #     (as antigas saem primeiro quando o orçamento estoura).
      MAX_QUERY_CHARS = 6_000
      MAX_COMPOSED_QUERY_CHARS = 16_000
      MAX_HISTORY_ITEM_CHARS = 4_000
      MAX_HISTORY_TOTAL_CHARS = 40_000 # Bloco A: 24k→40k (gpt-5.4 tem 128k; conversa longa preserva mais contexto)
      TRUNCATION_SUFFIX = '…'.freeze

      # Truncamento CENTRAL: mantém o COMEÇO da string (o fim é descartado) e sinaliza o corte com o
      # sufixo '…'. Uma string dentro do teto volta intacta (sem sufixo).
      def self.truncate_text(text, max_chars)
        text = text.to_s
        return text if text.length <= max_chars

        "#{text[0, max_chars - TRUNCATION_SUFFIX.length]}#{TRUNCATION_SUFFIX}"
      end

      # Fase C — "Operar" (debounce do ReplyJob). Janela de coalescência: rajada de
      # mensagens do contato (ex.: várias linhas seguidas) vira UMA resposta sobre o
      # contexto mais recente. last-writer-wins sobre o token de debounce.
      OPERATE_DEBOUNCE_SECONDS = 6.seconds

      # Janela de debounce EFETIVA por agente (refino): default OPERATE_DEBOUNCE_SECONDS, mas o
      # agente pode sobrescrever via config['debounce_seconds'] (ex.: nicho que manda muitas linhas
      # curtas → janela maior). Clamp defensivo [2s, 30s] p/ não travar a conversa nem responder no susto.
      def self.debounce_seconds_for(agent)
        raw = agent&.config.is_a?(Hash) ? agent.config['debounce_seconds'] : nil
        secs = raw.respond_to?(:to_f) && raw.to_s.present? ? raw.to_f : nil
        return OPERATE_DEBOUNCE_SECONDS if secs.nil? || secs <= 0

        secs.clamp(2.0, 30.0).seconds
      end

      # ENTREGA HUMANIZADA (chunk + delay + "digitando") — traz para o agente NATIVO o que antes só
      # existia no fluxo n8n: a resposta única do Answerer é quebrada em pedaços naturais, com pausas
      # calculadas e indicador de digitação por canal (web widget nativo, WhatsApp Cloud, Instagram).
      # KILL-SWITCH global (ENV) + override POR AGENTE (config['humanize_delivery']). Ambos default ON:
      # o recurso foi pedido pelo produto; desligar é instantâneo (sem deploy) por ENV ou por agente.
      # OFF em qualquer camada → entrega 1 mensagem única (comportamento anterior, ZERO regressão).
      def self.humanize_delivery_enabled?(agent = nil)
        return false unless BOOLEAN.cast(ENV.fetch('AI_HUMANIZE_DELIVERY', true))
        return true if agent.nil?

        cfg = agent.config.is_a?(Hash) ? agent.config['humanize_delivery'] : nil
        cfg.nil? ? true : BOOLEAN.cast(cfg)
      end

      # Instruções v2 (humanização + audiência + mídia). KILL-SWITCH global (ENV, default ON): ligado,
      # o PromptBuilder usa o OUTPUT_FORMAT v2 (anti-"material", sensível à audiência cliente/atendente,
      # regras de mídia). OFF → cai no formato legado (rollback instantâneo sem deploy). Rollout global
      # (decisão do PO); o flag existe só p/ rollback rápido caso um agente LIVE se comporte mal.
      def self.prompt_v2_enabled?
        BOOLEAN.cast(ENV.fetch('AI_AGENT_PROMPT_V2', true))
      end

      # MÍDIA NO OPERATE (Onda 2 / Track B): liga o encanamento que faz a imagem/figurinha da última
      # incoming chegar ao modelo como input_image, e o áudio ser transcrito (Crm::Ai::TranscriptionClient,
      # sem logar conteúdo) e injetado na query. KILL-SWITCH global (ENV, default ON) + override por agente
      # (config['operate_media']). OFF em qualquer camada → o Responder responde só ao TEXTO (comportamento
      # anterior, ZERO regressão). Independente do prompt_v2: o v2 só descreve as regras de mídia no prompt;
      # este flag é quem efetivamente entrega a mídia ao Answerer.
      def self.operate_media_enabled?(agent = nil)
        return false unless BOOLEAN.cast(ENV.fetch('AI_AGENT_MEDIA', true))
        return true if agent.nil?

        cfg = agent.config.is_a?(Hash) ? agent.config['operate_media'] : nil
        cfg.nil? ? true : BOOLEAN.cast(cfg)
      end

      # REACTION NO OPERATE (Onda 2b / Track B): o core do Chatwoot DESCARTA reações (emoji) na
      # ingestão. Com este flag (e só em inbox com agente Autonomia ATIVO), a reação vira UMA mensagem
      # incoming sintética ("[o cliente reagiu com 👍 …]") para o agente interpretá-la (o prompt v2 decide
      # responder ou ficar em silêncio — "só quando fizer sentido"). KILL-SWITCH global (ENV, default ON) +
      # override por agente (config['operate_reactions']). OFF em qualquer camada → reações seguem
      # descartadas pelo core (ZERO regressão).
      def self.operate_reactions_enabled?(agent = nil)
        return false unless BOOLEAN.cast(ENV.fetch('AI_AGENT_REACTIONS', true))
        return true if agent.nil?

        cfg = agent.config.is_a?(Hash) ? agent.config['operate_reactions'] : nil
        cfg.nil? ? true : BOOLEAN.cast(cfg)
      end

      # ESPELHAMENTO DE ÁUDIO (Onda 2c): quando o cliente manda áudio, o agente responde EM ÁUDIO (TTS).
      # Outward-facing + custo de TTS → KILL-SWITCH global default OFF (opt-in): liga via ENV
      # `AI_AGENT_VOICE_REPLY=true` (e/ou por agente config['voice_reply']). OFF -> responde em texto
      # (comportamento atual, zero regressão). Só dispara no ESPELHAMENTO (turno com áudio do cliente).
      # ENV é o DEFAULT (default OFF); config['voice_reply'] é OVERRIDE por agente (precedência sobre o
      # ENV) — assim dá p/ LIGAR só um agente (config=true) com a ENV global ainda OFF, sem ativar p/ todos.
      def self.voice_reply_enabled?(agent = nil)
        env_default = BOOLEAN.cast(ENV.fetch('AI_AGENT_VOICE_REPLY', false))
        return env_default if agent.nil?

        cfg = agent.config.is_a?(Hash) ? agent.config['voice_reply'] : nil
        cfg.nil? ? env_default : BOOLEAN.cast(cfg)
      end

      # Voz do TTS por gênero do agente (config['voice'] = 'feminina'|'masculina', escolhido pelo
      # Construtor na criação a partir da persona; default feminina). Mapeia para vozes OpenAI.
      # marin/cedar = vozes mais novas e de maior fidelidade da OpenAI (recomendadas por ela), bem
      # mais naturais que coral/onyx. Confirmado que funcionam no endpoint gpt-4o-mini-tts.
      VOICE_BY_GENDER = { 'feminina' => 'marin', 'masculina' => 'cedar' }.freeze
      DEFAULT_TTS_VOICE = 'marin'.freeze

      def self.voice_for(agent)
        gender = (agent.respond_to?(:config) && agent.config.is_a?(Hash) ? agent.config['voice'] : nil).to_s.strip.downcase
        VOICE_BY_GENDER.fetch(gender, DEFAULT_TTS_VOICE)
      end

      # Direcionamento de fala do TTS (gpt-4o-mini-tts aceita `instructions`): entonação + pronúncia
      # PT-BR + ritmo. O modelo IGNORA o parâmetro `speed`, então o ~1,2x é pedido aqui (aproximado).
      # ENV define o default; config['voice_instructions'] por agente sobrepõe (tunar sem redeploy).
      DEFAULT_VOICE_INSTRUCTIONS = ENV.fetch(
        'AI_AGENT_VOICE_INSTRUCTIONS',
        'Fale em português do Brasil com pronúncia natural e correta, entonação expressiva e tom ' \
        'acolhedor e profissional, nunca robótico ou monótono. Ritmo ágil, cerca de 20% mais rápido ' \
        'que o normal, mantendo a clareza.'
      ).freeze

      def self.voice_instructions_for(agent)
        cfg = (agent.respond_to?(:config) && agent.config.is_a?(Hash) ? agent.config['voice_instructions'] : nil)
        cfg.to_s.strip.presence || DEFAULT_VOICE_INSTRUCTIONS
      end

      # Indicador de "digitando" nos canais externos (WhatsApp Cloud / Instagram). Sub-switch do
      # humanize: alguns operadores podem querer o chunk+delay SEM custo/efeito de typing por canal.
      # O typing do web widget é nativo e sempre acompanha o humanize (não passa por este gate).
      def self.channel_typing_enabled?
        BOOLEAN.cast(ENV.fetch('AI_HUMANIZE_CHANNEL_TYPING', true))
      end

      # Parâmetros do quebrador/ritmo (espelham o CONFIG do script n8n v3 que o produto calibrou).
      # Centralizados aqui p/ tunar sem caçar literais no código. Chars de chunk + janelas de delay (ms).
      HUMANIZE = {
        min_chunk_chars: 60, soft_max_chunk_chars: 260, hard_max_chunk_chars: 420, max_chunks: 5,
        first_chunk_extra_min_ms: 700, first_chunk_extra_max_ms: 1600,
        next_chunk_gap_min_ms: 450, next_chunk_gap_max_ms: 1100,
        per_char_min_ms: 24, per_char_max_ms: 38,
        newline_pause_ms: 180, bullet_pause_ms: 220,
        url_chunk_min_ms: 700, url_chunk_max_ms: 1800, url_lead_pause_ms: 250,
        min_chunk_delay_ms: 900, max_chunk_delay_ms: 15_000, max_total_delay_ms: 90_000,
        punctuation_pause_ms: { '.' => 250, ',' => 90, ';' => 130, ':' => 150, '!' => 280, '?' => 320, '…' => 280 }
      }.freeze

      # Gate em duas camadas (aditivo, compatível) — ISOLADO do sistema de features
      # do Chatwoot (NÃO toca featurable/feature_flags):
      #   1) ENV master AUTONOMIA_AGENTS_ENABLED = kill-switch GLOBAL. Se OFF, o
      #      recurso fica OFF em TODAS as contas, mesmo marcadas como habilitadas.
      #   2) marca POR CONTA persistida no jsonb INTERNO `accounts.internal_attributes`
      #      (não editável pelo usuário; já existe no schema base). Só libera nas
      #      contas explicitamente marcadas via enable_for!.
      #
      # Sem `account` (compat): mantém o comportamento histórico de só-ENV — usado
      # por call-sites que ainda não resolveram a conta. Com `account`: exige ENV
      # master ligada E a conta marcada como habilitada.
      INTERNAL_ATTR_KEY = 'autonomia_agents_enabled'.freeze

      def self.enabled?(account = nil)
        master = BOOLEAN.cast(ENV.fetch('AUTONOMIA_AGENTS_ENABLED', false))
        return master if account.nil?

        # Boolean estrito: o payload da conta (_account.json.jbuilder) e os gates FE
        # comparam com `=== true`; garantir true/false (nunca nil) evita `null` no JSON.
        master && account_enabled?(account)
      end

      # Decisão POR CONTA, em camadas (precedência de cima p/ baixo):
      #   1) flag interno EXPLÍCITO (`autonomia_agents_enabled` true/false): opt-in OU opt-out manual
      #      por conta SEMPRE vence — permite ligar uma conta sem chave (piloto) ou desligar uma conta
      #      problemática mesmo no modo global.
      #   2) GLOBAL "só onde funciona": com ENV AUTONOMIA_AGENTS_GLOBAL=true e SEM flag explícito, liga
      #      automaticamente em qualquer conta que tenha CREDENCIAL DE IA resolvível (própria do Kanban AI
      #      ou de sistema). Auto-inclui contas futuras assim que configurarem a chave; nunca expõe um
      #      construtor sem chave (UX limpa). Sem o global, mantém o opt-in manual histórico.
      def self.account_enabled?(account)
        raw = account.internal_attributes[INTERNAL_ATTR_KEY]
        return BOOLEAN.cast(raw) unless raw.nil?

        global_enabled? && ai_credential_available?(account)
      end

      # Conta marcada explicitamente como habilitada pelo gate isolado (independente da ENV master).
      def self.enabled_for?(account)
        BOOLEAN.cast(account.internal_attributes[INTERNAL_ATTR_KEY]) || false
      end

      def self.global_enabled?
        BOOLEAN.cast(ENV.fetch('AUTONOMIA_AGENTS_GLOBAL', false))
      end

      # Conta tem credencial de IA utilizável (chave do Kanban AI da conta OU chave de sistema)?
      # Best-effort: qualquer erro de resolução -> false (NÃO libera o recurso por engano).
      def self.ai_credential_available?(account)
        ::Crm::Ai::CredentialResolver.new(account: account).configured?
      rescue StandardError
        false
      end

      # Helpers de console p/ LIGAR/DESLIGAR o recurso numa conta específica.
      def self.enable_for!(account)
        account.internal_attributes[INTERNAL_ATTR_KEY] = true
        account.save!
        account
      end

      def self.disable_for!(account)
        account.internal_attributes[INTERNAL_ATTR_KEY] = false
        account.save!
        account
      end
    end
  end
end
