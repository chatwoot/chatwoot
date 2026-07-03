module Autonomia
  module Agents
    # Motor de resposta SÍNCRONO (modo Testar): Retriever -> PromptBuilder -> ResponsesClient#create
    # -> parse -> PORTÃO DE CONFIANÇA. O AGENTE decide o handoff (via instruction/handoff_rule,
    # capturado em should_handoff/handoff_reason); o Answerer apenas CAPTURA essa decisão + a
    # confiança e aplica o portão. NÃO executa reassignment (Fase D). Em sandbox não há conversa real.
    #
    # SEGURANÇA: o prompt montado (scaffold + instruction) vai direto ao ResponsesClient via
    # `instructions` e é descartado. NUNCA entra no AnswerResult nem em log.
    class Answerer
      # Recusa "não tenho/não encontrei informação" (pt/en). Determinístico, p/ rebaixar confiança (P2.1).
      # NÃO casa recusa de injeção/fora-de-escopo (texto próprio) nem negação factual firme ("não, a X não faz").
      NO_INFO_PATTERNS = [
        /n[ãa]o\s+(?:tenho|possuo|encontr|localiz|disponho)/i,
        /(?:sem|n[ãa]o\s+h[áa])\s+informa[çc]/i,
        /informa[çc][ãa]o\s+(?:suficiente|dispon[íi]vel)/i,
        /(?:don'?t|do not)\s+have\s+(?:enough\s+)?info/i,
        /(?:no|not enough)\s+information/i
      ].freeze

      # Frases que AFIRMAM uma fonte de conhecimento ("nosso material/catálogo/base"). Removidas quando não
      # houve fonte real nem âncora na instrução (P2.2b) — evita citar material inexistente (S08).
      GROUNDING_PHRASE_PATTERNS = [
        /\bcom\s+base\s+(?:no|nos|na|nas)\s+(?:nosso|nossa|nossos|nossas)\s+[\wà-ú]+(?:\s+de\s+atendimento)?[,.:]?\s*/i,
        /\b(?:no|em)\s+(?:nosso|nossa)\s+(?:material|cat[áa]logo|base|sistema)[,.:]?\s*/i,
        /\baccording\s+to\s+our\s+[\w]+[,.:]?\s*/i
      ].freeze

      # Especificidade fabricável numa reply (preço, horário, passo numerado, SKU). Aciona o gate NOKB (P2.2a).
      SPECIFICS_PATTERNS = [
        /R\$\s?\d/,                              # preço
        /\b\d{1,2}\s?[:h]\d{2}\b/,               # horário
        /\b(?:passo|etapa|step)\s*\d/i,          # passo numerado
        /^\s*\d+[.)]\s+\S/,                      # lista numerada (início de linha)
        /\b[A-Z]{2,}-\d{2,}\b/                   # SKU/código tipo ST-045
      ].freeze

      def initialize(agent:, query:, history: [], images: [], allow_web_search: true, trust_instruction: false,
                     audience: :customer)
        @agent = agent
        @query = query.to_s
        @history = history
        @images = Array(images)
        # AUDIÊNCIA (Onda 1 v2): :customer (operate/cliente) | :attendant (copiloto) | :system (Guia).
        # A superfície decide; repassado ao PromptBuilder (que força :system p/ agente com system_key).
        @audience = audience
        # Guia da Plataforma desliga o web search: deve responder SÓ da base (KB), nunca de fonte
        # externa. Default true preserva o comportamento dos demais agentes.
        @allow_web_search = allow_web_search
        # MODO INSTRUÇÃO-DIRIGIDO (operate/atendimento ao cliente): devolve a resposta do modelo COMO
        # VEIO, sem portão de confiança / handoff de sistema / sanitização / anti-improviso — a
        # INSTRUÇÃO manda (decisão do PO). Default false preserva o Guia e o copiloto, que mantêm o portão.
        @trust_instruction = trust_instruction
      end

      # -> Autonomia::Agents::AnswerResult
      def answer
        snippets = retrieve_snippets
        parsed = generate(snippets)
        return trust_instruction_result(parsed, snippets) if @trust_instruction
        return safe_handoff if parsed.nil?

        build_result(parsed, snippets)
      rescue Autonomia::Agents::Retriever::RetrievalError
        # #14 — falha de INFRA no retrieval (banco/pgvector). Só chega aqui no fluxo GATEADO
        # (Guia/copiloto): retrieve_snippets só re-levanta quando NÃO é trust_instruction. Handoff
        # seguro com motivo distinto (não "sem KB" nem resposta ungrounded). Operate degrada p/ [].
        safe_handoff('retrieval_unavailable')
      end

      # Operate: a resposta do modelo passa direto (a instrução decide tudo, inclusive escalar e o sinal
      # de silêncio `conversation_closed_for_now`). NUNCA aplica portão/handoff de sistema. Falha de IA
      # (parsed nil) -> reply nil -> o Responder fica em SILÊNCIO (sem fallback de sistema).
      def trust_instruction_result(parsed, snippets)
        return AnswerResult.new(reply: nil, confidence: 0.0, handoff: { should: false, reason: nil },
                                used_knowledge: [], answered_from_knowledge: false, raw_reply: nil,
                                error: 'ai_unavailable') if parsed.nil?

        AnswerResult.new(
          reply: parsed['reply'], confidence: clamp(parsed['confidence'].to_f),
          handoff: { should: false, reason: nil },
          used_knowledge: used_knowledge(parsed['used_snippet_ids'], snippets, parsed),
          answered_from_knowledge: parsed['answered_from_knowledge'] == true,
          raw_reply: parsed['reply']
        )
      end

      private

      # Cinto e suspensório: o Retriever já degrada para [] em erro de embedding/provider
      # (resiliência do Testar). Este rescue defensivo garante que NENHUMA exceção inesperada
      # de retrieval suba — sem KB ou com IA de embedding fora, o Testar nunca dá 500: o
      # generate segue com snippets=[] e o agente responde pela instrução ou pede handoff.
      def retrieve_snippets
        # C3 (custo): agente declarado SEM base (`with_knowledge=false` explícito) pula o retrieval
        # inteiro — não paga embedding por mensagem nem usa entries residuais de uma base antiga.
        # Default histórico preservado: chave ausente = COM base (retrieval roda normalmente).
        return [] if @agent.knowledge_disabled?

        Retriever.new(agent: @agent).retrieve(@query, top_k: Config::ANSWER_TOP_K)
      rescue Autonomia::Agents::Retriever::RetrievalError
        # #14 — falha de INFRA. Operate (instrução-dirigido): NÃO silencia o bot — degrada p/ [] e
        # segue pela instrução. Fluxo GATEADO (Guia/copiloto): re-levanta → `answer` faz handoff seguro.
        raise unless @trust_instruction
        []
      rescue StandardError => e
        Rails.logger.warn("[autonomia][answerer] retrieve degraded agent=#{@agent.id} #{e.class}")
        []
      end

      # Roda o LLM (síncrono, schema, gpt-5.4) e devolve o hash parseado, ou nil em qualquer
      # falha de IA (credencial vazia, erro do cliente, timeout, JSON inválido) -> handoff seguro.
      def generate(snippets)
        credential = Crm::Ai::CredentialResolver.new(account: @agent.account).resolve
        return nil if credential.blank?

        pb = PromptBuilder.new(agent: @agent, query: @query, history: @history, snippets: snippets,
                               images: @images, audience: @audience)
        raw = Crm::Ai::ResponsesClient.new(
          credential: credential, feature: 'agente_resposta', account: @agent.account
        ).create(
          model: Config::ANSWERER_MODEL,
          instructions: pb.instructions,
          input: pb.input,
          schema: PromptBuilder::ANSWER_SCHEMA,
          reasoning_effort: Config::ANSWERER_REASONING_EFFORT,
          tools: @allow_web_search ? Crm::Ai::WebSearch.tools : nil
        )
        parsed = JSON.parse(raw[:text])
        parsed.is_a?(Hash) ? parsed : nil # JSON não-objeto (ex.: "[]") -> handoff seguro, nunca 500.
      rescue Crm::Ai::ResponsesClient::Error, JSON::ParserError
        nil # NÃO logar e.message (pode ecoar o prompt). error code curto fica no AnswerResult.
      end

      def build_result(parsed, snippets)
        self_conf = clamp(parsed['confidence'].to_f)
        used = used_knowledge(parsed['used_snippet_ids'], snippets, parsed)
        answered = parsed['answered_from_knowledge'] == true
        reply_present = parsed['reply'].to_s.strip.present?

        # Coerência (P1): reply nil/handoff NÃO pode ser rotulado como vindo do conhecimento.
        # Corrige o bug de rotulagem (T01/T06: reply=null+handoff vinham com answered=true, conf 0,95).
        # Chave SÓ no reply_present (a recusa/handoff não tem reply utilizável). NÃO acoplar a
        # used.any?: um grounded legítimo pode ter answered_from_knowledge=true e mesmo assim
        # used_snippet_ids vazio/incompleto (o modelo às vezes responde certo e esquece de ecoar os
        # ids); rebaixar esse caso para false zerava o rótulo de grounding correto e a citação de fonte.
        answered = false unless reply_present

        # P2.2(c): SÓ quando o agente NÃO tem KB, exigir fonte real (snippet) ou âncora na instrução
        # para sustentar answered. Em agente COM KB mantém o cuidado T01/T06 (não acoplar a used).
        grounded_by_instruction = answered && reply_present && !refusal_no_info?(parsed)
        answered = false if !agent_has_kb? && used.empty? && !grounded_by_instruction

        confidence = anchored_confidence(self_conf, parsed, snippets, used, reply_present, grounded_by_instruction)
        # P2.2(b): sem fonte real e sem âncora, remover a frase de grounding ("nosso material") da reply.
        reply = sanitize_grounding_phrase(parsed['reply'], used, grounded_by_instruction)

        if handoff?(parsed, confidence, answered, snippets, reply_present, grounded_by_instruction)
          handoff_result(parsed, confidence, used)
        else
          AnswerResult.new(
            reply: reply, confidence: confidence,
            handoff: { should: false, reason: nil },
            used_knowledge: used, answered_from_knowledge: answered,
            raw_reply: parsed['reply']
          )
        end
      end

      # P2.1 — CONFIANÇA ANCORADA no sinal real de retrieval, combinada com o self-report (nunca o INFLA: usa
      # min). `neighbor_distance` (gem neighbor) vem em cada snippet recuperado; aqui derivamos a menor distância
      # dos snippets que o modelo declarou usar (fallback: todos os recuperados). NÃO altera o teto do portão,
      # apenas REBAIXA confiança quando nada relevante foi recuperado e a resposta não veio da instrução.
      def anchored_confidence(self_conf, parsed, snippets, used, reply_present, grounded_by_instruction)
        return self_conf unless reply_present # recusa/handoff: deixa o portão agir com o self-report

        # Recusa em banda (injeção/fora-de-escopo): reply presente, mas o modelo NÃO afirma ter respondido do
        # conhecimento (answered_from_knowledge=false) e não é "não achei". NÃO rebaixar — preservaria o portão de
        # injeção (should_handoff=false + conf alta) intacto; rebaixar mandaria a recusa de injeção a handoff.
        claims_knowledge = parsed['answered_from_knowledge'] == true
        if used.empty? && refusal_no_info?(parsed)
          [self_conf, 0.29].min # "não achei" determinístico: nunca > 0.3 (resolve S01 frete 0.95)
        elsif !claims_knowledge
          self_conf # recusa em banda (injeção/fora-de-escopo): respeita should_handoff + self-report
        elsif retrieval_strong?(snippets, used) || grounded_by_instruction
          self_conf # ancorado em chunk forte ou em fato da instrução: respeita o self-report
        else
          [self_conf, 0.50].min # AFIRMOU conhecimento de chunk fraco/sem âncora: rebaixa p/ < threshold
        end
      end

      # true se algum snippet usado (ou, se nenhum ecoado, recuperado) está dentro do match FORTE.
      def retrieval_strong?(snippets, used)
        pool = used.any? ? snippets.select { |s| used.any? { |u| u[:id] == s.id } } : snippets
        distances = pool.filter_map { |s| s.neighbor_distance&.to_f }
        return false if distances.empty?

        distances.min <= strong_match_distance
      end

      # Limiar de match FORTE p/ ancoragem. Usa RETRIEVAL_STRONG_MATCH quando a área de RETRIEVAL o define;
      # caia para SIMILARITY_MAX_DISTANCE p/ compilar standalone (mesmo valor, 0.45).
      def strong_match_distance
        if Config.const_defined?(:RETRIEVAL_STRONG_MATCH)
          Config::RETRIEVAL_STRONG_MATCH
        else
          Config::SIMILARITY_MAX_DISTANCE
        end
      end

      def agent_has_kb?
        @agent.accepted_sources.exists? || @agent.knowledge_confidence.to_f.positive?
      end

      # Reply é uma recusa de "não tenho/não encontrei informação" (heurística determinística leve,
      # idioma pt/en). NÃO casa recusa de injeção/fora-de-escopo (essas têm texto próprio).
      def refusal_no_info?(parsed)
        text = parsed['reply'].to_s.downcase
        NO_INFO_PATTERNS.any? { |re| text.match?(re) }
      end

      # P2.2(b): se a resposta não veio de fonte real (snippet) nem de âncora na instrução, tira a frase de
      # grounding ("com base no nosso material/catálogo/base") — ela afirma uma fonte inexistente (S08).
      def sanitize_grounding_phrase(reply, used, grounded_by_instruction)
        text = reply.to_s
        return reply if text.blank? || used.any? || grounded_by_instruction

        GROUNDING_PHRASE_PATTERNS.reduce(text) { |acc, re| acc.gsub(re, '') }
                                 .gsub(/\s{2,}/, ' ').strip.presence || reply
      end

      # PORTÃO DE CONFIANÇA. handoff se: o agente pediu (should_handoff=true); OU confiança < threshold;
      # OU não conseguiu responder de fato (sem reply utilizável) e não havia conhecimento relevante.
      #
      # SEGURANÇA (P1) — recusa de INJEÇÃO não pode virar handoff: numa injeção o modelo produz uma
      # recusa curta (reply PRESENTE) com should_handoff=false e answered=false. O 3º ramo antigo
      # `(!answered && snippets.empty?)` ESCALAVA essa recusa quando o agente não tinha KB recuperada
      # (snippets vazios) — encaminhava o ataque ao humano, exatamente o que a §"Injeção" proíbe.
      # Agora o 3º ramo só dispara quando NÃO há reply utilizável (o modelo de fato não respondeu),
      # respeitando o should_handoff=false explícito de uma recusa em banda (injeção/fora de escopo).
      #
      # P2.2(a) — GATE DETERMINÍSTICO ANTI-IMPROVISO (4º ramo), condicional a agente SEM KB: se não há snippet
      # nem fato-âncora na instrução e a reply traz ESPECIFICIDADE fabricável (passo numerado, preço, horário,
      # SKU), força handoff em vez de deixar o LLM improvisar (S06). NÃO regride injeção: a recusa de injeção
      # é curta e SEM especificidade -> asks_for_specifics? falso -> não escala.
      def handoff?(parsed, confidence, answered, snippets, reply_present, grounded_by_instruction = false)
        parsed['should_handoff'] == true ||
          confidence < threshold ||
          (!reply_present && !answered && snippets.empty?) ||
          improvised_specifics_without_kb?(snippets, reply_present, grounded_by_instruction, parsed)
      end

      def improvised_specifics_without_kb?(snippets, reply_present, grounded_by_instruction, parsed)
        reply_present && snippets.empty? && !grounded_by_instruction &&
          !agent_has_kb? && asks_for_specifics?(parsed)
      end

      # Heurística leve: a reply contém especificidade fabricável (preço, horário, passo numerado, SKU)?
      def asks_for_specifics?(parsed)
        text = parsed['reply'].to_s
        SPECIFICS_PATTERNS.any? { |re| text.match?(re) }
      end

      # Handoff ⇒ NÃO respondeu do conhecimento (answered_from_knowledge=false SEMPRE).
      # Encaminhou ao humano, logo nenhuma resposta foi entregue a partir da base.
      def handoff_result(parsed, confidence, used)
        AnswerResult.new(
          reply: @agent.fallback_message.presence,
          confidence: confidence,
          handoff: { should: true, reason: parsed['handoff_reason'].presence || 'low_confidence' },
          used_knowledge: used, answered_from_knowledge: false,
          raw_reply: parsed['reply'] # melhor esforço preservado p/ o Copilot
        )
      end

      # used_snippet_ids ∩ ids dos snippets -> { id, content, source: label } (conteúdo do usuário, ok expor).
      # P3.1: quando a mensagem traz imagem e o modelo respondeu (reply presente), registrar a imagem lida
      # inline como FONTE em `used` (auditabilidade do multimodal — S14). Não há snippet.id para a imagem.
      def used_knowledge(used_ids, snippets, parsed = nil)
        ids = Array(used_ids).map(&:to_i).to_set
        used = snippets.select { |s| ids.include?(s.id) }.map do |s|
          { id: s.id, content: s.content, source: source_label(s) }
        end
        if @images.any? && parsed && parsed['reply'].to_s.strip.present?
          used << { id: nil, content: '<imagem enviada>', source: 'imagem da mensagem' }
        end
        used
      end

      def source_label(snippet)
        snippet.source&.reference.presence ||
          snippet.source&.external_link.presence ||
          "trecho ##{snippet.id}"
      end

      def threshold
        raw = @agent.confidence_threshold.presence || Config::DEFAULT_CONFIDENCE_THRESHOLD
        value = begin
          Float(raw) # parse estrito: "abc" não vira 0.0 e desliga o portão; cai no DEFAULT.
        rescue ArgumentError, TypeError
          Config::DEFAULT_CONFIDENCE_THRESHOLD
        end
        clamp(value)
      end

      def clamp(value)
        value.to_f.clamp(0.0, 1.0)
      end

      # Handoff seguro quando a IA está indisponível OU o retrieval falhou por infra (#14): nunca
      # crash, nunca eco do prompt. `reason` vira o código curto do handoff/erro ('ai_unavailable'
      # default; 'retrieval_unavailable' quando o banco/pgvector falhou).
      def safe_handoff(reason = 'ai_unavailable')
        AnswerResult.new(
          reply: @agent.fallback_message.presence,
          confidence: 0.0,
          handoff: { should: true, reason: reason },
          used_knowledge: [], answered_from_knowledge: false,
          raw_reply: nil, error: reason
        )
      end
    end
  end
end
