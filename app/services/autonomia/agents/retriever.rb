class Autonomia::Agents::Retriever
  # #14 — Erro DISTINTO de infra/banco no retrieval (pgvector/conexão/statement inválido). Difere de
  # "sem KB" (que é uma lista []): sinaliza ao Answerer que a RECUPERAÇÃO FALHOU (não que não há
  # conhecimento) → handoff seguro no fluxo gateado (Guia/copiloto), em vez de responder ungrounded.
  class RetrievalError < StandardError; end

  def initialize(agent:)
    @agent = agent
  end

  # query:String, top_k:Integer -> Array<Autonomia::Agents::KnowledgeEntry>
  # Escopo SEMPRE por agente (isolamento de conta/agente). Cada record expõe
  # .neighbor_distance. Retorna [] se o embedding vier vazio.
  def retrieve(query, top_k: Autonomia::Agents::Config::RETRIEVER_TOP_K)
    # C1 (custo) — teto da query ANTES do embedding: sem isso, uma mensagem colada gigante viraria um
    # embedding igualmente gigante (custo por token / limite do provider) mesmo com o PromptBuilder
    # capando depois. Defesa CENTRAL aqui (único funil): cobre Answerer (Testar/copiloto/operate),
    # Guide::Chat e context_for sem repetir truncamento em cada caller. O mesmo texto truncado segue
    # para o reforço lexical (merge_lexical), mantendo vetorial e lexical coerentes entre si.
    # Resolve o modelo UMA vez por retrieve: a query é embedada e comparada SEMPRE contra a coluna do
    # MESMO modelo (coerência dimensão↔coluna), mesmo se a config global virar no meio da operação.
    model = Autonomia::Agents::Config.active_embedding_model
    query = Autonomia::Agents::Config.truncate_text(query, Autonomia::Agents::Config::MAX_QUERY_CHARS)
    vector = embedding_service(model).embed(query)
    return [] if vector.blank?

    # folga (top_k*4) p/ rerank, dedup por fonte e merge lexical
    rank_candidates(candidate_rows(vector, top_k, model), query, top_k)
  rescue ActiveRecord::ActiveRecordError => e
    # #14 — FALHA DE INFRA/BANCO (pgvector fora, conexão perdida, statement inválido): NÃO mascarar
    # como "sem KB" (que faria o agente responder ungrounded ou dizer "não tenho material"). Levanta
    # erro DISTINTO → o Answerer faz handoff seguro no caminho gateado (Guia/copiloto); no operate
    # instrução-dirigido, degrada para [] (não silenciar o bot por uma falha transitória de banco).
    Rails.logger.error("[autonomia][retriever] db_failure agent=#{@agent.id} #{e.class}")
    raise RetrievalError, 'retrieval_unavailable'
  rescue Autonomia::Agents::EmbeddingService::EmbeddingError => e
    # RESILIÊNCIA (Testar/operate): erro de embedding/credencial/provider/timeout NÃO pode quebrar o
    # fluxo. Degrada para [] → o Answerer responde pela personalidade/instrução ou faz handoff seguro.
    Rails.logger.warn("[autonomia][retriever] degraded agent=#{@agent.id} #{e.class}")
    []
  rescue StandardError => e
    # NÃO mascarar BUG de programação como "sem KB": um typo/const errado (achado no B1: NameError no
    # SQL halfvec) virava [] silencioso e resposta ungrounded. Erro de programação SOBE (visível em
    # teste/monitoramento p/ corrigir); só erro operacional inesperado degrada para [] (resiliência).
    raise if e.is_a?(NameError) || e.is_a?(ArgumentError) || e.is_a?(TypeError)

    Rails.logger.warn("[autonomia][retriever] degraded agent=#{@agent.id} #{e.class}")
    []
  end

  # Conveniência p/ Fase B: trechos de texto já formatados.
  def context_for(query, top_k: Autonomia::Agents::Config::RETRIEVER_TOP_K)
    retrieve(query, top_k: top_k).map(&:content)
  end

  private

  # Pipeline de ranqueamento sobre os candidatos vetoriais (top_k*4): teto frouxo -> rerank por
  # metadata -> dedup por fonte -> reforço lexical. Extraído do retrieve p/ manter cada método focado.
  def rank_candidates(rows, query, top_k)
    # P1.1b — TOP-K com piso FROUXO de segurança (NÃO mais cutoff absoluto 0.45 que zerava tudo).
    # Mantém só o que está abaixo do teto de lixo; entre 0.45 e o teto o trecho ENTRA (recall) e a
    # ancoragem de confiança no Answerer o rebaixa se for fraco. Acima do teto = genuíno fora-de-
    # escopo → descartado, preservando o isolamento (handoff correto p/ "cardápio de pizza" num salão).
    kept = rows.select { |e| e.neighbor_distance.to_f <= Autonomia::Agents::Config::RETRIEVAL_HARD_CEILING }
    # B3 — rerank ADITIVO por metadata (nunca filtro que zera — lição P1.1b): reordena os candidatos já
    # dentro do teto, promovendo o chunk cujo heading/keywords/topics casam com os termos da query.
    kept = rerank_by_metadata(kept, query)
    result = dedup_by_source(kept).first(top_k)
    # P1.1c — complemento lexical p/ termos exatos que o embedding raso perde (SKU, "domingo",
    # "dermato"): só quando o vetorial veio fraco/incompleto. Roda sobre o MESMO escopo filtrado.
    reinforce_lexical?(result) ? merge_lexical(result, query, top_k) : result
  end

  # B1 — candidatos (top_k*4) pela COLUNA do modelo ativo. 3-small: caminho da gem `neighbor` sobre
  # :embedding (INALTERADO — sem regressão p/ a base atual e o Captain). 3-large: NN por SQL cru sobre
  # :embedding_large (halfvec 3072), pois neighbor 0.2.3 não conhece halfvec. Ambos expõem
  # `neighbor_distance` na MESMA escala (distância de cosseno) — os patamares 0.75/0.45 valem igual.
  def candidate_rows(vector, top_k, model)
    scope = @agent.knowledge_entries.ready.where.not(source_id: rejected_source_ids)
    if Autonomia::Agents::Config.embedding_large?(model)
      nearest_by_halfvec(scope, vector, top_k)
    else
      scope.nearest_neighbors(:embedding, vector, distance: 'cosine').limit(top_k * 4)
    end
  end

  # NN sobre halfvec: operador `<=>` = distância de cosseno (mesma escala do neighbor). Só linhas já
  # backfilladas (embedding_large IS NOT NULL). Literal pgvector "[...]" + cast ::halfvec, sanitizado.
  def nearest_by_halfvec(scope, vector, top_k)
    literal = "[#{vector.join(',')}]"
    distance = Autonomia::Agents::KnowledgeEntry
               .sanitize_sql_array(['(embedding_large <=> ?::halfvec)', literal])
    scope.where.not(embedding_large: nil)
         .select(Arel.sql("autonomia_agent_knowledge.*, #{distance} AS neighbor_distance"))
         .order(Arel.sql("#{distance} ASC"))
         .limit(top_k * 4)
  end

  # Revisor v2 (§2.6): exclui do retrieval o conhecimento de fontes REPROVADAS pela IA Revisora
  # (needs_resend) ou não-avaliáveis sem IA (needs_review). Fontes 'accepted' E ainda-não-revisadas
  # (review_status nil — legado/sources pré-revisor) SEGUEM incluídas → sem regressão para
  # conhecimento já no ar. Lista vazia ⇒ where.not(source_id: []) é no-op (não filtra nada).
  #
  # P3.2 — GATE DE ESCOPO NO RETRIEVAL (interação com P1.1): com o cutoff relaxado de 0.45 → 0.75
  # (RETRIEVAL_HARD_CEILING), um KB de OUTRO negócio aprovado por nota técnica (denso o suficiente p/
  # casar < 0.75) voltaria a ser recuperável e — se casar forte (≤ STRONG_MATCH) — sustentaria
  # confiança alta no Answerer, vazando contexto errado (Protege+ num agente Lar Ideal, S12). Excluímos
  # também as fontes de OUTRO NEGÓCIO (flag "Fora do negócio:" do Revisor, §6.6) ANTES do retrieval,
  # fechando o ponto que o cutoff barrava por acidente. NÃO confundir com "Cobertura:" (desencaixe de
  # TIPO, mesmo negócio) que NÃO isola — ver scope_mismatched_source_ids. Salvaguarda anti-regressão
  # idêntica à do topic_map: só exclui mismatched quando RESTA conhecimento em escopo — nunca esvazia tudo.
  def rejected_source_ids
    @agent.sources.where(review_status: %w[needs_resend needs_review]).pluck(:id) +
      scope_mismatched_source_ids
  end

  # Fontes ACEITAS porém de OUTRO NEGÓCIO: o Revisor marca isolamento de negócio com a frase "Fora do
  # negócio: …" no início de uma sentença do review_summary (Reviewer::OUT_OF_BUSINESS_MARKER, §6.6).
  # ATENÇÃO — correção do falso-positivo S15: ANTES gateávamos por SCOPE_MISMATCH_MARKER ("Cobertura:"),
  # que o Revisor emite por mero desencaixe de TIPO (catálogo de produtos num agente de atendimento = MESMO
  # negócio). Isso excluía do retrieval KB legítimo adicionado depois de finalizar ("incluir mais KB"). O
  # isolamento real (leak S12: seguradora num agente de imobiliária) usa o marcador de NEGÓCIO, estrito.
  # Devolve [] quando TODAS as aceitas estão flagueadas (ou nenhuma) — não regredir um agente cujo KB
  # inteiro veio marcado (preserva o recall; mesma salvaguarda do in_scope_sources do agregado).
  def scope_mismatched_source_ids
    accepted = @agent.accepted_sources.to_a
    mismatched = accepted.select { |s| Autonomia::Agents::Knowledge::Reviewer.out_of_business?(s.review_summary) }
    return [] if mismatched.empty? || mismatched.size == accepted.size

    mismatched.map(&:id)
  end

  # Reforço lexical útil só quando o vetorial trouxe ALGO mas veio incompleto (< top_k) OU sem
  # nenhum match forte (menor distância > patamar de match). Se o vetorial veio VAZIO (todos os
  # vizinhos acima do teto frouxo = genuíno fora-de-escopo), NÃO cai no lexical — senão reabriria
  # contaminação para queries fora do escopo do agente (preserva o handoff correto).
  def reinforce_lexical?(result)
    return false if result.empty?

    strong = result.any? { |e| e.neighbor_distance.to_f <= Autonomia::Agents::Config::RETRIEVAL_STRONG_MATCH }
    result.size < Autonomia::Agents::Config::RETRIEVER_TOP_K || !strong
  end

  # ILIKE sobre o `content` cru das entries do agente (mesmo escopo filtrado do vetorial), casando os
  # termos de conteúdo da query (>= 4 chars, sem stopwords pt). Merge dedup por id, vetorial primeiro.
  def merge_lexical(vector_hits, query, top_k)
    terms = lexical_terms(query)
    return vector_hits if terms.empty?

    seen = vector_hits.map(&:id)
    clause = terms.map { 'content ILIKE ?' }.join(' OR ')
    lex = @agent.knowledge_entries.ready
                .where.not(source_id: rejected_source_ids)
                .where(clause, *terms.map { |t| "%#{t}%" })
                .limit(top_k)
                .reject { |e| seen.include?(e.id) }
    # Hit lexical não passou pelo nearest_neighbors → o atributo SQL `neighbor_distance` (alias do
    # SELECT) não existe nessas instâncias. Define um reader singleton com o patamar de match forte
    # p/ uniformizar com os hits vetoriais (P2.1 lê .neighbor_distance p/ ancorar confiança):
    # casamento de termo exato é sinal positivo legítimo, mas NÃO um vetorial perfeito (0.0).
    lex.each { |e| e.define_singleton_method(:neighbor_distance) { Autonomia::Agents::Config::RETRIEVAL_STRONG_MATCH } }
    (vector_hits + lex).first(top_k)
  end

  STOPWORDS_PT = %w[para com como qual quais quanto quantos onde quando tem teem voce voces vocês quero
                    sobre nosso nossa email mais menos isso esse essa aqui esta este pelo pela dos das].freeze

  def lexical_terms(query)
    query.to_s.downcase.scan(/[\p{Alnum}]{4,}/).reject { |w| STOPWORDS_PT.include?(w) }.uniq.first(6)
  end

  # B3 — bônus por termo casado nos metadados do chunk, e teto do bônus. Pequenos de propósito:
  # o rerank AJUDA a ordenar entre candidatos já válidos (< teto), não substitui a similaridade
  # vetorial nem reabre fora-de-escopo (o teto 0.75 já filtrou). Distância menor = melhor; o bônus é
  # SUBTRAÍDO da distância só para ORDENAR (neighbor_distance permanece intacto p/ a ancoragem).
  METADATA_MATCH_BONUS = 0.03
  METADATA_MAX_BONUS = 0.12

  # Reordena por (distância - bônus_de_metadata), sem mutar neighbor_distance. NO-OP estrito quando não
  # há bônus (todos 0) → devolve a ordem vetorial original intacta (o dedup_by_source depende dela).
  # Índice original como tie-breaker → estável (não bagunça empates de distância que o dedup consome).
  def rerank_by_metadata(entries, query)
    terms = lexical_terms(query)
    return entries if terms.empty? || entries.size < 2

    rerank_by_bonus(entries, terms) || entries
  end

  # nil quando NENHUM candidato ganhou bônus (no-op → o caller preserva a ordem vetorial). Índice
  # original como tie-breaker → estável (não bagunça empates de distância que o dedup_by_source consome).
  def rerank_by_bonus(entries, terms)
    scored = entries.each_with_index.map { |entry, index| [entry, metadata_bonus(entry, terms), index] }
    return nil if scored.all? { |_, bonus, _| bonus.zero? }

    scored.sort_by { |entry, bonus, index| [entry.neighbor_distance.to_f - bonus, index] }.map(&:first)
  end

  def metadata_bonus(entry, terms)
    haystack = metadata_haystack(entry.metadata)
    return 0.0 if haystack.blank?

    hits = terms.count { |term| haystack.include?(term) }
    [hits * METADATA_MATCH_BONUS, METADATA_MAX_BONUS].min
  end

  # Junta os campos textuais do metadata (chaves string do jsonb) num blob minúsculo p/ casar termos:
  # heading, material_type, keywords e o bloco doc (topics/entities/style) do classificador (B2). Nil-safe
  # p/ chunks antigos sem metadata rica (bônus 0 → sem efeito, sem regressão).
  def metadata_haystack(metadata)
    # indifferent access: jsonb round-trip vem com chaves string, mas objetos em memória (specs, chunker)
    # usam símbolo — casa os dois sem depender do round-trip. Nil-safe p/ chunks sem metadata rica.
    meta = (metadata || {}).with_indifferent_access
    doc = meta[:doc] || {}
    parts = [meta[:section_heading], meta[:material_type], meta[:keywords], doc[:topics], doc[:entities]]
    parts.flatten.compact.join(' ').downcase
  end

  # Dedup por fonte (P2): 1 melhor trecho por fonte primeiro (já ordenados por distância pelo
  # nearest_neighbors), depois completa com os demais até top_k. Reduz a contaminação de um tema
  # quando uma única fonte domina os vizinhos, dando espaço a outras fontes relevantes.
  def dedup_by_source(entries)
    primary = entries.group_by(&:source_id).values.map(&:first)
    primary + (entries - primary)
  end

  # Memoizado POR MODELO: se o modelo resolvido no retrieve mudar entre chamadas, não reusa um serviço
  # preso ao modelo antigo (coerência query↔coluna). `model` vem resolvido do retrieve (1x por operação).
  def embedding_service(model = nil)
    @embedding_service ||= {}
    @embedding_service[model] ||= Autonomia::Agents::EmbeddingService.new(account: @agent.account, model: model)
  end
end
