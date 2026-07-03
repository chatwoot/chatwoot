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

## B1 — Upgrade de embedding: `3-small` → `3-large @ 1536 dims`

**O quê:** trocar o modelo de embedding mantendo 1536 dims (coluna e índice intactos).

**Como (raiz, sem gambiarra):**
- `EmbeddingService#embed` passa `dimensions: 1536` quando o modelo for `3-large`
  (`context.embed(text, model:, dimensions:)` — RubyLLM/OpenAI aceitam). `3-small` fica sem o param.
- Ligar via `InstallationConfig CAPTAIN_EMBEDDING_MODEL=text-embedding-3-large` (hook já existe;
  não hardcodar). Constante `DEFAULT_EMBEDDING_MODEL` em `lib/llm_constants.rb` permanece `3-small`
  como fallback seguro.
- **Coerência query↔base:** o retriever usa o MESMO `EmbeddingService` (mesma leitura de config),
  então query e base ficam no mesmo modelo automaticamente — desde que a base seja **totalmente
  re-embedada** (misturar vetores 3-small e 3-large no mesmo espaço é inválido).

**Por que não 3072 dims:** perderia o índice ivfflat → latência de retrieval explode. 1536-reduzido
do 3-large ainda supera o 3-small em qualidade (benchmark OpenAI MTEB), sem regressão de índice.

**Custo:** 3-large ≈ 6,5× o preço/token do 3-small no embedding. É custo de **ingestão** (uma vez por
documento + re-embed pontual), não por resposta. Alinhado a "qualidade sobre custo".

**Bônus barato:** trocar `embed_batch` (hoje 1 request/chunk) por batch real (a API de embeddings
aceita array de inputs) — corta latência/erro de ingestão sem mudar qualidade. Baixo risco.

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
  `EmptyExtraction`→`failed` silencioso. Avaliar `rtesseract`/`pdf-reader`+OCR. **Decisão de dep.**
- **xlsx.rb:** prefixar nome da aba como heading do bloco (achabilidade + herança de heading).
- **docx.rb:** preservar linhas de tabela (hoje achatadas) como registros tabulares.
- **json.rb:** achatar aninhamento em "caminho: valor" p/ virar registros mono-tópico.

Cada fix é isolado por tipo, testável com fixture, sem tocar chunk/embedding.

---

## Sequência, risco e reprocessamento

**Ordem de construção (PRs pequenos, gate por track igual Onda 5):**
1. **B4 extração** (aditivo, sem reprocessar) → merge/deploy → re-sync das fontes que estavam `failed`.
2. **B2 chunker+metadata** + **B3 rerank** (código; passa a valer p/ ingestões novas).
3. **B1 embedding 3-large@1536** (código + ligar config).
4. **Backfill controlado** (re-chunk + re-embed de TODA a base) — a parte 🔴 de prod-data.

**Backfill (Vermelha — precisa plano de rollback + validação, regra 3):**
- Job idempotente por fonte reusando `Ingestor` (extract→chunk→embed→replace com token-guard, que já
  existe e é seguro contra race). Rodar por **ondas de conta**, não big-bang.
- **Rollback:** o `replace_knowledge` é transacional; se uma conta regredir, re-embedar com o modelo
  antigo restaura. Guardar contagem de chunks/fonte antes e depois; abortar a onda se cair a zero.
- **Validação pós-backfill:** bateria de probes de recall (as já usadas nos incidentes: "frete
  grátis", "PLUS REASON", SKU, "domingo") comparando hit@k antes/depois por conta. Sem regressão =
  segue a próxima onda; regressão = pausa + investiga.
- **Custo:** re-embed de N chunks × preço 3-large. Estimar por conta antes de rodar (contar chunks).

---

## Decisões que preciso do Rodrigo (regra 7) antes de construir

1. **Dims do 3-large:** `1536` reduzido (mantém índice ivfflat — **recomendado**) vs `3072`
   (qualidade máxima porém **perde o índice**, retrieval vira seq scan). Recomendo 1536.
2. **Metadado:** determinístico-only (custo zero) vs **híbrido** com 1 classificação LLM por
   documento (**recomendado**, custo O(docs) limitado, dá o sinal rico que você pediu).
3. **OCR de PDF escaneado (B4):** adiciona dependência (tesseract) ao build/imagem. Fazer agora vs
   deixar como fase 2. Recomendo **fase 2** (isolar; não atrasar B1/B2/B3).
4. **Backfill:** ondas por conta com gate de validação (**recomendado**) vs big-bang. Recomendo ondas.

---

## Checklist de entrega (quando 🟢)
- [ ] B4 PRs por processador + re-sync `failed`
- [ ] B2 chunker adaptativo + metadata (determinístico + LLM/doc)
- [ ] B3 rerank por metadado
- [ ] B1 3-large@1536 + batch real de embedding
- [ ] Job de backfill + plano rollback + probes de validação
- [ ] Codex por track + reviewer + rspec; deploy blue-green 2 stacks; validação pós-deploy
- [ ] Project Autonom.ia Dev atualizado
