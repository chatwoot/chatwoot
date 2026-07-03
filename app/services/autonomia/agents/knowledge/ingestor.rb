module Autonomia
  module Agents
    module Knowledge
      # Orquestrador síncrono da ingestão de UMA fonte (rodado dentro do ProcessJob):
      # extrai texto -> chunka -> embeda em lote -> substitui o conhecimento antigo da fonte por
      # KnowledgeEntry novos (content + embedding + chunk_index, status: ready). Retorna a contagem
      # de chunks gravados; qualquer erro sobe p/ o job marcar a fonte como `failed`.
      class Ingestor
        # Levantada quando, na hora de gravar, outra ingestão (re-sync) já venceu o sync_token: o job
        # antigo NÃO pode tocar o conhecimento da geração nova.
        class Superseded < StandardError; end
        # Extração/embeddings vazios: NÃO é falha comum — o ProcessJob preserva a geração anterior
        # (não apaga, não rebaixa) em vez de marcar failed e perder o KB bom da recuperação.
        class EmptyExtraction < StandardError; end

        def initialize(source:, token:)
          @source = source
          @token = token
          @agent = source.agent
          @account = source.account
        end

        def perform
          text = Processors.for(@source).extract
          chunks = Chunker.new(text).chunks
          # DATA-LOSS GUARD: extração vazia (PDF escaneado, página em branco, só espaços, tudo abaixo
          # do MIN_CHUNK) NÃO pode virar replace_knowledge([],[]) — isso apagaria o conhecimento bom
          # anterior num re-sync ruim/transitório. Levanta ANTES de qualquer delete → o job marca a
          # fonte como `failed` e os KnowledgeEntry antigos ficam INTACTOS.
          raise EmptyExtraction, 'empty_extraction' if chunks.empty?

          vectors = Autonomia::Agents::EmbeddingService.new(account: @account).embed_batch(chunks)
          pairs = chunks.zip(vectors).select { |_, vector| vector.present? }
          raise EmptyExtraction, 'empty_embeddings' if pairs.empty?

          replace_knowledge(pairs.map(&:first), pairs.map(&:last))
        end

        private

        # Apaga os entries antigos da fonte e cria os novos numa transação (re-sync idempotente).
        # Token-guard (padrão Fase C): trava a row da fonte e SÓ substitui se o sync_token desta
        # execução ainda for o ativo E a fonte ainda estiver processing — senão `Superseded` (no-op),
        # evitando que um job velho apague o conhecimento de uma ingestão nova (race de resync).
        # Descarta pares cujo vetor veio vazio. Cria via model (não insert_all) p/ o cast de vetor da
        # gem `neighbor`. Retorna a contagem gravada.
        def replace_knowledge(chunks, vectors)
          count = 0
          KnowledgeEntry.transaction do
            @source.lock!
            raise Superseded unless @source.sync_token == @token && @source.processing?

            KnowledgeEntry.where(source_id: @source.id).delete_all
            chunks.each_with_index do |content, index|
              vector = vectors[index]
              next if vector.blank?

              create_entry(content, vector, index)
              count += 1
            end
          end
          count
        end

        # Grava o chunk na COLUNA de embedding do modelo ativo (B1): 3-small -> :embedding (a gem
        # neighbor casta o vetor); 3-large -> :embedding_large (halfvec 3072, escrito por SQL cru
        # sanitizado, pois neighbor 0.2.3 não conhece halfvec). O vetor foi produzido pelo mesmo modelo
        # ativo (EmbeddingService lê Config.active_embedding_model), então coluna e vetor são coerentes.
        def create_entry(content, vector, index)
          entry = KnowledgeEntry.create!(
            autonomia_agent_id: @agent.id, account_id: @account.id, source_id: @source.id,
            content: content, chunk_index: index, status: :ready,
            metadata: { source_type: @source.source_type },
            **small_embedding_attr(vector)
          )
          write_large_embedding!(entry, vector) if large_embedding?
        end

        def large_embedding?
          Config.embedding_column == Config::EMBEDDING_LARGE_COLUMN
        end

        def small_embedding_attr(vector)
          large_embedding? ? {} : { embedding: vector }
        end

        # halfvec via update_all sanitizado: o literal pgvector é "[v1,v2,...]" e o cast ::halfvec é
        # aplicado no SQL. Escopo por id (uma linha) — não toca a gem neighbor nem a coluna legada.
        def write_large_embedding!(entry, vector)
          # update_all: escrita direta do halfvec (vetor recém-embedado, sem validação a rodar).
          KnowledgeEntry.where(id: entry.id)
                        .update_all(['embedding_large = ?::halfvec', "[#{vector.join(',')}]"]) # rubocop:disable Rails/SkipsModelValidations
        end
      end
    end
  end
end
