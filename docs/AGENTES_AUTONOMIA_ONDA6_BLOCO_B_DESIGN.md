# Onda 6 — Bloco B — Design detalhado (qualidade de criação de chunk + embedding + extração)

> Status: **DESENHO — aguardando 🟢 do Rodrigo antes de construir.**
> Programa de reprocessamento de dado de PRODUÇÃO (re-embed + re-chunk de todo o acervo de KB).
> Filosofia fixada (Rodrigo, 2026-07-03): **qualidade sobre custo** — quem paga é o cliente e ele
> quer um agente que responda CORRETAMENTE. Portão de confiança 0.55 **não** é afrouxado.

Bloco A (config-only) já em produção (PR #108). Bloco B é o coração da Onda 6: elevar a
**inteligência de criação do chunk** (tamanho variável por tipo/estilo + metadados ricos por chunk),
subir o modelo de embedding, e fechar as lacunas de extração — depois reprocessar a base com validação.

---

## 0. Estado real do pipeline (verificado no código, 2026-07-03)

| Camada | Arquivo | Estado atual |
|---|---|---|
| Extração | `app/services/autonomia/agents/knowledge/processors/{pdf,docx,xlsx,json,text,link}.rb`, `base.rb`, `dispatcher.rb` | 1 processador por tipo; PDF escaneado (sem camada de texto) → extração vazia → fonte `failed` |
| Chunk | `knowledge/chunker.rb` (199 ln, P1.1a/b) | segmentação estrutural + herança de heading; `CHUNK_MAX=600` **fixo p/ todo tipo** |
| Embedding | `embedding_service.rb` | `text-embedding-3-small` (1536 dims); `embed_batch` = `map` ingênuo (1 request HTTP por chunk) |
| Storage | tabela `autonomia_agent_knowledge` | `embedding vector(1536)` índice **ivfflat** cosine; `metadata jsonb` gravado = só `{source_type}` |
| Retrieval | `retriever.rb` | `nearest_neighbors` cosine, `limit top_k*4`, dedup por fonte, reforço lexical ILIKE. **Não usa `metadata`** |
| Ingestão | `knowledge/ingestor.rb` | extract → chunk → embed_batch → `replace_knowledge` (transação, token-guard, data-loss guard) |

**Restrição dura descoberta:** pgvector `ivfflat`/`hnsw` indexam **no máximo 2000 dims**. O
`text-embedding-3-large` padrão tem **3072 dims → não indexável** (viraria seq scan em toda query).
Portanto o upgrade de modelo **tem** de usar `dimensions: 1536` (Matryoshka da OpenAI) p/ manter o
índice e o `vector(1536)` atual. Isso já resolve a decisão de dims (ver B1).

---

## B1 — Upgrade de embedding: `3-small` → `3-large @ 3072 dims` (DECISÃO RODRIGO: 3072 full)

**O quê:** trocar o modelo p/ `text-embedding-3-large` na dimensionalidade CHEIA (3072) — máxima
qualidade semântica. Escolha do Rodrigo (qualidade sobre custo/latência).

**⚠️ PRÉ-REQUISITO DURO a verificar ANTES de construir (não inventar):** 3072 dims **excede o teto
2000** dos índices `ivfflat`/`hnsw` sobre `vector`. O caminho raiz-limpo p/ manter índice em 3072 é
`halfvec(3072)` (16-bit) + índice **hnsw** (halfvec indexa até 4000 dims), disponível na **extensão
pgvector ≥ 0.7.0**. Ação obrigatória no início do B1:
```sql
SELECT extversion FROM pg_extension WHERE extname='vector';  -- read-only, seguro
```
- **Se ≥ 0.7.0:** coluna vira `halfvec(3072)` + índice hnsw cosine. 3072 indexado, retrieval rápido.
- **Se < 0.7.0:** duas saídas — (a) fazer upgrade da extensão pgvector no banco de prod (mudança de
  infra → 🔴 própria, avaliar cross-project), ou (b) cair p/ `3-large @ 1536` (mantém ivfflat atual).
  **Trazer ao Rodrigo qual saída** — não decidir sozinho.

**Como (após pré-requisito):**
- migração: `embedding vector(1536)` → `halfvec(3072)` (nova coluna/índice; backfill preenche).
- `EmbeddingService#embed`: `3-large` sem `dimensions` (padrão 3072); cast p/ halfvec na escrita.
- Ligar via `InstallationConfig CAPTAIN_EMBEDDING_MODEL=text-embedding-3-large` (hook já existe).
  `DEFAULT_EMBEDDING_MODEL` em `lib/llm_constants.rb` fica `3-small` como fallback.
- **Coerência query↔base:** retriever usa o MESMO `EmbeddingService` → query e base no mesmo modelo,
  desde que a base seja **totalmente re-embedada** (misturar 3-small e 3-large é inválido).

**Custo:** 3-large ≈ 6,5× o preço/token do 3-small; 3072 dobra bytes/vetor vs 1536 (halfvec corta
pela metade o storage do float full). Custo de **ingestão**, não por resposta.

**Bônus barato:** `embed_batch` real (hoje 1 request/chunk) — corta latência/erro de ingestão.

---

## B2 — Chunker adaptativo + metadados ricos (o pedido central do Rodrigo)

Hoje o `CHUNK_MAX=600` é fixo para todo material. O chunker já é estrutural (parágrafo/registro/
heading) e herda título de seção — boa base. Falta **variar por tipo/estilo** e **carimbar metadado
por chunk** p/ achabilidade.

### B2.1 — Perfis de chunk por tipo de material
Introduzir `ChunkProfile` selecionado pelo `source_type` + assinatura do conteúdo:

| Material | Estratégia | Teto |
|---|---|---|
| Tabular (XLSX/JSON registro) | 1 registro = 1 chunk (já parcial) + nome da aba/chave como heading | curto (~300) |
| Prosa/política (PDF/DOCX contínuo) | seção mono-tópico + janela deslizante no corpo longo | maior (~900) |
| FAQ / Q&A | 1 par pergunta+resposta por chunk (detecção de padrão "P:/R:", "?") | médio |
| Lista/procedimento | 1 passo/item por chunk (já parcial via LIST_ITEM) | curto |

Seleção via heurística barata sobre a estrutura já detectada em `Chunker#units` — sem custo LLM.

### B2.2 — Metadados ricos por chunk (jsonb `metadata`)
Enriquecer o `metadata` gravado em `create_entry` (hoje só `source_type`) com:

**Determinístico (custo zero, sempre):**
- `source_type`, `doc_title` (nome/referência da fonte), `section_heading` (o `@heading` que o
  chunker JÁ calcula — hoje entra no texto mas não no metadado), `chunk_index`, `char_span`,
  `material_type` (tabular/prosa/faq/lista, do B2.1), `keywords` (top termos por frequência sem
  stopwords pt — mesma base do `lexical_terms`).

**LLM leve (custo limitado, 1 chamada POR DOCUMENTO — não por chunk):**
- 1 passe de classificação por fonte na ingestão (reusa `Reviewer`/modelo `gpt-5.4` que **já roda**
  no ProcessJob após embed) que devolve: `topics` (taxonomia curta do doc), `entities`
  (produtos/serviços/nomes citados), `doc_style` (formal/coloquial/técnico). Carimbado em todos os
  chunks do doc. Custo = O(documentos), não O(chunks) → limitado.

Racional: metadado rico = mais sinal p/ o retrieval achar o chunk certo (B3), exatamente o que o
Rodrigo pediu ("criar metadados específicos pro material pra ficar mais fácil encontrá-los").

**Schema:** `metadata` já é `jsonb default {}` — **sem migração**. Só passa a ser preenchido.

---

## B3 — Retrieval usando os metadados (híbrido, sem regressão de recall)

**Regra dura (lição P1.1b):** metadado **nunca** vira filtro que zera contexto. Entra como **sinal
de rerank aditivo** sobre o candidato vetorial.

- Manter `nearest_neighbors` + `limit top_k*4` + reforço lexical (intactos).
- Adicionar rerank leve: bônus de score p/ chunk cujo `section_heading`/`keywords`/`topics` casam com
  os termos da query (barato, em Ruby sobre os candidatos já trazidos). Ordena melhor os `top_k*4`
  antes do `first(top_k)`.
- Opcional (fase 2): filtro **suave** por `material_type` só quando a query claramente pede um tipo
  (ex.: "planilha de preços") — sempre com a salvaguarda "nunca esvaziar" já usada em
  `scope_mismatched_source_ids`.

Sem migração; sem tocar o teto 0.75 nem o portão 0.55.

---

## B4 — Fixes de extração (aditivos, seguros)

Auditar e endurecer cada processador (confirmar gaps no build; sinalizados na auditoria):
- **pdf.rb:** fallback OCR quando a extração de texto vier quase-vazia (PDF escaneado) — hoje vira
  `EmptyExtraction`→`failed` silencioso. **DECISÃO: fazer agora** com `tesseract` (dep de sistema na
  imagem custom dos 2 stacks — tratar no Dockerfile, validar build/tamanho; regra 2 cross-project).
- **xlsx.rb:** prefixar nome da aba como heading do bloco (achabilidade + herança de heading).
- **docx.rb:** preservar linhas de tabela (hoje achatadas) como registros tabulares.
- **json.rb:** achatar aninhamento em "caminho: valor" p/ virar registros mono-tópico.

Cada fix é isolado por tipo, testável com fixture, sem tocar chunk/embedding.

---

## Sequência, risco e reprocessamento

**Ordem de construção (PRs pequenos, gate por track igual Onda 5):**
1. **B4 extração** (aditivo, sem reprocessar) → merge/deploy → re-sync das fontes que estavam `failed`.
2. **B2 chunker+metadata** + **B3 rerank** (código; passa a valer p/ ingestões novas).
3. **B1 embedding 3-large@3072** (pré-req halfvec/pgvector≥0.7.0 + migração de coluna/índice + config).
4. **Backfill BIG-BANG** (re-chunk + re-embed de TODA a base de uma vez) — a parte 🔴 de prod-data.

**Backfill SEM regressão — nuance descoberta na construção (2026-07-03):** re-ingestão (p/ ganhar
chunks B2) usa `replace_knowledge` que DELETA+recria os entries da fonte. Se recriar gravando só
`embedding_large` (3-large) enquanto o modelo GLOBAL ainda é 3-small, o retrieval (que lê a coluna
`embedding`) perde essa fonte até o cutover → janela de regressão POR FONTE. Duas saídas limpas:
- **(recomendada) 2 fases:** (1) job "re-embed-only" adiciona `embedding_large` aos entries EXISTENTES
  (embeda o `content` atual com 3-large, `UPDATE ... embedding_large`, sem deletar/re-chunk) → flip
  global p/ 3-large (agora large serve, zero janela) → (2) re-ingestão normal das fontes ao longo do
  tempo pega os chunks/metadata B2 (pós-cutover grava só a coluna ativa, sem risco). Desacopla o
  cutover de embedding (seguro) da melhoria de chunk.
- **(alternativa) dual-write:** re-ingestão grava AMBAS as colunas (embedding 3-small + embedding_large
  3-large) durante a transição → 2× custo de embedding, zero janela, cutover instantâneo. Requer
  Ingestor/EmbeddingService aceitarem override de modelo e escreverem 2 colunas.
Backfill é 🔴 (próprio 🟢 do Rodrigo p/ EXECUTAR) e NÃO bloqueia o merge/deploy do código B1–B4 (com
global ainda 3-small, a coluna halfvec fica dormente e segura; B2/B3/B4 já melhoram ingestões NOVAS).

**Backfill (Vermelha — precisa plano de rollback + validação, regra 3):**
- Job idempotente por fonte reusando `Ingestor` (extract→chunk→embed→replace com token-guard, que já
  existe e é seguro contra race). **Big-bang** (decisão Rodrigo) — todas as contas de uma vez.
- **Rollback pré-aprovado:** o `replace_knowledge` é transacional; regressão → re-embedar com o modelo
  antigo restaura. Guardar contagem de chunks/fonte antes; **abortar** se qualquer fonte cair a zero.
- **Validação pós-backfill:** bateria de probes de recall (as já usadas nos incidentes: "frete
  grátis", "PLUS REASON", SKU, "domingo") comparando hit@k antes/depois. Regressão = investigar.
- **Custo:** Σ chunks × preço 3-large. Estimar (contar chunks totais) e trazer ao Rodrigo antes de disparar.

---

## Decisões (RESOLVIDAS pelo Rodrigo, 2026-07-03)

1. **Dims do 3-large → `3072` FULL.** Qualidade máxima. Requer `halfvec(3072)`+hnsw (pgvector ≥0.7.0)
   — pré-requisito duro verificado no início do B1 (ver B1). Se a extensão for antiga, trazer as duas
   saídas (upgrade da extensão vs cair p/ 1536) ao Rodrigo antes de seguir.
2. **Metadado → HÍBRIDO** (determinístico + 1 classificação LLM por documento). ✅ como no design.
3. **OCR de PDF escaneado → FAZER AGORA (nesta onda).** Adiciona dep de sistema **tesseract** à
   imagem custom dos 2 stacks (Hub2You + Autonomia). Tratar no Dockerfile; validar que não quebra o
   build/tamanho da imagem (regra 2 cross-project — mesma imagem base dos 2 stacks).
4. **Backfill → BIG-BANG** (não ondas). Reprocessa toda a base de uma vez. **Salvaguardas da regra 3
   permanecem obrigatórias** (não são afrouxadas pela escolha de velocidade): backup/contagem de
   chunks antes; abort se qualquer fonte cair a zero; probes de recall pós-backfill; rollback
   pré-aprovado = re-embed com modelo antigo. Estimar custo total (Σ chunks × preço 3-large) e trazer
   antes de disparar.

---

## Checklist de entrega (quando 🟢)
- [ ] B4 PRs por processador + re-sync `failed`
- [ ] B2 chunker adaptativo + metadata (determinístico + LLM/doc)
- [ ] B3 rerank por metadado
- [ ] B1 3-large@1536 + batch real de embedding
- [ ] Job de backfill + plano rollback + probes de validação
- [ ] Codex por track + reviewer + rspec; deploy blue-green 2 stacks; validação pós-deploy
- [ ] Project Autonom.ia Dev atualizado
